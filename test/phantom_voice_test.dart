import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/phantom/ai/voice_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = NativeVoiceInput.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('construction makes no audio call; explicit methods only', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'listen' ? '  Review this text  ' : null;
    });
    final voice = NativeVoiceInput();
    expect(calls, isEmpty);
    expect(await voice.listen(), 'Review this text');
    await voice.finish();
    await voice.cancel();
    expect(calls, ['listen', 'finish', 'cancel']);
  });

  test('permission error details are never propagated', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
        code: 'denied',
        message: 'sensitive spoken content',
      );
    });
    try {
      await NativeVoiceInput().listen();
      fail('Expected failure');
    } catch (error) {
      expect(error, isA<VoiceFailure>());
      expect(error.toString(), isNot(contains('sensitive')));
    }
  });

  test('empty, oversized and malformed transcripts fail closed', () async {
    for (final value in <Object?>[null, '', '    ', 'x' * 2001, 17]) {
      messenger.setMockMethodCallHandler(channel, (_) async => value);
      await expectLater(
        NativeVoiceInput().listen(),
        throwsA(isA<VoiceFailure>()),
      );
    }
  });

  test(
    'cancel rejects a late transcript after a permission/start race',
    () async {
      final gate = Completer<String>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        return call.method == 'listen' ? gate.future : null;
      });
      final voice = NativeVoiceInput();
      final pending = voice.listen();
      final rejected = expectLater(pending, throwsA(isA<VoiceFailure>()));
      await pumpEventQueue();
      await voice.cancel();
      gate.complete('late private text');
      await rejected;
    },
  );

  testWidgets('stuck native session times out and is cancelled', (
    tester,
  ) async {
    final gate = Completer<String>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'listen' ? gate.future : null;
    });
    final pending = NativeVoiceInput().listen();
    final rejected = expectLater(pending, throwsA(isA<VoiceFailure>()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 91));
    await rejected;
    expect(calls, contains('cancel'));
    gate.complete('late');
    await tester.pump();
  });
  test(
    'missing cancellation acknowledgement is observable without native details',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'unavailable',
          message: 'private native details',
        );
      });
      expect(await NativeVoiceInput().cancel(), isFalse);
    },
  );
}
