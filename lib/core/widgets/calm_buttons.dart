import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'dashed_border.dart';
import 'pressable.dart';

/// Ink call to action, full width by default (design: 56pt, radius 16).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null && !loading;
    return Pressable(
      onPressed: enabled ? onPressed : null,
      pressedScale: .98,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.quick),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: palette.strong,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: _ButtonLabel(
          label: label,
          icon: icon,
          loading: loading,
          color: palette.onStrong,
        ),
      ),
    );
  }
}

/// Outlined secondary action (design: 52pt, 1.5pt line border).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.destructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = destructive ? palette.danger : palette.text;
    return Pressable(
      onPressed: loading ? null : onPressed,
      pressedScale: .98,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive
                ? palette.danger.withValues(alpha: .35)
                : palette.line,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: _ButtonLabel(
          label: label,
          icon: icon,
          loading: loading,
          color: color,
          size: 16,
        ),
      ),
    );
  }
}

/// Borderless text action such as “Resend” or “Decline”.
class QuietButton extends StatelessWidget {
  const QuietButton({
    required this.label,
    required this.onPressed,
    this.accent = true,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Center(
            widthFactor: 1,
            child: _ButtonLabel(
              label: label,
              icon: icon,
              color: accent ? palette.accentDeep : palette.textMuted,
              size: 15.5,
              weight: accent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed “add” affordance used for new zones, homes and devices.
class DashedButton extends StatelessWidget {
  const DashedButton({
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.add,
    this.height = 56,
    this.radius = 16,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      child: CustomPaint(
        painter: DashedBorderPainter(color: palette.accentSoft, radius: radius),
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: _ButtonLabel(
            label: label,
            icon: icon,
            color: palette.accentDeep,
            size: 16,
          ),
        ),
      ),
    );
  }
}

/// Round 44pt icon button inside a 48pt touch target.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.plain = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      tooltip: tooltip,
      semanticLabel: tooltip,
      excludeChildSemantics: true,
      pressedScale: .9,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: plain
                  ? Colors.transparent
                  : filled
                  ? palette.strong
                  : palette.raised,
            ),
            child: Icon(
              icon,
              size: 22,
              color: filled ? palette.onStrong : palette.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style back chevron that pops the current route.
class CalmBackButton extends StatelessWidget {
  const CalmBackButton({this.onPressed, this.close = false, super.key});
  final VoidCallback? onPressed;
  final bool close;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(-12, 0),
    child: CircleIconButton(
      icon: close ? CupertinoIcons.xmark : CupertinoIcons.chevron_back,
      tooltip: close ? context.l10n.close : context.l10n.back,
      plain: true,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    ),
  );
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.label,
    required this.color,
    this.icon,
    this.loading = false,
    this.size = 17,
    this.weight = FontWeight.w600,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool loading;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final leading = loading
        ? SizedBox.square(
            key: const ValueKey('loading'),
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : icon == null
        ? null
        : Icon(icon, key: ValueKey(icon), size: 20, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.quick),
          child: leading == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(loading),
                  padding: const EdgeInsets.only(right: 10),
                  child: leading,
                ),
        ),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: weight,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
