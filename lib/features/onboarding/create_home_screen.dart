import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_text_field.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/step_bar.dart';
import 'invite_accept_screen.dart';
import 'zones_setup_screen.dart';

/// 05 · Name the home (step 2 of 3). Also used to add another home later.
class CreateHomeScreen extends StatefulWidget {
  const CreateHomeScreen({this.addingAnother = false, super.key});
  final bool addingAnother;

  @override
  State<CreateHomeScreen> createState() => _CreateHomeScreenState();
}

class _CreateHomeScreenState extends State<CreateHomeScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _usePreset(String name) {
    _name.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    setState(() {});
  }

  void _next() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ZonesSetupScreen(
          homeName: name,
          addingAnother: widget.addingAnother,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final homes = context.app.homes;
    return FlowPage(
      top: widget.addingAnother
          ? const Align(
              alignment: Alignment.centerLeft,
              child: CalmBackButton(),
            )
          : const Align(
              alignment: Alignment.centerLeft,
              child: StepBar(current: 2, showLabel: true),
            ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: homes,
            builder: (context, _) {
              final invite = homes.invites.firstOrNull;
              if (invite == null || widget.addingAnother) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CalmPanel(
                  color: context.palette.raised,
                  radius: 16,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => InviteAcceptScreen(inviteId: invite.id),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.palette.paper,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.envelope,
                          size: 22,
                          color: context.palette.accentDeep,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.alreadyInvited,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              l10n.invitesWaiting(homes.invites.length),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_forward, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
          PrimaryButton(
            label: l10n.createHome,
            onPressed: _name.text.trim().isEmpty ? null : _next,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 20),
        FlowHeader(
          title: widget.addingAnother ? l10n.addHomeTitle : l10n.firstHomeTitle,
          subtitle: Text(l10n.firstHomeSubtitle),
        ),
        const SizedBox(height: 32),
        CalmTextField(
          label: l10n.homeName,
          controller: _name,
          hint: l10n.homeNameHint,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final preset in l10n.homeNamePresets)
              SelectPill(
                label: preset,
                height: 40,
                selected: _name.text.trim() == preset,
                onTap: () => _usePreset(preset),
              ),
          ],
        ),
      ],
    );
  }
}
