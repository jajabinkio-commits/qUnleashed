import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/ai/openrouter.dart';
import 'package:qunleashed/phantom/device/flipper_gateway.dart';
import 'package:qunleashed/phantom/features/ai/chat_page.dart';

import 'phantom_ai_fakes.dart';
import 'phantom_fakes.dart';

void main() {
  late PhantomFakeClient client;
  late MemoryCredentials credentials;
  late ScriptedProvider provider;
  setUp(() {
    client = PhantomFakeClient();
    credentials = MemoryCredentials();
    provider = ScriptedProvider((_) async => textReply('Assistant answer.'));
  });
  tearDown(() => client.dispose());

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PhantomChatPage(
          createGateway: () => FlipperGateway(client: client),
          credentials: credentials,
          createProvider: () => provider,
          loadModels: () async => [
            const ModelChoice('example/model', 'Test model'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseModel(WidgetTester tester) async {
    await tester.tap(find.text('Load available models'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test model').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening AI sends no provider request or device RPC; sharing defaults off',
    (tester) async {
      await open(tester);
      expect(client.requests, isEmpty);
      expect(provider.requests, isEmpty);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(find.text('fake-test-key'), findsNothing);
    },
  );

  testWidgets('save key clears the obscured input', (tester) async {
    await open(tester);
    final field = find.byType(TextField).first;
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.enterText(field, 'replacement-test-key');
    await tester.tap(find.text('Save key'));
    await tester.pumpAndSettle();
    expect(credentials.key, 'replacement-test-key');
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
  });

  testWidgets(
    'selected model and send show response without granting device access',
    (tester) async {
      await open(tester);
      await chooseModel(tester);
      await tester.enterText(find.byType(TextField).last, 'Explain Bluetooth');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Assistant answer.'), findsOneWidget);
      expect(provider.toolsAllowed, [false]);
      expect(client.requests, isEmpty);
      await tester.tap(find.text('Erase conversation'));
      await tester.pumpAndSettle();
      expect(find.text('Assistant answer.'), findsNothing);
    },
  );

  testWidgets('backgrounding cancels AI and discards a late tool call', (
    tester,
  ) async {
    final pending = Completer<AiReply>();
    provider = ScriptedProvider((_) => pending.future);
    await open(tester);
    await chooseModel(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.enterText(find.byType(TextField).last, 'Read status');
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
      reason: 'status consent is consumed by one send',
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    pending.complete(toolReply('device_status'));
    await tester.pumpAndSettle();
    expect(provider.closed, isTrue);
    expect(client.requests, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
