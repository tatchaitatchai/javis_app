import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/entrance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/pressable.dart';
import 'add_device_screen.dart';

/// Opens “Add device” as a sheet-style page over the current tab.
void openAddDevice(BuildContext context, {String? zoneId}) =>
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DeviceTypeScreen(zoneId: zoneId),
      ),
    );

/// 14 · Choose what to add. Bulbs pair for real or in demo; the lock is
/// shown but not pairable yet (spec 012).
class DeviceTypeScreen extends StatelessWidget {
  const DeviceTypeScreen({this.zoneId, super.key});
  final String? zoneId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = context.app.homes.activeHome;
    return FlowPage(
      top: const FlowTopBar(leading: CalmBackButton(close: true)),
      footer: Text(
        l10n.moreDevicesLater,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        const SizedBox(height: 8),
        FlowHeader(
          title: l10n.whatToAdd,
          subtitle: home == null ? null : Text(l10n.addingTo(home.name)),
        ),
        const SizedBox(height: 24),
        Entrance(
          child: _TypeCard(
            icon: CupertinoIcons.lightbulb_fill,
            title: l10n.deviceTypeBulb,
            subtitle: l10n.deviceTypeProtocol,
            onTap: () {
              final lighting = context.app.lighting;
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute<void>(
                  builder: (_) =>
                      AddDeviceScreen(service: lighting, zoneId: zoneId),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Entrance(
          order: 1,
          child: _TypeCard(
            icon: CupertinoIcons.lock_fill,
            title: l10n.deviceTypeLock,
            subtitle: l10n.deviceTypeProtocol,
            badge: l10n.comingSoon,
            onTap: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.lockPairingLater))),
          ),
        ),
        const SizedBox(height: 22),
        InfoNote(
          icon: CupertinoIcons.info_circle,
          title: l10n.beforeYouStart,
          text: l10n.beforeYouStartBody,
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onTap,
      pressedScale: .98,
      semanticLabel: [title, subtitle, ?badge].join(', '),
      excludeChildSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.accentTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: palette.accentDeep, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13.5, color: palette.textMuted),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    StatusBadge(badge!, subtle: true),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
