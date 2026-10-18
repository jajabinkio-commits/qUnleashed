import 'dart:async';

import 'package:flutter/services.dart';

import '../../services/guarded.dart';

class VoiceFailure implements Exception {
  const VoiceFailure();
}

abstract interface class VoiceInput {
  Future<String> listen();
  Future<void> finish();

  /// Whether the native channel acknowledged cancellation.
  Future<bool> cancel();
}

/// iOS on-device dictation only. This channel cannot send AI/device commands.
class NativeVoiceInput implements VoiceInput {
  static const channel = MethodChannel('phantom/speech');
  int _generation = 0;

  @override
  Future<String> listen() async {
    final generation = ++_generation;
    try {
      final text = await channel
          .invokeMethod<String>('listen')
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              if (generation == _generation) {
                unawaited(
                  guarded('[PHANTOM voice] cancel timed-out dictation', () async {
                    await cancel();
                  }),
                );
              }
              throw const VoiceFailure();
            },
          );
      if (generation != _generation ||
          text == null ||
          text.trim().isEmpty ||
          text.length > 2000) {
        throw const VoiceFailure();
      }
      return text.trim();
    } catch (_) {
      throw const VoiceFailure(); // No native details or transcript in errors.
    }
  }

  @override
  Future<void> finish() async {
    try {
      await channel
          .invokeMethod<void>('finish')
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      throw const VoiceFailure();
    }
  }

  @override
  Future<bool> cancel() async {
    _generation++;
    try {
      await channel
          .invokeMethod<void>('cancel')
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      // Report the missing acknowledgement without leaking native details.
      return false;
    }
  }
}
