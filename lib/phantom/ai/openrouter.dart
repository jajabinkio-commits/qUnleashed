import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AiFailure implements Exception {
  const AiFailure(this.code);
  final String code;
  @override
  String toString() => 'AI unavailable ($code)';
}

class AiReply {
  const AiReply({required this.message, this.totalTokens});
  final Map<String, Object?> message;
  final int? totalTokens;
}

abstract interface class AiProvider {
  Future<AiReply> complete({
    required String key,
    required String model,
    required List<Map<String, Object?>> messages,
    required bool allowDeviceTools,
  });
  void close();
}

/// Verified against OpenRouter's OpenAPI schema. Custom function tools only;
/// no server-side shell, web, file, or other built-in tools are requested.
class OpenRouterProvider implements AiProvider {
  OpenRouterProvider({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  bool _closed = false;
  static final endpoint = Uri.parse(
    'https://openrouter.ai/api/v1/chat/completions',
  );
  static const toolNames = ['device_status', 'device_capabilities'];

  @override
  Future<AiReply> complete({
    required String key,
    required String model,
    required List<Map<String, Object?>> messages,
    required bool allowDeviceTools,
  }) async {
    if (_closed) throw const AiFailure('cancelled');
    if (key.isEmpty ||
        key.length > 512 ||
        key.contains(RegExp(r'[\s\x00-\x1f\x7f]'))) {
      throw const AiFailure('key');
    }
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9/_.:\-]{1,127}$').hasMatch(model)) {
      throw const AiFailure('model');
    }
    if (jsonEncode(messages).contains(key)) {
      throw const AiFailure('sensitive_input');
    }
    if (utf8.encode(jsonEncode(messages)).length > 20000) {
      throw const AiFailure('budget');
    }
    try {
      return await _request(key, model, messages, allowDeviceTools).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          close();
          throw const AiFailure('timeout');
        },
      );
    } on AiFailure {
      rethrow;
    } catch (_) {
      // Do not propagate HTTP headers, provider bodies, credentials or prompts.
      throw AiFailure(_closed ? 'cancelled' : 'network');
    }
  }

  Future<AiReply> _request(
    String key,
    String model,
    List<Map<String, Object?>> messages,
    bool tools,
  ) async {
    final request = http.Request('POST', endpoint)
      ..headers.addAll({
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': false,
        'max_completion_tokens': 512,
        if (tools)
          'tools': [
            for (final name in toolNames)
              {
                'type': 'function',
                'function': {
                  'name': name,
                  'description': name == 'device_status'
                      ? 'Read observed, minimized status of the selected Flipper.'
                      : 'Read verified capabilities of the selected Flipper.',
                  'parameters': {
                    'type': 'object',
                    'properties': <String, Object?>{},
                    'additionalProperties': false,
                    'required': <String>[],
                  },
                },
              },
          ],
      });
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw AiFailure('http_${response.statusCode}');
    }
    final bytes = <int>[];
    await for (final part in response.stream) {
      if (_closed) throw const AiFailure('cancelled');
      if (bytes.length + part.length > 65536) {
        throw const AiFailure('response_size');
      }
      bytes.addAll(part);
    }
    final body = jsonDecode(utf8.decode(bytes));
    if (body is! Map ||
        body['choices'] is! List ||
        (body['choices'] as List).isEmpty) {
      throw const AiFailure('response');
    }
    final choice = (body['choices'] as List).first;
    if (choice is! Map || choice['message'] is! Map) {
      throw const AiFailure('response');
    }
    final message = choice['message'] as Map;
    final content = message['content'];
    if (content != null && (content is! String || content.length > 16000)) {
      throw const AiFailure('response');
    }
    final calls = message['tool_calls'];
    if (calls != null && (calls is! List || calls.length > 4)) {
      throw const AiFailure('tool_schema');
    }
    final cleaned = <Map<String, Object?>>[];
    for (final call in (calls as List? ?? [])) {
      if (call is! Map ||
          call['type'] != 'function' ||
          call['id'] is! String ||
          (call['id'] as String).length > 128 ||
          call['function'] is! Map) {
        throw const AiFailure('tool_schema');
      }
      final function = call['function'] as Map;
      if (function['name'] is! String ||
          function['arguments'] is! String ||
          (function['arguments'] as String).length > 1024) {
        throw const AiFailure('tool_schema');
      }
      cleaned.add({
        'id': call['id'],
        'type': 'function',
        'function': {
          'name': function['name'],
          'arguments': function['arguments'],
        },
      });
    }
    final usage = body['usage'];
    final tokens = usage is Map && usage['total_tokens'] is int
        ? usage['total_tokens'] as int
        : null;
    if (tokens != null && tokens < 0) throw const AiFailure('response');
    return AiReply(
      message: {
        'role': 'assistant',
        'content': content is String
            ? content.replaceAll(key, '[redacted credential]')
            : null,
        if (cleaned.isNotEmpty) 'tool_calls': cleaned,
      },
      totalTokens: tokens,
    );
  }

  @override
  void close() {
    _closed = true;
    _client.close();
  }
}

class ModelChoice {
  const ModelChoice(this.id, this.name);
  final String id;
  final String name;
}

/// Public model discovery; invoked by an explicit UI action, not startup.
Future<List<ModelChoice>> loadOpenRouterModels({http.Client? client}) async {
  final connection = client ?? http.Client();
  try {
    final response = await connection
        .send(
          http.Request('GET', Uri.parse('https://openrouter.ai/api/v1/models')),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw const AiFailure('models');
    final bytes = <int>[];
    await for (final part in response.stream.timeout(
      const Duration(seconds: 10),
    )) {
      if (bytes.length + part.length > 4000000) throw const AiFailure('models');
      bytes.addAll(part);
    }
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map || data['data'] is! List) throw const AiFailure('models');
    final choices = <String, ModelChoice>{};
    for (final item in data['data'] as List) {
      if (item is! Map ||
          item['id'] is! String ||
          item['name'] is! String ||
          item['supported_parameters'] is! List ||
          !(item['supported_parameters'] as List).contains('tools')) {
        continue;
      }
      final id = item['id'] as String;
      if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9/_.:\-]{1,127}$').hasMatch(id)) {
        continue;
      }
      choices[id] = ModelChoice(id, item['name'] as String);
    }
    if (choices.isEmpty) throw const AiFailure('models');
    return choices.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  } on AiFailure {
    rethrow;
  } catch (_) {
    throw const AiFailure('models');
  } finally {
    connection.close();
  }
}
