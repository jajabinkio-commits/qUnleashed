import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flipperlib/flipperlib.dart' hide DateTime, File;
import 'package:flipperlib/flipperlib.dart' as fl show File;

/// SIMULATED: real API extensions + real callRpc decoding, fake wire frames.
/// No BLE plugin, radio, firmware or physical acceptance gate is exercised.
class PhantomFakeClient extends FlipperClient {
  FlipperDevice? device = simulatedDevice('A');
  bool connected = true;
  FlipperMode currentMode = FlipperMode.rpc;
  Future<List<Main>> Function(Main request)? respond;
  final requests = <Main>[];
  final priorities = <FlipperRequestPriority>[];
  final timeouts = <Duration>[];

  @override
  FlipperDevice? get connectedDevice => connected ? device : null;
  @override
  bool get isConnected => connected;
  @override
  FlipperMode get mode => currentMode;
  @override
  FlipperSessionBinding bindCurrentSession() => device == null
      ? const FlipperSessionBinding.unbound()
      : FlipperSessionBinding.to(device!);

  void changeDevice(String id) {
    device = simulatedDevice(id);
    connectionCtrl.add(
      FlipperConnectionState(mode: mode, device: device, connected: connected),
    );
  }

  @override
  Future<List<Main>> callRpcFrames(
    Main request, {
    Duration timeout = const Duration(seconds: 8),
    FlipperRequestPriority priority = FlipperRequestPriority.unattended,
    void Function(Main frame)? onFrame,
    void Function()? onSent,
    bool retainFrames = true,
    bool interleavable = false,
    bool pipelined = true,
  }) async {
    requests.add(request);
    priorities.add(priority);
    timeouts.add(timeout);
    if (respond != null) return respond!(request);
    return answer(request);
  }

  List<Main> answer(Main request) {
    if (request.hasSystemDeviceInfoRequest()) {
      return [
        Main(
          systemDeviceInfoResponse: DeviceInfoResponse(
            key: 'firmware.version',
            value: 'custom-working',
          ),
        ),
      ];
    }
    if (request.hasSystemPowerInfoRequest()) {
      return [
        Main(
          systemPowerInfoResponse: PowerInfoResponse(
            key: 'battery_charge',
            value: '73',
          ),
        ),
      ];
    }
    if (request.hasSystemProtobufVersionRequest()) {
      return [
        Main(
          systemProtobufVersionResponse: ProtobufVersionResponse(
            major: 0,
            minor: 30,
          ),
        ),
      ];
    }
    if (request.hasStorageInfoRequest()) {
      return [
        Main(
          storageInfoResponse: InfoResponse(
            totalSpace: Int64(4096),
            freeSpace: Int64(3072),
          ),
        ),
      ];
    }
    if (request.hasStorageListRequest()) {
      return [
        Main(
          storageListResponse: ListResponse(
            file: [fl.File(name: 'sample.txt', size: 12)],
          ),
        ),
      ];
    }
    throw StateError('Unexpected RPC ${request.whichContent()}');
  }
}

class _Source implements DiscoveredDevice {
  const _Source(this.id);
  @override
  final String id;
  @override
  String get name => id;
  @override
  DeviceTransport get transport => DeviceTransport.ble;
}

FlipperDevice simulatedDevice(String id) =>
    FlipperDevice(id: id, name: id, link: FlipperLink.ble, source: _Source(id));
