import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_segment.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_switch.dart';
import '../../core/widgets/failure_message.dart';
import '../home/home_switcher_sheet.dart';
import '../home/zone_name_sheet.dart';
import 'account_store.dart';

/// 24 · Profile, homes, preferences and sign-out.
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  // Preview only: no notifications are sent (spec 012).
  bool _doorAlerts = true;

  Future<void> _editName() async {
    final l10n = context.l10n;
    final name = await showZoneNameSheet(
      context,
      title: l10n.editName,
      label: l10n.nickname,
      initial: context.app.account.name,
    );
    if (name == null || !mounted) return;
    final account = context.app.account;
    await attempt(context, () => account.setName(name));
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.signOutQuestion),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Haptics.warn();
    await context.app.account.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([app.account, app.homes]),
      builder: (context, _) {
        final account = app.account;
        final invites = app.homes.invites.length;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.meTab,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProfileCard(
                    name: account.name,
                    phone: account.phone == null
                        ? ''
                        : internationalThaiMobile(account.phone!),
                    onEdit: _editName,
                  ),
                  SectionHeader(l10n.homesSection),
                  ListGroup(
                    children: [
                      ListRow(
                        title: l10n.myHomes,
                        value: l10n.homeCount(app.homes.homes.length),
                        chevron: true,
                        onTap: () => showHomeSwitcher(context),
                      ),
                      ListRow(
                        title: l10n.homeInvites,
                        trailing: invites > 0 ? StatusBadge('$invites') : null,
                        value: invites == 0 ? l10n.none : null,
                        chevron: invites > 0,
                        onTap: invites > 0
                            ? () => showHomeSwitcher(context)
                            : null,
                      ),
                    ],
                  ),
                  SectionHeader(l10n.usageSection),
                  ListGroup(
                    children: [
                      ListRow(
                        title: l10n.language,
                        trailing: SizedBox(
                          width: 128,
                          child: CalmSegment<String>(
                            options: const [('th', 'ไทย'), ('en', 'EN')],
                            selected: l10n.isThai ? 'th' : 'en',
                            onChanged: (code) =>
                                AppLanguage.of(context).setLocale(Locale(code)),
                          ),
                        ),
                      ),
                      ListRow(title: l10n.theme, value: l10n.followSystem),
                      ListRow(
                        title: l10n.doorAlerts,
                        subtitle: l10n.doorAlertsPreview,
                        onTap: () => setState(() => _doorAlerts = !_doorAlerts),
                        trailing: CalmSwitch(
                          value: _doorAlerts,
                          semanticLabel: l10n.doorAlerts,
                          onChanged: (value) =>
                              setState(() => _doorAlerts = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SecondaryButton(
                    label: l10n.signOut,
                    destructive: true,
                    onPressed: _signOut,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.appVersion,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return CalmPanel(
      child: Row(
        children: [
          InitialAvatar(name, size: 56, strong: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(fontSize: 14, color: palette.textMuted),
                ),
              ],
            ),
          ),
          QuietButton(label: context.l10n.edit, onPressed: onEdit),
        ],
      ),
    );
  }
}
