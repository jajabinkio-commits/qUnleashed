import 'package:flutter/material.dart';

import '../../../services/localization/l10n.dart';
import '../../ai/observation.dart';
import '../../core/device_snapshot.dart';

/// Shows controller evidence separately from the model's explanation.
class ObservationCard extends StatelessWidget {
  const ObservationCard({super.key, required this.observation});

  final AgentObservation observation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = observation.snapshot;
    final capabilities = observation.capabilities;
    final battery = observation.batteryPercent;
    final storage = snapshot?.externalStorage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot == null
                  ? l10n.phantomCapabilityEvidence
                  : l10n.phantomObservedTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (snapshot != null) ...[
              Text(
                l10n.phantomObservedAt(
                  snapshot.observedAt.toLocal().toIso8601String(),
                ),
              ),
              Text(
                l10n.phantomObservedBattery(
                  battery == null
                      ? l10n.phantomObservedUnknown
                      : '${battery == battery.roundToDouble() ? battery.toInt() : battery}%',
                ),
              ),
              Text(
                l10n.phantomObservedStorage(
                  storage == null
                      ? l10n.phantomObservedUnknown
                      : '${storage.freeBytes} / ${storage.totalBytes}',
                ),
              ),
              Text(
                l10n.phantomObservedProtocol(
                  snapshot.protocolVersion ?? l10n.phantomObservedUnknown,
                ),
              ),
              if (snapshot.issues.isNotEmpty) Text(l10n.phantomObservedPartial),
            ],
            if (capabilities != null) ...[
              Text(
                l10n.phantomObservedCapabilities(
                  capabilities.entries.values
                      .where((item) => item.state == CapabilityState.supported)
                      .length,
                  capabilities.entries.length,
                ),
              ),
              Text(l10n.phantomObservedCapabilitiesNote),
            ],
          ],
        ),
      ),
    );
  }
}
