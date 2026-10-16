import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/ai/openrouter.dart';
import 'package:qunleashed/phantom/features/ai/screen_page.dart';

import 'phantom_ai_fakes.dart';
import 'phantom_screen_test.dart' show sampleScreen;

void main() {
  late ScriptedProvider provider;
  setUp(
    () =>
        provider = ScriptedProvider((_) async => textReply('Inferred: menu.')),
  );
  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PhantomScreenPage(
          screen: sampleScreen(),
          credentials: MemoryCredentials(),
          createProvider: () => provider,
          loadModels: () async => [
            const ModelChoice(
              'vendor/vision',
              'Vision model',
              supportsImages: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.tap(find.text('Load available models'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ModelChoice>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vision model').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preview defaults off, explicit send resets consent; erase removes interpretation',
    (tester) async {
      await open(tester);
      expect(find.byType(Image), findsOneWidget);
      expect(provider.requests, isEmpty);
      await choose(tester);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.tap(find.text('Explain this screenshot'));
      await tester.pumpAndSettle();
      expect(provider.requests, hasLength(1));
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(find.text('Inferred: menu.'), findsOneWidget);
      await tester.tap(find.text('Erase conversation'));
      await tester.pumpAndSettle();
      expect(find.text('Inferred: menu.'), findsNothing);
    },
  );
  testWidgets('background revokes consent and ignores late provider answer', (
    tester,
  ) async {
    final gate = Completer<AiReply>();
    provider = ScriptedProvider((_) => gate.future);
    await open(tester);
    await choose(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.text('Explain this screenshot'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    gate.complete(textReply('late answer'));
    await tester.pumpAndSettle();
    expect(provider.closed, isTrue);
    expect(find.text('late answer'), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
