import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/device/device_gateway.dart';
import 'package:qunleashed/pages/devices/models/connection_state.dart';

import 'firmware_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetFirmwareState);

  test('disconnected snapshot is truthful, not a fabricated device', () {
    final (device, _) = mountedDevice();
    final gateway = QUnleashedPhantomGateway(device);
    final snapshot = gateway.readSnapshot();

    expect(snapshot.connection, DeviceConnectionState.disconnected);
    expect(snapshot.deviceId, isNull);
    expect(snapshot.deviceName, isNull);
    expect(snapshot.firmwareVersion, isNull);
    expect(snapshot.infoLoaded, isFalse);
    expect(snapshot.hasConfirmedDevice, isFalse);
  });

  test('a connection event without an active device is insufficient', () async {
    final (device, client) = mountedDevice();
    final gateway = QUnleashedPhantomGateway(device);

    client.arrive();
    await pumpEventQueue();
    expect(gateway.readSnapshot().hasConfirmedDevice, isFalse);
    expect(
      gateway.discoverCapabilities()[PhantomCapability.deviceInfoRefresh],
      PhantomCapabilityState.disconnected,
    );
  });

  test('feature probes do not claim unverified runtime support', () {
    final (device, _) = mountedDevice();
    final capabilities =
        QUnleashedPhantomGateway(device).discoverCapabilities();

    expect(
      capabilities[PhantomCapability.deviceSnapshot],
      PhantomCapabilityState.ready,
    );
    expect(
      capabilities[PhantomCapability.screenMirror],
      PhantomCapabilityState.unverified,
    );
    expect(
      capabilities[PhantomCapability.usbCli],
      PhantomCapabilityState.bridgeRequired,
    );
    expect(() => capabilities.clear(), throwsUnsupportedError);
  });

  test('request to refresh without a selected device is refused', () async {
    final (device, _) = mountedDevice();
    final gateway = QUnleashedPhantomGateway(device);

    await expectLater(
      gateway.requestDeviceInfoRefresh(),
      throwsA(isA<StateError>()),
    );
  });

  test('watch emits initial snapshot and controller changes', () async {
    final (device, client) = mountedDevice();
    final gateway = QUnleashedPhantomGateway(device);
    final events = <PhantomDeviceSnapshot>[];
    final subscription = gateway.watchSnapshots().listen(events.add);

    await pumpEventQueue();
    expect(events, hasLength(1));

    client.stir();
    await pumpEventQueue();
    expect(events, hasLength(2));
    expect(events.last.hasConfirmedDevice, isFalse);

    await subscription.cancel();
  });
}

