import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qunleashed/pages/tools/remote/desktop/models/models.dart';
import 'package:qunleashed/pages/tools/remote/desktop/screenshot_encoder.dart';
import 'package:qunleashed/phantom/ai/openrouter.dart';
import 'package:qunleashed/phantom/ai/screen_interpreter.dart';

import 'phantom_ai_fakes.dart';

ScreenAttachment sampleScreen() => ScreenAttachment(
  encodeScreenshotPng(
    RawFrameData(
      pixelIndices: Uint8List(8192),
      rgba: Uint8List(32768),
      bgColor: 0xff000000,
      fgColor: 0xffffffff,
      orientation: StreamOrientation.horizontal,
    ),
  ),
  capturedAt: DateTime.utc(2026, 10, 16),
);

void main() {
  const vision = ModelChoice('vendor/vision', 'Vision', supportsImages: true);
  late ScriptedProvider provider;
  late ScreenInterpreter interpreter;
  setUp(() {
    provider = ScriptedProvider((_) async => textReply('Inferred: menu.'));
    interpreter = ScreenInterpreter(
      credentials: MemoryCredentials(),
      createProvider: () => provider,
    );
  });
  tearDown(() => interpreter.stop());

  test(
    'screen copy is immutable; invalid dimensions and oversized input fail',
    () {
      final screen = sampleScreen();
      expect(() => screen.png[0] = 0, throwsUnsupportedError);
      final bytes = Uint8List.fromList(screen.png);
      final copy = ScreenAttachment(bytes, capturedAt: screen.capturedAt);
      bytes[0] = 0;
      expect(copy.png[0], 137);
      expect(
        () => ScreenAttachment(Uint8List(8193), capturedAt: screen.capturedAt),
        throwsA(isA<AiFailure>()),
      );
      final invalid = Uint8List.fromList(screen.png);
      ByteData.sublistView(invalid).setUint32(16, 99999);
      expect(
        () => ScreenAttachment(invalid, capturedAt: screen.capturedAt),
        throwsA(isA<AiFailure>()),
      );
    },
  );

  test(
    'no consent or incompatible model creates no provider request',
    () async {
      await expectLater(
        interpreter.explain(sampleScreen(), model: vision, consent: false),
        throwsA(isA<AiFailure>()),
      );
      await expectLater(
        interpreter.explain(
          sampleScreen(),
          model: const ModelChoice('a/text', 'Text'),
          consent: true,
        ),
        throwsA(isA<AiFailure>()),
      );
      expect(provider.requests, isEmpty);
    },
  );

  test(
    'one image with no tools, no identifiers and no retained history',
    () async {
      for (var i = 0; i < 2; i++) {
        expect(
          await interpreter.explain(
            sampleScreen(),
            model: vision,
            consent: true,
          ),
          'Inferred: menu.',
        );
      }
      expect(provider.requests, hasLength(2));
      expect(provider.toolsAllowed, [false, false]);
      expect(provider.requests.every((r) => r.length == 2), isTrue);
      final content = provider.requests.first.last['content'] as List;
      expect(content.last['image_url']['url'], sampleScreen().dataUrl);
      expect(jsonEncode(provider.requests), isNot(contains('fake-test-key')));
      expect(jsonEncode(provider.requests), contains('untrusted data'));
    },
  );

  test(
    'hostile model tool proposals cannot execute or start another request',
    () async {
      provider = ScriptedProvider((_) async => toolReply('files_delete'));
      await expectLater(
        interpreter.explain(sampleScreen(), model: vision, consent: true),
        throwsA(isA<AiFailure>()),
      );
      expect(provider.requests, hasLength(1));
      expect(provider.closed, isTrue);
    },
  );

  test('STOP rejects late answers and closes the provider', () async {
    final gate = Completer<AiReply>();
    provider = ScriptedProvider((_) => gate.future);
    final pending = interpreter.explain(
      sampleScreen(),
      model: vision,
      consent: true,
    );
    final rejected = expectLater(pending, throwsA(isA<AiFailure>()));
    await pumpEventQueue();
    interpreter.stop();
    gate.complete(textReply('late'));
    await rejected;
    expect(provider.closed, isTrue);
  });

  test(
    'vision catalog includes images without requiring tool support',
    () async {
      final models = await loadOpenRouterModels(
        visionOnly: true,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'vendor/text',
                  'name': 'Text',
                  'supported_parameters': ['tools'],
                  'architecture': {
                    'input_modalities': ['text'],
                  },
                },
                {
                  'id': 'vendor/vision',
                  'name': 'Vision',
                  'supported_parameters': [],
                  'architecture': {
                    'input_modalities': ['text', 'image'],
                  },
                },
                {'id': 'vendor/unknown', 'name': 'Unknown'},
              ],
            }),
            200,
          ),
        ),
      );
      expect(models.single.id, 'vendor/vision');
      expect(models.single.supportsImages, isTrue);
    },
  );

  test('actual HTTP request uses image data URL and excludes tools', () async {
    final api = OpenRouterProvider(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body.containsKey('tools'), isFalse);
        expect(body['max_completion_tokens'], 512);
        expect(
          body['messages'][1]['content'][1]['image_url']['url'],
          startsWith('data:image/png;base64,'),
        );
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Observed pixels: dark screen.'},
              },
            ],
          }),
          200,
        );
      }),
    );
    interpreter = ScreenInterpreter(
      credentials: MemoryCredentials(),
      createProvider: () => api,
    );
    expect(
      await interpreter.explain(sampleScreen(), model: vision, consent: true),
      contains('Observed pixels'),
    );
  });
}
