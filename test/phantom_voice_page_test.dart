import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/ai/openrouter.dart';
import 'package:qunleashed/phantom/ai/voice_input.dart';
import 'package:qunleashed/phantom/device/flipper_gateway.dart';
import 'package:qunleashed/phantom/features/ai/chat_page.dart';

import 'phantom_ai_fakes.dart';
import 'phantom_fakes.dart';

class _Voice implements VoiceInput {
  int starts = 0;
  int finishes = 0;
  int cancels = 0;
  bool acknowledged = true;
  Completer<String>? pending;
  @override
  Future<String> listen() {
    starts++;
    pending = Completer<String>();
    return pending!.future;
  }

  @override
  Future<void> finish() async {
    finishes++;
  }

  @override
  Future<bool> cancel() async {
    cancels++;
    return acknowledged;
  }
}

void main() {
  late _Voice voice;
  late PhantomFakeClient client;
  late ScriptedProvider provider;
  setUp(() {
    voice = _Voice();
    client = PhantomFakeClient();
    provider = ScriptedProvider((_) async => textReply('Read-only answer.'));
  });
  tearDown(() => client.dispose());
  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PhantomChatPage(
          createGateway: () => FlipperGateway(client: client),
          credentials: MemoryCredentials(),
          voiceInput: voice,
          createProvider: () => provider,
          loadModels: () async => [
            const ModelChoice('vendor/model', 'Test model'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.tap(find.text('Load available models'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test model').last);
    await tester.pumpAndSettle();
  }

  testWidgets('speech is editable text; only explicit Send reaches the AI', (
    tester,
  ) async {
    await open(tester);
    expect(voice.starts, 0);
    await choose(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.enterText(find.byType(TextField).last, 'Draft');
    await tester.tap(find.text('Dictate message'));
    await tester.pump();
    expect(voice.starts, 1);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Finish recording'));
    await tester.pump();
    expect(voice.finishes, 1);
    voice.pending!.complete('spoken instructions');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Draft spoken instructions',
    );
    expect(provider.requests, isEmpty);
    expect(client.requests, isEmpty);
    await tester.enterText(find.byType(TextField).last, 'Reviewed message');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(provider.requests.single.last['content'], 'Reviewed message');
    expect(provider.toolsAllowed, [false]);
    expect(client.requests, isEmpty);
  });
  testWidgets(
    'permission dialog inactive is allowed; background discards late speech',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Dictate message'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(voice.cancels, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(voice.cancels, greaterThan(0));
      voice.pending!.complete('late transcript');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );
      expect(provider.requests, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );
  testWidgets('STOP discards late speech; erase clears the draft', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).last, 'Private draft');
    await tester.tap(find.text('Dictate message'));
    await tester.pump();
    await tester.tap(find.text('Stop'));
    await tester.pump();
    voice.pending!.complete('must not appear');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Private draft',
    );
    await tester.tap(find.text('Erase conversation'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );
    expect(provider.requests, isEmpty);
  });
  testWidgets('permission failure preserves typing and the existing draft', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).last, 'Keep this');
    await tester.tap(find.text('Dictate message'));
    await tester.pump();
    voice.pending!.completeError(const VoiceFailure());
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).readOnly,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Keep this',
    );
    expect(
      find.textContaining('On-device dictation is unavailable'),
      findsOneWidget,
    );
    expect(provider.requests, isEmpty);
  });
  testWidgets('late old session cannot replace a newer transcript', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Dictate message'));
    await tester.pump();
    final old = voice.pending!;
    await tester.tap(find.text('Stop'));
    await tester.pump();
    await tester.tap(find.text('Dictate message'));
    await tester.pump();
    final current = voice.pending!;
    old.complete('stale');
    await tester.pump();
    current.complete('current transcript');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'current transcript',
    );
    expect(provider.requests, isEmpty);
  });

  testWidgets('oversized combined transcript preserves the existing draft', (
    tester,
  ) async {
    await open(tester);
    final draft = 'x' * 1998;
    await tester.enterText(find.byType(TextField).last, draft);
    await tester.tap(find.text('Dictate message'));
    await tester.pump();
    voice.pending!.complete('more words');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      draft,
    );
    expect(provider.requests, isEmpty);
  });
  testWidgets(
    'failed cancellation acknowledgement is shown without accepting late speech',
    (tester) async {
      await open(tester);
      voice.acknowledged = false;
      await tester.tap(find.text('Dictate message'));
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not confirm dictation stopped'),
        findsOneWidget,
      );
      voice.pending!.complete('late');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );
      expect(provider.requests, isEmpty);
    },
  );
}
