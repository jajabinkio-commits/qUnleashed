import 'dart:convert';

import 'package:qunleashed/phantom/ai/credentials.dart';
import 'package:qunleashed/phantom/ai/openrouter.dart';

class MemoryCredentials implements CredentialStore {
  String? key = 'fake-test-key';
  @override
  Future<String?> read() async => key;
  @override
  Future<void> write(String key) async {
    this.key = key;
  }

  @override
  Future<void> erase() async {
    key = null;
  }
}

class ScriptedProvider implements AiProvider {
  ScriptedProvider(this.respond);
  final Future<AiReply> Function(int index) respond;
  final requests = <List<Map<String, Object?>>>[];
  final toolsAllowed = <bool>[];
  bool closed = false;
  @override
  Future<AiReply> complete({
    required String key,
    required String model,
    required List<Map<String, Object?>> messages,
    required bool allowDeviceTools,
  }) {
    requests.add(
      (jsonDecode(jsonEncode(messages)) as List)
          .map((e) => Map<String, Object?>.from(e as Map))
          .toList(),
    );
    toolsAllowed.add(allowDeviceTools);
    return respond(requests.length - 1);
  }

  @override
  void close() {
    closed = true;
  }
}

AiReply textReply(String text) =>
    AiReply(message: {'role': 'assistant', 'content': text});
AiReply toolReply(
  String name, {
  String arguments = '{}',
  String id = 'call_1',
}) => AiReply(
  message: {
    'role': 'assistant',
    'content': null,
    'tool_calls': [
      {
        'id': id,
        'type': 'function',
        'function': {'name': name, 'arguments': arguments},
      },
    ],
  },
);
