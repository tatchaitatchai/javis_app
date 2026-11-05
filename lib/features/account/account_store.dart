import 'package:flutter/foundation.dart';

import '../home/home_models.dart';

enum AccountStage { signedOut, onboarding, signedIn }

enum OtpOutcome { existingAccount, newAccount, invalidCode }

/// Mock phone + OTP session (spec 012). No SMS is sent; any six digits other
/// than `000000` are accepted so the error state can still be previewed.
class AccountStore extends ChangeNotifier {
  AccountStore({this.networkDelay = const Duration(milliseconds: 700)});

  /// The demo number that already has an account and homes.
  static const demoPhone = '0812345678';
  static const resendAfter = Duration(seconds: 45);

  final Duration networkDelay;
  AccountStage _stage = AccountStage.signedOut;
  String? _phone;
  String? _name;
  DateTime? _codeSentAt;

  AccountStage get stage => _stage;
  bool get signedIn => _stage == AccountStage.signedIn;
  String? get phone => _phone;
  String get name => _name ?? '';
  DateTime? get codeSentAt => _codeSentAt;

  Member get asMember => Member(
    id: 'you',
    name: name,
    phone: _phone ?? '',
    role: HomeRole.owner,
    canUnlock: true,
    isYou: true,
  );

  /// Signs straight into the demo account (used by tests and previews).
  void signInDemo() {
    _phone = demoPhone;
    _name = 'มายด์';
    _stage = AccountStage.signedIn;
    notifyListeners();
  }

  Future<void> requestCode(String phoneDigits) async {
    await Future<void>.delayed(networkDelay);
    _phone = phoneDigits;
    _codeSentAt = DateTime.now();
    notifyListeners();
  }

  Future<OtpOutcome> verify(String code) async {
    await Future<void>.delayed(networkDelay);
    if (code.length != 6 || code == '000000') return OtpOutcome.invalidCode;
    if (_phone == demoPhone) {
      _name = 'มายด์';
      return OtpOutcome.existingAccount;
    }
    _stage = AccountStage.onboarding;
    notifyListeners();
    return OtpOutcome.newAccount;
  }

  void setName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _name = trimmed;
    notifyListeners();
  }

  void completeSignIn() {
    _stage = AccountStage.signedIn;
    notifyListeners();
  }

  void signOut() {
    _stage = AccountStage.signedOut;
    _phone = null;
    _name = null;
    _codeSentAt = null;
    notifyListeners();
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
