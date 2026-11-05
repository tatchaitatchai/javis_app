import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_text_field.dart';
import '../../core/widgets/failure_message.dart';
import '../../core/widgets/flow_page.dart';
import '../../core/widgets/step_bar.dart';
import 'create_home_screen.dart';

/// 04 · Nickname (step 1 of 3).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _name = TextEditingController(text: context.app.account.name);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final account = context.app.account;
    final saved = await attempt(context, () => account.setName(_name.text));
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) return;
    await Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => const CreateHomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FlowPage(
      top: const Align(
        alignment: Alignment.centerLeft,
        child: StepBar(current: 1, showLabel: true),
      ),
      footer: PrimaryButton(
        label: l10n.next,
        loading: _saving,
        onPressed: _name.text.trim().isEmpty ? null : _next,
      ),
      children: [
        const SizedBox(height: 20),
        FlowHeader(
          title: l10n.profileTitle,
          subtitle: Text(l10n.profileSubtitle),
        ),
        const SizedBox(height: 36),
        CalmTextField(
          label: l10n.nickname,
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.nickname],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }
}
