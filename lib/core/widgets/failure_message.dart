import 'package:flutter/material.dart';

import '../../backend/backend_failure.dart';
import '../localization/app_localizations.dart';
import '../motion/motion.dart';

/// Runs a backend [action] and reports a failure as a calm message. Returns
/// whether it succeeded, so the screen can stay as it is when it did not.
Future<bool> attempt(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  try {
    await action();
    return true;
  } on BackendFailure catch (failure) {
    Haptics.warn();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.failure(failure))));
    return false;
  }
}
