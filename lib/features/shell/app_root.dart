import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/motion/motion.dart';
import '../onboarding/welcome_screen.dart';
import 'app_shell.dart';

/// Shows the welcome flow until the account is signed in, then the tabs.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.app.account;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) => AnimatedSwitcher(
        duration: Motion.of(context, Motion.gentle),
        switchInCurve: Motion.curve,
        child: account.signedIn
            ? const AppShell(key: ValueKey('shell'))
            : const WelcomeScreen(key: ValueKey('welcome')),
      ),
    );
  }
}

/// Completes sign-in from anywhere in the onboarding stack: the root swaps to
/// the tabs and the pushed onboarding routes are removed.
void enterHome(BuildContext context) {
  final navigator = Navigator.of(context);
  context.app.account.completeSignIn();
  navigator.popUntil((route) => route.isFirst);
}
