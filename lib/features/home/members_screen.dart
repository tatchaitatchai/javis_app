import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../backend/backend_failure.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_switch.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/pressable.dart';
import '../account/account_store.dart';
import '../account/phone_field.dart';
import 'home_models.dart';

/// 23 · Invite someone to the active home by mobile number. No SMS is sent:
/// they see the invitation when they sign in with that number. The admin role
/// and the unlock right are the owner's to give.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _phone = TextEditingController();
  HomeRole _role = HomeRole.member;
  bool _canUnlock = false;
  bool _sending = false;
  String? _error;

  String? get _digits => normalizeThaiMobile(_phone.text);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _digits;
    if (digits == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.app.homes.inviteMember(
        phone: digits,
        role: _role,
        canUnlock: _canUnlock,
      );
    } on BackendFailure catch (failure) {
      Haptics.warn();
      if (mounted) {
        setState(() {
          _sending = false;
          _error = l10n.failure(failure);
        });
      }
      return;
    }
    Haptics.confirm();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.inviteSaved)));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = context.app.homes.activeHome;
    final isOwner = home?.isOwner ?? false;
    return FlowPage(
      top: const FlowTopBar(leading: CalmBackButton()),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.inviteSeenOnSignIn,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.sendInvite,
            loading: _sending,
            onPressed: _digits == null ? null : _send,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 8),
        FlowHeader(
          title: l10n.inviteTitle,
          subtitle: Text(l10n.inviteSubtitle(home?.name ?? '')),
        ),
        const SizedBox(height: 28),
        ThaiPhoneField(
          label: l10n.mobileNumber,
          controller: _phone,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: context.palette.danger, fontSize: 13.5),
            ),
          ),
        ],
        if (isOwner) ...[
          SectionHeader(l10n.yourRoleLabel),
          for (final role in [HomeRole.admin, HomeRole.member])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RoleOption(
                title: l10n.role(role.name),
                description: l10n.roleDescription(role.name),
                selected: _role == role,
                onTap: () => setState(() => _role = role),
              ),
            ),
          const SizedBox(height: 8),
          ListGroup(
            children: [
              ListRow(
                title: l10n.allowUnlock,
                subtitle: l10n.allowUnlockHint,
                onTap: () => setState(() => _canUnlock = !_canUnlock),
                trailing: CalmSwitch(
                  value: _canUnlock,
                  semanticLabel: l10n.allowUnlock,
                  onChanged: (value) => setState(() => _canUnlock = value),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onTap,
      selected: selected,
      pressedScale: .98,
      semanticLabel: '$title, $description',
      excludeChildSemantics: true,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.quick),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? palette.accentTint : palette.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? CupertinoIcons.largecircle_fill_circle
                  : CupertinoIcons.circle,
              color: selected ? palette.accent : palette.textFaint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13.5, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
