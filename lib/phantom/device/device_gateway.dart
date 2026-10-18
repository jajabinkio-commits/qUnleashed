import '../core/device_snapshot.dart';

/// M1 read-only surface. AI proposals cannot execute mutations through this
/// interface; the later command controller must authorize those separately.
abstract interface class DeviceGateway {
  Stream<DeviceSnapshot> watchDevice();
  Future<DeviceSnapshot> readStatus();
  Future<CapabilityReport> discoverCapabilities();
  Future<List<DeviceFileEntry>> listFiles(String path);
  void cancelPending();
  Future<void> close();
}
