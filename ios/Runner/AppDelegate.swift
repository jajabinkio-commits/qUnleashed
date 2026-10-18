import Flutter
import UIKit
import Security
import Speech
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let phantomSpeech = PhantomSpeech()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PhantomSpeech") {
      let channel = FlutterMethodChannel(name: "phantom/speech", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { result(FlutterMethodNotImplemented); return }
        self.phantomSpeech.handle(call, result: result)
      }
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PhantomCredentials") {
      let channel = FlutterMethodChannel(name: "phantom/credentials", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        Self.handleCredentialCall(call, result: result)
      }
    }
  }

  // Fixed account/service: callers cannot read arbitrary Keychain items.
  private static func handleCredentialCall(_ call: FlutterMethodCall, result: FlutterResult) {
    let service = (Bundle.main.bundleIdentifier ?? "phantom") + ".openrouter"
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: "api-key",
      kSecAttrSynchronizable as String: false
    ]
    func finish(_ status: OSStatus) {
      if status == errSecSuccess || status == errSecItemNotFound {
        result(nil)
      } else {
        result(FlutterError(code: "keychain", message: "Credential storage unavailable", details: nil))
      }
    }
    switch call.method {
    case "read":
      var readQuery = query
      readQuery[kSecReturnData as String] = true
      readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
      var value: CFTypeRef?
      let status = SecItemCopyMatching(readQuery as CFDictionary, &value)
      if status == errSecItemNotFound {
        result(nil)
      } else if status == errSecSuccess, let data = value as? Data,
                let key = String(data: data, encoding: .utf8) {
        result(key)
      } else {
        result(FlutterError(code: "keychain", message: "Credential storage unavailable", details: nil))
      }
    case "write":
      guard let arguments = call.arguments as? [String: Any],
            let key = arguments["key"] as? String,
            !key.isEmpty, key.utf8.count <= 512,
            key.rangeOfCharacter(from: .whitespacesAndNewlines.union(.controlCharacters)) == nil,
            let data = key.data(using: .utf8) else {
        result(FlutterError(code: "key", message: "Invalid API key", details: nil))
        return
      }
      let attributes: [String: Any] = [
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      ]
      let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
      if status == errSecItemNotFound {
        finish(SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil))
      } else {
        finish(status)
      }
    case "erase":
      finish(SecItemDelete(query as CFDictionary))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// On-device only: no audio files, network fallback or device executor.
private final class PhantomSpeech {
  private var pending: FlutterResult?
  private var generation = 0
  private var engine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var recognizer: SFSpeechRecognizer?
  private var timer: DispatchWorkItem?
  private var tapped = false
  private var audioActive = false
  private var finishing = false
  private var inputStopped = false
  private var observers: [NSObjectProtocol] = []

  init() {
    for name in [UIApplication.didEnterBackgroundNotification, AVAudioSession.interruptionNotification] {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
        [weak self] _ in self?.complete(code: "speech_cancelled")
      })
    }
  }

  deinit {
    for observer in observers { NotificationCenter.default.removeObserver(observer) }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "listen":
      guard pending == nil else { fail(result, "speech_busy"); return }
      generation += 1
      let token = generation
      pending = result
      SFSpeechRecognizer.requestAuthorization { [weak self] status in
        DispatchQueue.main.async {
          guard let self = self, self.generation == token, self.pending != nil else { return }
          guard status == .authorized else { self.complete(code: "speech_denied"); return }
          guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
                recognizer.supportsOnDeviceRecognition, recognizer.isAvailable else {
            self.complete(code: "speech_unavailable"); return
          }
          self.recognizer = recognizer
          AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
              guard let self = self, self.generation == token, self.pending != nil else { return }
              guard granted else { self.complete(code: "speech_denied"); return }
              guard UIApplication.shared.applicationState == .active else {
                self.complete(code: "speech_cancelled"); return
              }
              self.start(token: token)
            }
          }
        }
      }
    case "finish":
      finish()
      result(nil)
    case "cancel":
      complete(code: "speech_cancelled")
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(token: Int) {
    guard generation == token, pending != nil, let recognizer = recognizer else { return }
    do {
      inputStopped = false
      let audio = AVAudioSession.sharedInstance()
      try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audio.setActive(true, options: .notifyOthersOnDeactivation)
      audioActive = true
      let engine = AVAudioEngine()
      self.engine = engine
      let request = SFSpeechAudioBufferRecognitionRequest()
      request.requiresOnDeviceRecognition = true
      request.shouldReportPartialResults = false
      self.request = request
      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      guard format.channelCount > 0, format.sampleRate > 0 else {
        complete(code: "speech_unavailable"); return
      }
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
      tapped = true
      task = recognizer.recognitionTask(with: request) { [weak self] response, error in
        DispatchQueue.main.async {
          guard let self = self, self.generation == token, self.pending != nil else { return }
          if let response = response, response.isFinal {
            let text = response.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.utf16.count <= 2000 else {
              self.complete(code: "speech_unavailable"); return
            }
            self.complete(text: text)
          } else if error != nil { self.complete(code: "speech_unavailable") }
        }
      }
      engine.prepare()
      try engine.start()
      schedule(seconds: 20) { [weak self] in self?.finish() }
    } catch { complete(code: "speech_unavailable") }
  }

  private func stopInput() {
    guard !inputStopped else { return }
    inputStopped = true
    engine?.stop()
    if tapped { engine?.inputNode.removeTap(onBus: 0); tapped = false }
    request?.endAudio()
    if audioActive {
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      audioActive = false
    }
  }

  private func finish() {
    guard pending != nil, !finishing else { return }
    guard engine != nil else { complete(code: "speech_cancelled"); return }
    finishing = true
    stopInput()
    schedule(seconds: 8) { [weak self] in self?.complete(code: "speech_timeout") }
  }

  private func schedule(seconds: Double, action: @escaping () -> Void) {
    timer?.cancel()
    let token = generation
    let work = DispatchWorkItem { [weak self] in
      guard let self = self, self.generation == token else { return }
      action()
    }
    timer = work
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
  }

  private func complete(text: String? = nil, code: String? = nil) {
    guard let result = pending else { return }
    pending = nil
    generation += 1
    timer?.cancel()
    timer = nil
    stopInput()
    task?.cancel()
    task = nil
    request = nil
    engine = nil
    recognizer = nil
    finishing = false
    if let code = code { fail(result, code) } else { result(text) }
  }

  private func fail(_ result: FlutterResult, _ code: String) {
    result(FlutterError(code: code, message: "On-device dictation unavailable", details: nil))
  }
}
