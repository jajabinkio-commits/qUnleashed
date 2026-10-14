import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flipperlib/flipperlib.dart' hide DateTime, File;
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/core/device_snapshot.dart';
import 'package:qunleashed/phantom/device/flipper_gateway.dart';

import 'phantom_fakes.dart';

void main() {
  late PhantomFakeClient client;
  late FlipperGateway gateway;

  setUp(() {
    client = PhantomFakeClient();
    gateway = FlipperGateway(client: client);
  });
  tearDown(() async {
    await gateway.close();
    await client.dispose();
  });

  test(
    'status maps actual response fields without firmware matching',
    () async {
      final status = await gateway.readStatus();
      expect(status.deviceId, 'A');
      expect(status.info, {'firmware.version': 'custom-working'});
      expect(status.power, {'battery_charge': '73'});
      expect(status.protocolVersion, '0.30');
      expect(status.externalStorage?.freeBytes, 3072);
      expect(status.externalStorage?.totalBytes, 4096);
      expect(status.issues, isEmpty);
      expect(
        client.priorities,
        everyElement(FlipperRequestPriority.unattended),
      );
      expect(client.timeouts, everyElement(const Duration(seconds: 8)));
      expect(client.requests.last.storageInfoRequest.path, '/ext');
      expect(() => status.info['injected'] = 'value', throwsUnsupportedError);
    },
  );

  test(
    'capabilities are unknown before probing, USB features require bridge',
    () async {
      final report = await gateway.discoverCapabilities();
      expect(report.entries['device.info']?.state, CapabilityState.unverified);
      expect(
        report.entries['bridge.cli']?.state,
        CapabilityState.bridgeRequired,
      );
      expect(
        report.entries['bridge.dfu_repair']?.state,
        CapabilityState.bridgeRequired,
      );
      expect(client.requests, isEmpty);
    },
  );

  test(
    'successful reads establish only the capabilities they exercised',
    () async {
      await gateway.readStatus();
      final report = await gateway.discoverCapabilities();
      expect(report.entries['device.info']?.state, CapabilityState.supported);
      expect(
        report.entries['storage.info.ext']?.state,
        CapabilityState.supported,
      );
      expect(report.entries['gui.input']?.state, CapabilityState.unverified);
      expect(
        report.entries['firmware.update']?.state,
        CapabilityState.unverified,
      );
    },
  );

  test('NOT_IMPLEMENTED differs from temporary unavailability', () async {
    client.respond = (request) async {
      if (request.hasSystemPowerInfoRequest()) {
        throw FlipperRpcNotImplementedException(Main());
      }
      if (request.hasStorageInfoRequest()) {
        throw FlipperRpcStorageNotReadyException(Main());
      }
      return client.answer(request);
    };
    final status = await gateway.readStatus();
    expect(status.power, isEmpty);
    expect(status.externalStorage, isNull);
    expect(status.issues['device.power'], DeviceReadIssue.unsupported);
    final report = await gateway.discoverCapabilities();
    expect(report.entries['device.power']?.state, CapabilityState.unsupported);
    expect(
      report.entries['storage.info.ext']?.state,
      CapabilityState.unverified,
    );
  });

  test(
    'empty ACKs are not invented status or directory observations',
    () async {
      client.respond = (_) async => [];
      final status = await gateway.readStatus();
      expect(status.protocolVersion, isNull);
      expect(
        status.issues.values,
        everyElement(DeviceReadIssue.invalidResponse),
      );
      expect(
        (await gateway.discoverCapabilities()).entries['device.info']?.state,
        CapabilityState.unverified,
      );
      await expectLater(gateway.listFiles('/ext'), throwsFormatException);
    },
  );

  test('invalid storage response is rejected', () async {
    client.respond = (request) async => request.hasStorageInfoRequest()
        ? [
            Main(
              storageInfoResponse: InfoResponse(
                totalSpace: Int64(5),
                freeSpace: Int64(6),
              ),
            ),
          ]
        : client.answer(request);
    final status = await gateway.readStatus();
    expect(status.externalStorage, isNull);
    expect(status.issues['storage.info.ext'], DeviceReadIssue.invalidResponse);
  });

  test(
    'listFiles uses real storageList and decodes response entries',
    () async {
      final entries = await gateway.listFiles('/ext');
      expect(entries.single.name, 'sample.txt');
      expect(entries.single.sizeBytes, 12);
      expect(entries.single.isDirectory, isFalse);
      expect(client.requests.single.storageListRequest.path, '/ext');
    },
  );

  test('an observed empty directory remains empty', () async {
    client.respond = (_) async => [Main(storageListResponse: ListResponse())];
    expect(await gateway.listFiles('/int'), isEmpty);
  });

  test(
    'traversal, aliases and non-storage paths fail before any RPC',
    () async {
      for (final path in [
        '/ext/../int',
        '/ext/a/../../b',
        '/ext2',
        '/intx',
        '/etc',
        'ext/a',
        '/ext//a',
        '/ext/a/',
        '/ext/./a',
        '/ext/%2e%2e',
        '/ext/a\\b',
        '/ext/a\u0000b',
      ]) {
        await expectLater(
          gateway.listFiles(path),
          throwsArgumentError,
          reason: path,
        );
      }
      expect(client.requests, isEmpty);
    },
  );

  test('disconnected and CLI sessions send no RPC', () async {
    client.connected = false;
    await expectLater(gateway.readStatus(), throwsStateError);
    client.connected = true;
    client.currentMode = FlipperMode.cli;
    await expectLater(gateway.readStatus(), throwsStateError);
    expect(client.requests, isEmpty);
  });

  test(
    'STOP discards the in-flight read and sends no following requests',
    () async {
      final pending = Completer<List<Main>>();
      client.respond = (_) => pending.future;
      final result = gateway.readStatus();
      final rejected = expectLater(result, throwsStateError);
      gateway.cancelPending();
      pending.complete(client.answer(client.requests.single));
      await rejected;
      expect(client.requests, hasLength(1));
    },
  );

  test(
    'switching warm devices aborts inspection rather than mixing responses',
    () async {
      final pending = Completer<List<Main>>();
      client.respond = (_) => pending.future;
      final result = gateway.readStatus();
      final rejected = expectLater(result, throwsStateError);
      client.changeDevice('B');
      await pumpEventQueue();
      pending.complete(client.answer(client.requests.single));
      await rejected;
      expect(client.requests, hasLength(1));
    },
  );

  test(
    'same-device reconnect clears previously observed capabilities',
    () async {
      await gateway.readStatus();
      client.changeDevice('A');
      await pumpEventQueue();
      expect(
        (await gateway.discoverCapabilities()).entries['device.info']?.state,
        CapabilityState.unverified,
      );
    },
  );

  test('bounded request timeout is reported and never retried', () async {
    await gateway.close();
    gateway = FlipperGateway(
      client: client,
      requestTimeout: const Duration(milliseconds: 10),
    );
    client.respond = (_) => Completer<List<Main>>().future;
    final status = await gateway.readStatus();
    expect(status.issues.values, everyElement(DeviceReadIssue.timedOut));
    expect(client.requests, hasLength(4));
  });

  test(
    'watch reports current connection immediately and observed status later',
    () async {
      final events = <DeviceSnapshot>[];
      final sub = gateway.watchDevice().listen(events.add);
      await pumpEventQueue();
      expect(events.single.deviceId, 'A');
      expect(events.single.info, isEmpty);
      await gateway.readStatus();
      await pumpEventQueue();
      expect(events.last.info['firmware.version'], 'custom-working');
      await sub.cancel();
    },
  );

  test(
    'closing gateway rejects future work without disconnecting shared client',
    () async {
      await gateway.close();
      await expectLater(gateway.readStatus(), throwsStateError);
      await expectLater(gateway.discoverCapabilities(), throwsStateError);
      expect(client.isConnected, isTrue);
      expect(client.requests, isEmpty);
    },
  );
}
