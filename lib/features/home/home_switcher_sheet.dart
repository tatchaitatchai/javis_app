import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/dashed_border.dart';
import '../../core/widgets/pressable.dart';
import '../onboarding/create_home_screen.dart';
import '../onboarding/invite_accept_screen.dart';
import 'home_models.dart';
import 'home_settings_screen.dart';

/// 07 · Switch home, add a home, or open the current home's settings.
Future<void> showHomeSwitcher(BuildContext context) async {
  final next = await showCalmSheet<WidgetBuilder>(
    context: context,
    builder: (_) => const _HomeSwitcher(),
  );
  if (next != null && context.mounted) {
    await Navigator.of(context).push(CupertinoPageRoute<void>(builder: next));
  }
}

class _HomeSwitcher extends StatelessWidget {
  const _HomeSwitcher();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l10n = context.l10n;
    final active = app.homes.activeHome;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.myHomes,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        for (final home in app.homes.homes)
          _HomeRow(
            home: home,
            active: home.id == active?.id,
            onTap: () {
              app.homes.switchHome(home.id);
              Navigator.of(context).pop();
            },
          ),
        for (final invite in app.homes.invites)
          _ActionRow(
            icon: CupertinoIcons.envelope,
            label: l10n.inviteFrom(
              invite.invitedBy ?? l10n.someone,
              invite.homeName,
            ),
            onTap: () => Navigator.of(context).pop<WidgetBuilder>(
              (_) => InviteAcceptScreen(inviteId: invite.id),
            ),
          ),
        Divider(height: 17, color: context.palette.hairline),
        _ActionRow(
          icon: CupertinoIcons.add,
          label: l10n.addHome,
          dashed: true,
          onTap: () => Navigator.of(context).pop<WidgetBuilder>(
            (_) => const CreateHomeScreen(addingAnother: true),
          ),
        ),
        if (active != null)
          _ActionRow(
            icon: CupertinoIcons.gear,
            label: l10n.settingsFor(active.name),
            onTap: () =>
                Navigator.of(context)
                    .pop<WidgetBuilder>((_) => const HomeSettingsScreen()),
          ),
      ],
    );
  }
}

class _HomeRow extends StatelessWidget {
  const _HomeRow({
    required this.home,
    required this.active,
    required this.onTap,
  });

  final Home home;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final app = context.app;
    final devices = app.homes.deviceCount(home, app.lighting);
    final summary = home.invitedBy != null
        ? l10n.memberInvitedBy(l10n.role(home.role.name), home.invitedBy!)
        : '${l10n.role(home.role.name)} · '
              '${l10n.zonesAndDevices(home.zones.length, devices)}';
    return Pressable(
      onPressed: onTap,
      selected: active,
      pressedScale: .98,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.quick),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? palette.accentTint : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? palette.accent : palette.raised,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                home.invitedBy != null
                    ? CupertinoIcons.person_2_fill
                    : CupertinoIcons.house_fill,
                size: 22,
                color: active ? palette.onStrong : palette.accentDeep,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    home.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(summary, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (active)
              Icon(
                CupertinoIcons.checkmark_alt,
                color: palette.accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = dashed ? palette.accentDeep : palette.text;
    final iconBox = SizedBox.square(
      dimension: 48,
      child: Icon(icon, size: 22, color: color),
    );
    return Pressable(
      onPressed: onTap,
      pressedScale: .98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            dashed
                ? CustomPaint(
                    painter: DashedBorderPainter(
                      color: palette.accentSoft,
                      radius: 14,
                    ),
                    child: iconBox,
                  )
                : iconBox,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: dashed ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
