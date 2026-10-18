import 'package:flutter/services.dart';

abstract interface class CredentialStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> erase();
}

/// Native iOS Keychain only: there is no preferences/plaintext fallback.
class KeychainCredentialStore implements CredentialStore {
  const KeychainCredentialStore();
  static const channel = MethodChannel('phantom/credentials');

  @override
  Future<String?> read() => channel.invokeMethod<String>('read');
  @override
  Future<void> write(String key) =>
      channel.invokeMethod<void>('write', {'key': key});
  @override
  Future<void> erase() => channel.invokeMethod<void>('erase');
}
