import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';
import '../account/account_store.dart';
import '../shell/app_root.dart';

/// 08 · Accept an invitation to someone else's home.
class InviteAcceptScreen extends StatelessWidget {
  const InviteAcceptScreen({required this.inviteId, super.key});
  final String inviteId;

  void _leave(BuildContext context) {
    if (context.app.account.stage == AccountStage.onboarding) {
      enterHome(context);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final invite = app.homes.invites
        .where((item) => item.id == inviteId)
        .firstOrNull;
    final l10n = context.l10n;
    final palette = context.palette;
    if (invite == null) {
      return FlowPage(
        top: const Align(
          alignment: Alignment.centerLeft,
          child: CalmBackButton(),
        ),
        children: [FlowHeader(title: l10n.inviteGone)],
      );
    }
    return FlowPage(
      top: const Align(
        alignment: Alignment.centerLeft,
        child: CalmBackButton(),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: l10n.joinHome,
            onPressed: () {
              Haptics.confirm();
              app.homes.acceptInvite(invite.id, app.account.asMember);
              _leave(context);
            },
          ),
          const SizedBox(height: 4),
          QuietButton(
            label: l10n.decline,
            accent: false,
            onPressed: () {
              app.homes.declineInvite(invite.id);
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: palette.accentTint,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              CupertinoIcons.house_fill,
              size: 44,
              color: palette.accent,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.invitedYou(invite.invitedBy),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: palette.textMuted),
        ),
        Text(
          invite.homeName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 28),
        ListGroup(
          children: [
            ListRow(title: l10n.yourRole, value: l10n.role(invite.role.name)),
            ListRow(
              title: l10n.inThisHome,
              value: l10n.zonesAndDevices(
                invite.zoneKeys.length,
                invite.deviceCount,
              ),
            ),
            ListRow(
              title: l10n.inviteExpires,
              value: l10n.inDays(invite.expiresInDays),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.memberRightsNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
