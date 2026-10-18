import '../device/device_gateway.dart';

/// Only explicitly enumerated operations are executable. This is a host-side
/// policy boundary, not a prompt or a model-generated command interpreter.
enum PhantomActionDisposition { snapshotReturned, refreshRequested, rejected }

final class PhantomActionOutcome {
  const PhantomActionOutcome({
    required this.disposition,
    required this.message,
    this.snapshot,
  });

  final PhantomActionDisposition disposition;
  final String message;
  final PhantomDeviceSnapshot? snapshot;
  bool get accepted => disposition != PhantomActionDisposition.rejected;
}

final class PhantomActionGate {
  const PhantomActionGate(this.gateway);

  final PhantomDeviceGateway gateway;

  /// The caller supplies a parsed operation name and exact argument map.
  ///
  /// No arbitrary CLI, file mutation, radio transmission, or dynamic method
  /// lookup exists in this initial action allowlist.
  Future<PhantomActionOutcome> execute({
    required String operation,
    Map<String, Object?> arguments = const {},
  }) async {
    if (arguments.isNotEmpty) {
      return const PhantomActionOutcome(
        disposition: PhantomActionDisposition.rejected,
        message: 'Unexpected arguments; no action executed',
      );
    }

    switch (operation) {
      case 'device.status':
        return PhantomActionOutcome(
          disposition: PhantomActionDisposition.snapshotReturned,
          message: 'Returned current controller snapshot; not a new RPC read',
          snapshot: gateway.readSnapshot(),
        );
      case 'device.refresh':
        if (gateway.discoverCapabilities()[PhantomCapability.deviceInfoRefresh] !=
            PhantomCapabilityState.ready) {
          return const PhantomActionOutcome(
            disposition: PhantomActionDisposition.rejected,
            message: 'No verified active device; refresh not started',
          );
        }
        try {
          await gateway.requestDeviceInfoRefresh();
          return const PhantomActionOutcome(
            disposition: PhantomActionDisposition.refreshRequested,
            message: 'Refresh requested; await a device information update',
          );
        } on StateError {
          // A device may disconnect between capability checking and use.
          return const PhantomActionOutcome(
            disposition: PhantomActionDisposition.rejected,
            message: 'Device became unavailable; no refresh confirmed',
          );
        }
      default:
        return const PhantomActionOutcome(
          disposition: PhantomActionDisposition.rejected,
          message: 'Operation is not on the approved allowlist',
        );
    }
  }
}

