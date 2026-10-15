import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/ai/observation.dart';
import 'package:qunleashed/phantom/core/device_snapshot.dart';
import 'package:qunleashed/phantom/features/ai/observation_card.dart';

void main() {
  DeviceSnapshot status({
    Map<String, String> power = const {},
    Map<String, DeviceReadIssue> issues = const {},
  }) => DeviceSnapshot(
    deviceId: 'local-only-identity',
    connected: true,
    rpcReady: true,
    observedAt: DateTime.utc(2026, 10, 15),
    power: power,
    issues: issues,
  );

  test('invalid battery data remains unknown rather than becoming a false measurement', () {
    for (final value in [
      '',
      'NaN',
      'Infinity',
      '-1',
      '101',
      'battery is great',
    ]) {
      expect(
        AgentObservation.status(status(power: {'battery_charge': value}))
            .batteryPercent,
        isNull,
        reason: value,
      );
    }
    expect(
      AgentObservation.status(status(power: {'battery_charge': '73.5'}))
          .batteryPercent,
      73.5,
    );
  });

  testWidgets(
    'missing readings stay unknown and private identity is not rendered',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationCard(
              observation: AgentObservation.status(
                status(issues: {'device.power': DeviceReadIssue.timedOut}),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Battery: Unknown'), findsOneWidget);
      expect(
        find.text('Free / total storage in bytes: Unknown'),
        findsOneWidget,
      );
      expect(find.text('local-only-identity'), findsNothing);
      expect(
        find.text(
          'Some readings could not be retrieved. Missing values remain unknown.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'unverified capabilities are not presented as successful device readings',
    (tester) async {
      final report = CapabilityReport(
        deviceId: 'local-only-identity',
        entries: {
          'gui.input': const CapabilityEvidence(
            CapabilityState.unverified,
            'Not probed',
          ),
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservationCard(
              observation: AgentObservation.capabilities(report),
            ),
          ),
        ),
      );
      expect(find.text('Device capability evidence'), findsOneWidget);
      expect(
        find.text('0 of 1 capabilities have supporting observations.'),
        findsOneWidget,
      );
      expect(find.text('Reported by your Flipper'), findsNothing);
      expect(find.text('local-only-identity'), findsNothing);
    },
  );
}
