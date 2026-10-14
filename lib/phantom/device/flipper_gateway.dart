import 'dart:async';

import 'package:flipperlib/flipperlib.dart' hide DateTime, File;

import '../core/device_snapshot.dart';
import 'device_gateway.dart';

/// Thin adapter over the pinned client, including its actual API extensions.
/// It neither opens a second connection nor implements transport/protobuf.
class FlipperGateway implements DeviceGateway {
  FlipperGateway({
    required this._client,
    this.requestTimeout = const Duration(seconds: 8),
  }) {
    if (requestTimeout <= Duration.zero ||
        requestTimeout > const Duration(seconds: 30)) {
      throw ArgumentError.value(requestTimeout, 'requestTimeout');
    }
    _connectionSub = _client.connectionStream.listen(
      (_) {
        cancelPending();
        _snapshots.add(_connectionSnapshot());
      },
      onError: (Object error, StackTrace stack) {
        cancelPending();
        _snapshots.addError(error, stack);
      },
    );
  }

  final FlipperClient _client;
  final Duration requestTimeout;
  int _epoch = 0;
  bool _closed = false;
  DeviceSnapshot? _latest;
  final _snapshots = StreamController<DeviceSnapshot>.broadcast();
  late final StreamSubscription<FlipperConnectionState> _connectionSub;

  @override
  Stream<DeviceSnapshot> watchDevice() => Stream.multi((sink) {
    if (_closed) {
      sink.close();
      return;
    }
    // Subscribe before taking the snapshot: connectionStream is broadcast,
    // not replayed. Connection events never manufacture a fresh RPC reading.
    final sub = _snapshots.stream.listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.add(_connectionSnapshot());
    sink.onCancel = sub.cancel;
  });

  DeviceSnapshot _connectionSnapshot() => DeviceSnapshot(
    deviceId: _client.connectedDevice?.id,
    connected: _client.isConnected,
    rpcReady: _client.isRpcReady,
    observedAt: DateTime.now().toUtc(),
  );

  _ReadScope _scope() {
    if (_closed) throw StateError('Device gateway is closed');
    if (!_client.isRpcReady) throw StateError('Connect a Flipper in RPC mode');
    final binding = _client.bindCurrentSession();
    if (!binding.isAlive || binding.device == null) {
      throw StateError('No live device session');
    }
    return _ReadScope(binding, _client.deviceToken, _epoch);
  }

  void _check(_ReadScope scope) {
    if (_closed || scope.epoch != _epoch) {
      throw StateError('Device inspection cancelled');
    }
    if (!scope.binding.isAlive || scope.token.isStale || !_client.isRpcReady) {
      throw StateError('Device session changed; inspect again');
    }
  }

  Future<T> _read<T>(_ReadScope scope, Future<T> Function() request) async {
    _check(scope);
    // Foreground RPCs bypass task bindings in this client. Use unattended for
    // every bound read so a warm-device switch cannot redirect the next call.
    final value = await scope.binding.run(request).timeout(requestTimeout);
    _check(scope);
    return value;
  }

  @override
  Future<DeviceSnapshot> readStatus() async {
    final scope = _scope();
    final issues = <String, DeviceReadIssue>{};
    final info = <String, String>{};
    final power = <String, String>{};
    String? protocol;
    StorageObservation? storage;

    Future<void> collect(
      String capability,
      Future<void> Function() body,
    ) async {
      try {
        await body();
      } catch (error) {
        _check(
          scope,
        ); // Never turn a cancelled/stale read into partial success.
        issues[capability] = _classify(error);
      }
    }

    await collect('device.info', () async {
      final batch = await _read(
        scope,
        () => _client.deviceInfo(
          timeout: requestTimeout,
          priority: FlipperRequestPriority.unattended,
        ),
      );
      if (batch.items.isEmpty) {
        throw const FormatException('Missing device info');
      }
      for (final item in batch.items) {
        if (item.key.isEmpty) throw const FormatException('Empty info key');
        info[item.key] = item.value;
      }
    });
    await collect('device.power', () async {
      final batch = await _read(
        scope,
        () => _client.powerInfo(
          timeout: requestTimeout,
          priority: FlipperRequestPriority.unattended,
        ),
      );
      if (batch.items.isEmpty) {
        throw const FormatException('Missing power info');
      }
      for (final item in batch.items) {
        if (item.key.isEmpty) throw const FormatException('Empty power key');
        power[item.key] = item.value;
      }
    });
    await collect('device.protocol', () async {
      final batch = await _read(
        scope,
        () => _client.protobufVersion(
          timeout: requestTimeout,
          priority: FlipperRequestPriority.unattended,
        ),
      );
      if (batch.items.length != 1) {
        throw const FormatException('Missing protocol version');
      }
      protocol = '${batch.single.major}.${batch.single.minor}';
    });
    await collect('storage.info.ext', () async {
      final batch = await _read(
        scope,
        () => _client.storageInfo(
          InfoRequest(path: '/ext'),
          timeout: requestTimeout,
          priority: FlipperRequestPriority.unattended,
        ),
      );
      if (batch.items.length != 1) {
        throw const FormatException('Missing storage info');
      }
      final item = batch.single;
      if (item.freeSpace > item.totalSpace ||
          item.freeSpace.isNegative ||
          item.totalSpace.isNegative) {
        throw const FormatException('Invalid storage sizes');
      }
      storage = StorageObservation(
        totalBytes: item.totalSpace.toInt(),
        freeBytes: item.freeSpace.toInt(),
      );
    });
    _check(scope);
    final snapshot = DeviceSnapshot(
      deviceId: scope.binding.device!.id,
      connected: true,
      rpcReady: true,
      observedAt: DateTime.now().toUtc(),
      info: info,
      power: power,
      protocolVersion: protocol,
      externalStorage: storage,
      issues: issues,
    );
    _latest = snapshot;
    _snapshots.add(snapshot);
    return snapshot;
  }

  @override
  Future<CapabilityReport> discoverCapabilities() async {
    if (_closed) throw StateError('Device gateway is closed');
    final deviceId = _client.connectedDevice?.id;
    final snapshot = _latest;
    final current =
        snapshot != null && snapshot.deviceId == deviceId && _client.isRpcReady;
    final entries = <String, CapabilityEvidence>{};
    for (final key in [
      'device.info',
      'device.power',
      'device.protocol',
      'storage.info.ext',
    ]) {
      final issue = current ? snapshot.issues[key] : null;
      entries[key] = CapabilityEvidence(
        !current
            ? CapabilityState.unverified
            : issue == null
            ? CapabilityState.supported
            : issue == DeviceReadIssue.unsupported
            ? CapabilityState.unsupported
            : CapabilityState.unverified,
        !current
            ? 'No observation in the current RPC session'
            : issue == null
            ? 'RPC response observed in this session'
            : 'Read result: ${issue.name}',
      );
    }
    for (final key in [
      'gui.screen_stream',
      'gui.input',
      'storage.list',
      'storage.write',
      'apps.manage',
      'firmware.update',
    ]) {
      entries[key] = const CapabilityEvidence(
        CapabilityState.unverified,
        'Upstream implementation retained; device verification required',
      );
    }
    for (final key in ['bridge.cli', 'bridge.dfu_repair']) {
      entries[key] = const CapabilityEvidence(
        CapabilityState.bridgeRequired,
        'Requires an authenticated USB host bridge on iPhone',
      );
    }
    entries['extensions.telemetry'] = const CapabilityEvidence(
      CapabilityState.requiresExtension,
      'Requires a measured module-specific adapter',
    );
    return CapabilityReport(deviceId: deviceId, entries: entries);
  }

  @override
  Future<List<DeviceFileEntry>> listFiles(String path) async {
    validateReadPath(path);
    final scope = _scope();
    final batch = await _read(
      scope,
      () => _client.storageList(
        ListRequest(path: path),
        timeout: requestTimeout,
        priority: FlipperRequestPriority.unattended,
      ),
    );
    // An empty listing is valid only when a ListResponse was actually received.
    if (batch.items.isEmpty) {
      throw const FormatException('Missing directory response');
    }
    return List.unmodifiable([
      for (final response in batch.items)
        for (final file in response.file)
          DeviceFileEntry(
            name: file.name,
            sizeBytes: file.size,
            isDirectory: file.type == File_FileType.DIR,
          ),
    ]);
  }

  static void validateReadPath(String path) {
    final parts = path.split('/');
    if (path.length > 255 ||
        parts.length < 2 ||
        parts.first.isNotEmpty ||
        !['ext', 'int'].contains(parts[1]) ||
        path.contains(RegExp(r'[\x00-\x1f\x7f\\%]')) ||
        parts
            .skip(2)
            .any((part) => part.isEmpty || part == '.' || part == '..')) {
      throw ArgumentError.value(
        path,
        'path',
        'Use a canonical /ext or /int path',
      );
    }
  }

  static DeviceReadIssue _classify(Object error) => switch (error) {
    FlipperRpcNotImplementedException() ||
    FlipperRpcStorageNotImplementedException() => DeviceReadIssue.unsupported,
    TimeoutException() => DeviceReadIssue.timedOut,
    FormatException() => DeviceReadIssue.invalidResponse,
    _ => DeviceReadIssue.unavailable,
  };

  @override
  void cancelPending() {
    _epoch++;
    _latest = null;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    cancelPending();
    await _connectionSub.cancel();
    await _snapshots.close();
    // The application owns the injected client. Never disconnect/dispose it.
  }
}

class _ReadScope {
  const _ReadScope(this.binding, this.token, this.epoch);
  final FlipperSessionBinding binding;
  final DeviceToken token;
  final int epoch;
}
