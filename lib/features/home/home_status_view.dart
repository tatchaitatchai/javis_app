import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../onboarding/create_home_screen.dart';
import '../onboarding/invite_accept_screen.dart';

/// The dashboard when there is no home to show: still loading, loading failed,
/// or an account with no home.
class HomeStatusView extends StatelessWidget {
  const HomeStatusView({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(CupertinoPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final homes = context.app.homes;
    final l10n = context.l10n;
    if (homes.loading) {
      return Center(
        child: CupertinoActivityIndicator(color: context.palette.textMuted),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: homes.loadFailed
                  ? [
                      FlowHeader(title: l10n.cantLoadHomes),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: l10n.tryAgain,
                        onPressed: homes.load,
                      ),
                    ]
                  : [
                      FlowHeader(
                        title: l10n.noHomeYetTitle,
                        subtitle: Text(l10n.noHomeYetBody),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: l10n.createHome,
                        onPressed: () => _open(
                          context,
                          const CreateHomeScreen(addingAnother: true),
                        ),
                      ),
                      for (final invite in homes.invites)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SecondaryButton(
                            label: l10n.inviteFrom(
                              invite.invitedBy ?? l10n.someone,
                              invite.homeName,
                            ),
                            onPressed: () => _open(
                              context,
                              InviteAcceptScreen(inviteId: invite.id),
                            ),
                          ),
                        ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
