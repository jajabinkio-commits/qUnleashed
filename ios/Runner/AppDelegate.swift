import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
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
