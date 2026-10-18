import '../core/device_snapshot.dart';

/// Local evidence produced by the controller, never parsed from model text.
/// Kept in memory with its chat turn and never added to provider history.
class AgentObservation {
  const AgentObservation.status(DeviceSnapshot status)
    : snapshot = status,
      capabilities = null;

  const AgentObservation.capabilities(CapabilityReport report)
    : snapshot = null,
      capabilities = report;

  final DeviceSnapshot? snapshot;
  final CapabilityReport? capabilities;

  double? get batteryPercent {
    final value = double.tryParse(snapshot?.power['battery_charge'] ?? '');
    return value != null && value.isFinite && value >= 0 && value <= 100
        ? value
        : null;
  }
}
