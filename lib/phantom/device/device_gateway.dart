import 'dart:async';

import '../../pages/devices/controllers/device.dart';
import '../../pages/devices/models/connection_state.dart';

/// PHANTOM's read-only seam over the existing, tested qUnleashed controller.
///
/// The controller still owns the real FlipperClient and its BLE/RPC session.
/// This gateway neither creates a second client nor changes the transport.
abstract interface class PhantomDeviceGateway {
  PhantomDeviceSnapshot readSnapshot();
  Stream<PhantomDeviceSnapshot> watchSnapshots();
  Map<PhantomCapability, PhantomCapabilityState> discoverCapabilities();
  Future<void> requestDeviceInfoRefresh();
}

enum PhantomCapability {
  deviceSnapshot,
  deviceInfoRefresh,
  screenMirror,
  remoteButtons,
  fileManager,
  archive,
  appManager,
  firmwareUpdate,
  savedSignalActions,
  aiExecution,
  usbCli,
  usbDfuRepair,
}

/// 'Unverified' means no capability probe has been made, NOT that it works.
enum PhantomCapabilityState {
  ready,
  disconnected,
  unverified,
  bridgeRequired,
}

final class PhantomDeviceSnapshot {
  PhantomDeviceSnapshot({
    required this.connection,
    required this.deviceId,
    required this.deviceName,
    required this.firmwareVersion,
    required this.infoLoaded,
    required Map<String, String> properties,
  }) : properties = Map<String, String>.unmodifiable(properties);

  final DeviceConnectionState connection;
  final String? deviceId;
  final String? deviceName;
  final String? firmwareVersion;
  final bool infoLoaded;
  final Map<String, String> properties;

  /// Do not report a physical device connected based on an event alone:
  /// a real selected FlipperDevice must also be present.
  bool get hasConfirmedDevice =>
      connection == DeviceConnectionState.connected &&
      deviceId != null &&
      deviceId!.isNotEmpty;
}

final class QUnleashedPhantomGateway implements PhantomDeviceGateway {
  QUnleashedPhantomGateway(this.controller);

  /// Injected by the existing app's composition root; do not dispose here.
  final DeviceController controller;

  @override
  PhantomDeviceSnapshot readSnapshot() {
    final info = Map<String, String>.of(controller.info);
    final name = info['hardware_name']?.trim();
    final firmware = controller.firmwareVersion;
    return PhantomDeviceSnapshot(
      connection: controller.connectionState,
      deviceId: controller.device?.id,
      deviceName: name == null || name.isEmpty ? null : name,
      firmwareVersion: firmware == '-' ? null : firmware,
      infoLoaded: controller.isConnected && controller.deviceInfoConnected,
      properties: info,
    );
  }

  /// Each subscription owns exactly one listener and removes it on cancel.
  /// There is no competing BLE stream, timer or connection singleton.
  @override
  Stream<PhantomDeviceSnapshot> watchSnapshots() => Stream.multi((events) {
    events.add(readSnapshot());
    void onChanged() => events.add(readSnapshot());
    controller.addListener(onChanged);
    events.onCancel = () => controller.removeListener(onChanged);
  });

  @override
  Map<PhantomCapability, PhantomCapabilityState> discoverCapabilities() {
    final connected = readSnapshot().hasConfirmedDevice;
    return Map<PhantomCapability, PhantomCapabilityState>.unmodifiable({
      PhantomCapability.deviceSnapshot: PhantomCapabilityState.ready,
      PhantomCapability.deviceInfoRefresh: connected
          ? PhantomCapabilityState.ready
          : PhantomCapabilityState.disconnected,
      // Do not infer runtime protocol support merely because a menu exists.
      PhantomCapability.screenMirror: PhantomCapabilityState.unverified,
      PhantomCapability.remoteButtons: PhantomCapabilityState.unverified,
      PhantomCapability.fileManager: PhantomCapabilityState.unverified,
      PhantomCapability.archive: PhantomCapabilityState.unverified,
      PhantomCapability.appManager: PhantomCapabilityState.unverified,
      PhantomCapability.firmwareUpdate: PhantomCapabilityState.unverified,
      PhantomCapability.savedSignalActions: PhantomCapabilityState.unverified,
      PhantomCapability.aiExecution: PhantomCapabilityState.unverified,
      // These are iPhone-mode requirements, not claims about desktop builds.
      PhantomCapability.usbCli: PhantomCapabilityState.bridgeRequired,
      PhantomCapability.usbDfuRepair: PhantomCapabilityState.bridgeRequired,
    });
  }

  /// Only starts the existing controller's info request. It does not assert
  /// that a fresh hardware reply was received; observe watchSnapshots().
  @override
  Future<void> requestDeviceInfoRefresh() async {
    if (!readSnapshot().hasConfirmedDevice) {
      throw StateError('No selected, connected Flipper to refresh');
    }
    controller.synchronize();
  }
}

