import 'dart:async';

import 'package:flipperlib/flipperlib.dart' hide DateTime;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/device/flipper_gateway.dart';
import 'package:qunleashed/phantom/features/devices/inspection_page.dart';

import 'phantom_fakes.dart';

/// SIMULATED Flutter widget tests, not physical iOS acceptance.
void main() {
  late PhantomFakeClient client;
  setUp(() => client = PhantomFakeClient());
  tearDown(() => client.dispose());

  Widget page() => MaterialApp(
    home: PhantomInspectionPage(
      createGateway: () => FlipperGateway(client: client),
    ),
  );

  testWidgets(
    'manual inspection displays observed status with no provider configured',
    (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();
      expect(
        client.requests,
        isEmpty,
        reason: 'opening/building the page performs no RPC',
      );
      await tester.tap(find.text('Read status'));
      await tester.pumpAndSettle();
      expect(find.text('custom-working'), findsOneWidget);
      expect(find.text('0.30'), findsOneWidget);
      expect(client.requests, hasLength(4));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(
        client.isConnected,
        isTrue,
        reason: 'closing inspection preserves manual BLE client',
      );
    },
  );

  testWidgets('stop discards late results and prevents subsequent RPC', (
    tester,
  ) async {
    final pending = Completer<List<Main>>();
    client.respond = (_) => pending.future;
    await tester.pumpWidget(page());
    await tester.pump();
    await tester.tap(find.text('Read status'));
    await tester.pump();
    await tester.tap(find.text('Stop inspection'));
    pending.complete(client.answer(client.requests.single));
    await tester.pumpAndSettle();
    expect(client.requests, hasLength(1));
    expect(find.text('custom-working'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'backgrounding cancels inspection instead of reporting unattended success',
    (tester) async {
      final pending = Completer<List<Main>>();
      client.respond = (_) => pending.future;
      await tester.pumpWidget(page());
      await tester.pump();
      await tester.tap(find.text('Read status'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      pending.complete(client.answer(client.requests.single));
      await tester.pumpAndSettle();
      expect(client.requests, hasLength(1));
      expect(find.text('custom-working'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets('disconnected device cannot start an inspection', (tester) async {
    client.connected = false;
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Read status'),
    );
    expect(button.onPressed, isNull);
    expect(client.requests, isEmpty);
  });
}
