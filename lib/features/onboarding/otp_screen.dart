import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../backend/backend_failure.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/failure_message.dart';
import '../../core/widgets/flow_page.dart';
import '../account/account_store.dart';
import '../shell/app_root.dart';
import 'create_home_screen.dart';
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
  String? _error;
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
    final account = context.app.account;
    final sentAt = account.codeSentAt;
    if (sentAt == null) return Duration.zero;
    final left = account.resendAfter - DateTime.now().difference(sentAt);
    return left.isNegative ? Duration.zero : left;
  }

  void _onChanged(String value) {
    setState(() => _error = null);
    if (value.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_verifying || _code.text.length != 6) return;
    setState(() => _verifying = true);
    final app = context.app;
    final l10n = context.l10n;
    final OtpOutcome outcome;
    try {
      outcome = await app.account.verify(_code.text);
    } on BackendFailure catch (failure) {
      if (mounted) _reject(l10n.failure(failure));
      return;
    }
    if (outcome == OtpOutcome.invalidCode) {
      if (mounted) _reject(l10n.codeInvalid);
      return;
    }
    Haptics.confirm();
    await app.homes.load();
    if (!mounted) return;
    setState(() => _verifying = false);
    if (outcome == OtpOutcome.newAccount) {
      _open(const ProfileScreen());
    } else if (app.homes.hasHome || app.homes.loadFailed) {
      enterHome(context);
    } else {
      app.account.startOnboarding();
      _open(const CreateHomeScreen());
    }
  }

  void _reject(String message) {
    Haptics.warn();
    setState(() {
      _verifying = false;
      _error = message;
      _shakes++;
      _code.clear();
    });
    _focus.requestFocus();
  }

  void _open(Widget screen) =>
      Navigator.of(context)
          .push(CupertinoPageRoute<void>(builder: (_) => screen));

  Future<void> _resend() async {
    final account = context.app.account;
    final phone = account.phone;
    if (phone == null) return;
    await attempt(context, () => account.requestCode(phone));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final account = context.app.account;
    final phone = account.phone ?? '';
    final debugCode = account.debugCode;
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
          if (debugCode != null || account.isDemo) ...[
            const SizedBox(height: 12),
            Text(
              debugCode == null
                  ? l10n.otpDemoNote
                  : l10n.otpDebugNote(debugCode),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
            invalid: _error != null,
            onChanged: _onChanged,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.quick),
          child: _error != null
              ? Semantics(
                  key: const ValueKey('invalid'),
                  liveRegion: true,
                  child: Text(
                    _error!,
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

/// A short horizontal shake each time [shakes] increases. The child stays
/// mounted throughout, so the code field keeps its focus and keyboard.
class _Shake extends StatefulWidget {
  const _Shake({required this.shakes, required this.child});
  final int shakes;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(_Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakes > oldWidget.shakes && !Motion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = _controller.value;
      return Transform.translate(
        offset: Offset(math.sin(t * math.pi * 5) * 8 * (1 - t), 0),
        child: child,
      );
    },
  );
}
