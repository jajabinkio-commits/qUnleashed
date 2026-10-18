enum CapabilityState {
  supported,
  unsupported,
  unverified,
  bridgeRequired,
  requiresExtension,
}

class CapabilityEvidence {
  const CapabilityEvidence(this.state, this.reason);

  final CapabilityState state;
  final String reason;
}

class CapabilityReport {
  CapabilityReport({
    required this.deviceId,
    required Map<String, CapabilityEvidence> entries,
  }) : entries = Map.unmodifiable(entries);

  final String? deviceId;
  final Map<String, CapabilityEvidence> entries;
}

enum DeviceReadIssue { unsupported, unavailable, timedOut, invalidResponse }

class StorageObservation {
  const StorageObservation({required this.totalBytes, required this.freeBytes});

  final int totalBytes;
  final int freeBytes;
}

/// Values are device responses, not estimates or firmware-name heuristics.
/// Missing/failed readings remain absent and carry a separate issue.
class DeviceSnapshot {
  DeviceSnapshot({
    required this.deviceId,
    required this.connected,
    required this.rpcReady,
    required this.observedAt,
    Map<String, String> info = const {},
    Map<String, String> power = const {},
    this.protocolVersion,
    this.externalStorage,
    Map<String, DeviceReadIssue> issues = const {},
  }) : info = Map.unmodifiable(info),
       power = Map.unmodifiable(power),
       issues = Map.unmodifiable(issues);

  final String? deviceId;
  final bool connected;
  final bool rpcReady;
  final DateTime observedAt;
  final Map<String, String> info;
  final Map<String, String> power;
  final String? protocolVersion;
  final StorageObservation? externalStorage;
  final Map<String, DeviceReadIssue> issues;
}

class DeviceFileEntry {
  const DeviceFileEntry({
    required this.name,
    required this.sizeBytes,
    required this.isDirectory,
  });

  final String name;
  final int sizeBytes;
  final bool isDirectory;
}
