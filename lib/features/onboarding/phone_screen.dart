import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/failure_message.dart';
import '../../core/widgets/flow_page.dart';
import '../account/account_store.dart';
import '../account/phone_field.dart';
import 'otp_screen.dart';

/// 02 · Mobile number. One number for both sign-up and sign-in.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phone = TextEditingController();
  bool _sending = false;

  String? get _digits => normalizeThaiMobile(_phone.text);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _digits;
    if (digits == null || _sending) return;
    setState(() => _sending = true);
    final sent = await attempt(
      context,
      () => context.app.account.requestCode(digits),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (!sent) return;
    await Navigator.of(context)
        .push(CupertinoPageRoute<void>(builder: (_) => const OtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FlowPage(
      top: const Align(
        alignment: Alignment.centerLeft,
        child: CalmBackButton(),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: l10n.sendCode,
            loading: _sending,
            onPressed: _digits == null ? null : _send,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noPasswordNeeded,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 20),
        FlowHeader(
          title: l10n.yourMobileTitle,
          subtitle: Text(l10n.yourMobileSubtitle),
        ),
        const SizedBox(height: 36),
        ThaiPhoneField(
          label: l10n.mobileNumber,
          controller: _phone,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _send(),
        ),
      ],
    );
  }
}
