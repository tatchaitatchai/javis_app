import 'package:flutter/foundation.dart';

import '../../backend/backend_failure.dart';
import '../../backend/demo_backend.dart';
import '../../backend/javis_backend.dart';

/// `restoring` and `unreachable` only happen at launch with the API.
enum AccountStage { restoring, unreachable, signedOut, onboarding, signedIn }

enum OtpOutcome { existingAccount, newAccount, invalidCode }

/// The signed-in person and the sign-in flow.
class AccountStore extends ChangeNotifier {
  AccountStore(this._backend)
    : _stage = _backend.isDemo
          ? AccountStage.signedOut
          : AccountStage.restoring {
    _backend.onSessionExpired = _clear;
  }

  final JavisBackend _backend;
  AccountStage _stage;
  String? _phone;
  String? _name;
  String? _debugCode;
  DateTime? _codeSentAt;
  Duration _resendAfter = Duration.zero;

  /// Clears what belongs to the account: homes and scenes.
  VoidCallback? onSignedOut;

  AccountStage get stage => _stage;
  bool get signedIn => _stage == AccountStage.signedIn;
  bool get isDemo => _backend.isDemo;
  String? get phone => _phone;
  String get name => _name ?? '';
  String? get debugCode => _debugCode;
  DateTime? get codeSentAt => _codeSentAt;
  Duration get resendAfter => _resendAfter;

  /// Signs straight into the demo account (used by tests and previews).
  void signInDemo() {
    _phone = DemoBackend.demoPhone;
    _name = DemoBackend.demoName;
    _stage = AccountStage.signedIn;
    notifyListeners();
  }

  /// Finds a stored session. Returns true when one is valid; the caller loads
  /// the homes and then calls [completeSignIn].
  Future<bool> restore() async {
    _setStage(AccountStage.restoring);
    try {
      final user = await _backend.restoreSession();
      if (user != null && user.name != null) {
        _adopt(user);
        return true;
      }
      // Sign-up stopped before the profile step: start it again.
      if (user != null) await _backend.signOut();
      _setStage(AccountStage.signedOut);
    } on BackendFailure {
      _setStage(AccountStage.unreachable);
    }
    return false;
  }

  Future<void> requestCode(String phoneDigits) async {
    final challenge = await _backend.requestCode(phoneDigits);
    _phone = phoneDigits;
    _debugCode = challenge.debugCode;
    _resendAfter = challenge.resendAfter;
    _codeSentAt = DateTime.now();
    notifyListeners();
  }

  Future<OtpOutcome> verify(String code) async {
    final AccountUser user;
    try {
      user = await _backend.verifyCode(_phone!, code);
    } on BackendFailure catch (failure) {
      if (failure.code == 'invalid_code') return OtpOutcome.invalidCode;
      rethrow;
    }
    _adopt(user);
    if (user.name != null) return OtpOutcome.existingAccount;
    _setStage(AccountStage.onboarding);
    return OtpOutcome.newAccount;
  }

  /// Moves an existing account with no home into the onboarding steps.
  void startOnboarding() => _setStage(AccountStage.onboarding);

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final before = _name;
    _name = trimmed;
    notifyListeners();
    try {
      await _backend.updateName(trimmed);
    } on BackendFailure {
      _name = before;
      notifyListeners();
      rethrow;
    }
  }

  void completeSignIn() => _setStage(AccountStage.signedIn);

  Future<void> signOut() async {
    _clear();
    await _backend.signOut();
  }

  void _adopt(AccountUser user) {
    _phone = user.phone;
    _name = user.name;
    _debugCode = null;
  }

  void _setStage(AccountStage stage) {
    _stage = stage;
    notifyListeners();
  }

  void _clear() {
    _phone = null;
    _name = null;
    _debugCode = null;
    _codeSentAt = null;
    onSignedOut?.call();
    _setStage(AccountStage.signedOut);
  }
}

/// Digits of a Thai mobile number in local form (`0XXXXXXXXX`), or null.
String? normalizeThaiMobile(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('66')) digits = '0${digits.substring(2)}';
  if (digits.length == 9 && !digits.startsWith('0')) digits = '0$digits';
  final valid = RegExp(r'^0[689]\d{8}$').hasMatch(digits);
  return valid ? digits : null;
}

/// `0812345678` → `081 234 5678`. Partial input is grouped as typed.
String formatThaiMobile(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 3 || i == 6) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `0891234521` → `089 xxx 4521` for people who have not joined yet.
String maskThaiMobile(String digits) => digits.length == 10
    ? '${digits.substring(0, 3)} xxx ${digits.substring(6)}'
    : digits;

/// `0812345678` → `+66 81 234 5678` for the profile row.
String internationalThaiMobile(String digits) => digits.length == 10
    ? '+66 ${digits.substring(1, 3)} ${digits.substring(3, 6)} '
          '${digits.substring(6)}'
    : digits;
