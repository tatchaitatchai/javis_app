import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/flow_page.dart';
import '../account/account_store.dart';
import '../shell/app_root.dart';
import 'profile_screen.dart';

/// 03 · Six-digit code. Verifies as soon as the sixth digit is typed.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  bool _verifying = false;
  bool _invalid = false;
  int _shakes = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Duration get _resendIn {
    final sentAt = context.app.account.codeSentAt;
    if (sentAt == null) return Duration.zero;
    final left = AccountStore.resendAfter - DateTime.now().difference(sentAt);
    return left.isNegative ? Duration.zero : left;
  }

  void _onChanged(String value) {
    setState(() => _invalid = false);
    if (value.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_verifying || _code.text.length != 6) return;
    setState(() => _verifying = true);
    final app = context.app;
    final outcome = await app.account.verify(_code.text);
    if (!mounted) return;
    switch (outcome) {
      case OtpOutcome.invalidCode:
        Haptics.warn();
        setState(() {
          _verifying = false;
          _invalid = true;
          _shakes++;
          _code.clear();
        });
        _focus.requestFocus();
      case OtpOutcome.existingAccount:
        Haptics.confirm();
        app.homes.loadDemoAccount(
          yourName: app.account.name,
          yourPhone: app.account.phone!,
        );
        enterHome(context);
      case OtpOutcome.newAccount:
        Haptics.confirm();
        app.homes.startNewAccount();
        setState(() => _verifying = false);
        await Navigator.of(
          context,
        ).push(CupertinoPageRoute<void>(builder: (_) => const ProfileScreen()));
    }
  }

  Future<void> _resend() async {
    final phone = context.app.account.phone;
    if (phone == null) return;
    await context.app.account.requestCode(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final phone = context.app.account.phone ?? '';
    final resendIn = _resendIn;
    return FlowPage(
      top: const Align(
        alignment: Alignment.centerLeft,
        child: CalmBackButton(),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: l10n.confirm,
            loading: _verifying,
            onPressed: _code.text.length == 6 ? _verify : null,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.otpDemoNote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 20),
        FlowHeader(
          title: l10n.enterCodeTitle,
          subtitle: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.codeSentTo),
              Text(
                formatThaiMobile(phone),
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              QuietButton(
                label: l10n.changeNumber,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _Shake(
          shakes: _shakes,
          child: _CodeBoxes(
            controller: _code,
            focusNode: _focus,
            invalid: _invalid,
            onChanged: _onChanged,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.quick),
          child: _invalid
              ? Semantics(
                  key: const ValueKey('invalid'),
                  liveRegion: true,
                  child: Text(
                    l10n.codeInvalid,
                    style: TextStyle(color: palette.danger, fontSize: 14),
                  ),
                )
              : resendIn > Duration.zero
              ? Text(
                  l10n.resendIn(
                    '${resendIn.inMinutes}:'
                    '${(resendIn.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  key: const ValueKey('countdown'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : Align(
                  key: const ValueKey('resend'),
                  alignment: Alignment.centerLeft,
                  child: QuietButton(
                    label: l10n.resendCode,
                    onPressed: _resend,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Six visual boxes backed by one field so paste and SMS autofill work.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.invalid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool invalid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: context.l10n.sixDigitCode,
      textField: true,
      child: GestureDetector(
        onTap: focusNode.requestFocus,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: const ValueKey('otp-field'),
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  onChanged: onChanged,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([controller, focusNode]),
              builder: (context, _) {
                final text = controller.text;
                return Row(
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _Box(
                          digit: i < text.length ? text[i] : '',
                          active:
                              focusNode.hasFocus &&
                              i == math.min(text.length, 5),
                          invalid: invalid,
                          palette: palette,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.digit,
    required this.active,
    required this.invalid,
    required this.palette,
  });

  final String digit;
  final bool active;
  final bool invalid;
  final CalmPalette palette;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Motion.of(context, Motion.quick),
    height: 60,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: palette.paper,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: invalid
            ? palette.danger
            : active
            ? palette.accent
            : palette.line,
        width: active || invalid ? 2 : 1.5,
      ),
    ),
    child: AnimatedSwitcher(
      duration: Motion.of(context, Motion.quick),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Text(
        digit,
        key: ValueKey(digit),
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// A short horizontal shake each time [shakes] increases.
class _Shake extends StatelessWidget {
  const _Shake({required this.shakes, required this.child});
  final int shakes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakes == 0 || Motion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shakes),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      child: child,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 5) * 8 * (1 - t), 0),
        child: child,
      ),
    );
  }
}
