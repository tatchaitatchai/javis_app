import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../backend/backend_failure.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_segment.dart';
import '../../core/widgets/calm_sheet.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_switch.dart';
import '../account/account_store.dart';
import 'home_models.dart';

/// Whether the signed-in person can do anything to [member].
bool canOpenMemberSheet(BuildContext context, Member member) {
  final homes = context.app.homes;
  return _canEditRights(homes.activeHome, member) || homes.canRemove(member);
}

/// Only the owner edits rights, and never their own or an invitation's.
bool _canEditRights(Home? home, Member member) =>
    (home?.isOwner ?? false) && !member.pending && !member.isYou;

Future<void> showMemberSheet(BuildContext context, String memberId) =>
    showCalmSheet<void>(
      context: context,
      builder: (_) => _MemberSheet(memberId: memberId),
    );

class _MemberSheet extends StatefulWidget {
  const _MemberSheet({required this.memberId});
  final String memberId;

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  bool _removing = false;
  String? _error;

  Future<void> _run(Future<void> Function() change) async {
    final l10n = context.l10n;
    setState(() => _error = null);
    try {
      await change();
    } on BackendFailure catch (failure) {
      Haptics.warn();
      if (mounted) setState(() => _error = l10n.failure(failure));
    }
  }

  Future<bool> _confirmRemoval(Member member) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.removeMemberQuestion(member.name ?? member.phone)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.removeFromHome),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _remove(Member member) async {
    if (!member.pending && !await _confirmRemoval(member)) return;
    if (!mounted) return;
    setState(() => _removing = true);
    final homes = context.app.homes;
    await _run(() => homes.removeMember(member));
    if (!mounted) return;
    setState(() => _removing = false);
    if (_error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final homes = context.app.homes;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: homes,
      builder: (context, _) {
        final home = homes.activeHome;
        final member = home?.members
            .where((item) => item.id == widget.memberId)
            .firstOrNull;
        if (member == null) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              member.pending
                  ? maskThaiMobile(member.phone)
                  : member.name ?? l10n.unnamedMember,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_canEditRights(home, member)) ...[
              SectionHeader(
                l10n.yourRoleLabel,
                padding: const EdgeInsets.only(top: 16, bottom: 8),
              ),
              CalmSegment<HomeRole>(
                options: [
                  for (final role in [HomeRole.admin, HomeRole.member])
                    (role, l10n.role(role.name)),
                ],
                selected: member.role,
                onChanged: (role) =>
                    _run(() => homes.updateMember(member, role: role)),
              ),
              const SizedBox(height: 16),
              ListGroup(
                children: [
                  ListRow(
                    title: l10n.allowUnlock,
                    trailing: CalmSwitch(
                      value: member.canUnlock,
                      semanticLabel: l10n.allowUnlock,
                      onChanged: (value) => _run(
                        () => homes.updateMember(member, canUnlock: value),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: context.palette.danger,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
            if (homes.canRemove(member)) ...[
              const SizedBox(height: 20),
              SecondaryButton(
                label: member.pending ? l10n.revokeInvite : l10n.removeFromHome,
                destructive: true,
                loading: _removing,
                onPressed: () => _remove(member),
              ),
            ],
          ],
        );
      },
    );
  }
}
