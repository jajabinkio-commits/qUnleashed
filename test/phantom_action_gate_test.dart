import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/ai/action_gate.dart';
import 'package:qunleashed/phantom/device/device_gateway.dart';

import 'firmware_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetFirmwareState);

  test('status returns observation, not a claim of RPC execution', () async {
    final (device, _) = mountedDevice();
    final outcome = await PhantomActionGate(
      QUnleashedPhantomGateway(device),
    ).execute(operation: 'device.status');

    expect(outcome.disposition, PhantomActionDisposition.snapshotReturned);
    expect(outcome.snapshot, isNotNull);
    expect(outcome.snapshot!.hasConfirmedDevice, isFalse);
    expect(outcome.message, contains('not a new RPC'));
  });

  test('unexpected model-generated operation is rejected', () async {
    final (device, _) = mountedDevice();
    final outcome = await PhantomActionGate(
      QUnleashedPhantomGateway(device),
    ).execute(operation: 'device.run_shell');

    expect(outcome.disposition, PhantomActionDisposition.rejected);
    expect(outcome.snapshot, isNull);
  });

  test('known operation with unexpected arguments is rejected', () async {
    final (device, _) = mountedDevice();
    final outcome = await PhantomActionGate(
      QUnleashedPhantomGateway(device),
    ).execute(operation: 'device.status', arguments: {'command': 'anything'});

    expect(outcome.disposition, PhantomActionDisposition.rejected);
  });

  test('disconnected refresh does not start device work', () async {
    final (device, _) = mountedDevice();
    final outcome = await PhantomActionGate(
      QUnleashedPhantomGateway(device),
    ).execute(operation: 'device.refresh');

    expect(outcome.disposition, PhantomActionDisposition.rejected);
  });
}

