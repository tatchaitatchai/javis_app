import 'package:flutter/services.dart';

/// Where the session token is kept between launches.
abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// The iOS Keychain, through `SessionVault.swift`.
class KeychainSessionVault implements SessionVault {
  static const _channel = MethodChannel('com.javis.home/session');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String token) =>
      _channel.invokeMethod<void>('write', {'token': token});

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');
}
