import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/failure_message.dart';
import '../../core/widgets/flow_page.dart';
import '../account/account_store.dart';
import 'home_models.dart';
import 'member_sheet.dart';
import 'members_screen.dart';
import 'zone_name_sheet.dart';

/// 22 · Name, zones and members of the active home.
class HomeSettingsScreen extends StatelessWidget {
  const HomeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListenableBuilder(
      listenable: Listenable.merge([app.homes, app.lighting]),
      builder: (context, _) {
        final home = app.homes.activeHome;
        if (home == null) return const _NoHome();
        return _HomeSettings(home: home);
      },
    );
  }
}

class _HomeSettings extends StatelessWidget {
  const _HomeSettings({required this.home});
  final Home home;

  Future<void> _rename(BuildContext context) async {
    final l10n = context.l10n;
    final name = await showZoneNameSheet(
      context,
      title: l10n.renameHome,
      label: l10n.homeName,
      initial: home.name,
    );
    if (name != null && context.mounted) {
      final homes = context.app.homes;
      await attempt(context, () => homes.renameActiveHome(name));
    }
  }

  Future<void> _addZone(BuildContext context) async {
    final name = await showZoneNameSheet(context);
    if (name != null && context.mounted) {
      final homes = context.app.homes;
      await attempt(context, () => homes.addZone(name));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.deleteHomeQuestion(home.name)),
        content: Text(l10n.deleteHomeBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final homes = context.app.homes;
    final deleted = await attempt(context, homes.deleteActiveHome);
    if (!deleted || !context.mounted) return;
    Haptics.warn();
    Navigator.of(context).pop();
  }

  Future<void> _leave(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.leaveHomeQuestion(home.name)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.leaveHome),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final homes = context.app.homes;
    final left = await attempt(context, homes.leaveActiveHome);
    if (!left || !context.mounted) return;
    Haptics.warn();
    Navigator.of(context).pop();
  }

  int _devicesIn(BuildContext context, Zone zone) {
    final app = context.app;
    return app.homes
        .lightsIn(app.lighting)
        .where((device) => app.homes.zoneIdFor(device) == zone.id)
        .length;
  }

  String _memberTitle(AppLocalizations l10n, Member member) {
    if (member.pending) return maskThaiMobile(member.phone);
    final name = member.name ?? l10n.unnamedMember;
    return member.isYou ? l10n.youSuffix(name) : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final manage = home.canManage;
    final homes = context.app.homes;
    final canDelete = homes.canDeleteActive();
    return FlowPage(
      top: FlowTopBar(
        leading: const CalmBackButton(),
        center: Text(
          l10n.homeSettings,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      footer: canDelete
          ? SecondaryButton(
              label: l10n.deleteHome,
              destructive: true,
              onPressed: () => _delete(context),
            )
          : homes.canLeaveActive
          ? SecondaryButton(
              label: l10n.leaveHome,
              destructive: true,
              onPressed: () => _leave(context),
            )
          : null,
      children: [
        const SizedBox(height: 12),
        ListGroup(
          children: [
            ListRow(
              title: l10n.homeName,
              value: home.name,
              chevron: manage,
              onTap: manage ? () => _rename(context) : null,
            ),
          ],
        ),
        SectionHeader(
          l10n.zonesCount(home.zones.length),
          action: manage
              ? QuietButton(
                  label: l10n.addZone,
                  icon: CupertinoIcons.add,
                  onPressed: () => _addZone(context),
                )
              : null,
        ),
        ListGroup(
          children: [
            for (final zone in home.zones)
              ListRow(
                title: zone.label(l10n),
                value: l10n.deviceCount(_devicesIn(context, zone)),
              ),
          ],
        ),
        SectionHeader(
          l10n.membersCount(home.members.length),
          action: manage
              ? QuietButton(
                  label: l10n.inviteMember,
                  icon: CupertinoIcons.add,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const MembersScreen(),
                    ),
                  ),
                )
              : null,
        ),
        ListGroup(
          children: [
            for (final member in home.members)
              ListRow(
                leading: InitialAvatar(
                  member.pending ? '' : member.name ?? '',
                  strong: member.isYou,
                ),
                title: _memberTitle(l10n, member),
                subtitle: member.pending ? l10n.invitePending : null,
                onTap: canOpenMemberSheet(context, member)
                    ? () => showMemberSheet(context, member.id)
                    : null,
                trailing: StatusBadge(
                  l10n.role(member.role.name),
                  subtle: member.role == HomeRole.member,
                ),
              ),
          ],
        ),
        if (!home.connected) ...[
          const SizedBox(height: 16),
          Text(
            l10n.previewHomeBody(home.previewDeviceCount),
            style: TextStyle(fontSize: 13, color: palette.textMuted),
          ),
        ],
      ],
    );
  }
}

class _NoHome extends StatelessWidget {
  const _NoHome();

  @override
  Widget build(BuildContext context) => const FlowPage(
    top: FlowTopBar(leading: CalmBackButton()),
    children: [],
  );
}
