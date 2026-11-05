import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../account/account_store.dart';
import '../onboarding/connection_screen.dart';
import '../onboarding/welcome_screen.dart';
import 'app_shell.dart';

/// Shows the welcome flow until the account is signed in, then the tabs.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    final app = context.app;
    if (app.account.stage == AccountStage.restoring) restoreSession(app);
  }

  @override
  Widget build(BuildContext context) {
    final account = context.app.account;
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) => AnimatedSwitcher(
        duration: Motion.of(context, Motion.gentle),
        switchInCurve: Motion.curve,
        child: switch (account.stage) {
          AccountStage.restoring => ColoredBox(
            key: const ValueKey('restoring'),
            color: context.palette.canvas,
            child: const SizedBox.expand(),
          ),
          AccountStage.unreachable => const ConnectionScreen(
            key: ValueKey('unreachable'),
          ),
          AccountStage.signedIn => const AppShell(key: ValueKey('shell')),
          _ => const WelcomeScreen(key: ValueKey('welcome')),
        },
      ),
    );
  }
}

/// Reopens a stored session. Homes load first so the dashboard opens complete.
Future<void> restoreSession(AppScope app) async {
  if (!await app.account.restore()) return;
  await app.homes.load();
  app.account.completeSignIn();
}

/// Completes sign-in from anywhere in the onboarding stack: the root swaps to
/// the tabs and the pushed onboarding routes are removed.
void enterHome(BuildContext context) {
  final navigator = Navigator.of(context);
  context.app.account.completeSignIn();
  navigator.popUntil((route) => route.isFirst);
}
