import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';

/// Tall brightness pill (design 11). Drag or tap anywhere to set; VoiceOver
/// users swipe up/down in 10% steps.
class BrightnessPill extends StatelessWidget {
  const BrightnessPill({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  static const _height = 300.0;

  double _valueAt(double dy) => (1 - dy / _height).clamp(.01, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final percent = (value * 100).round();
    void step(double delta) => onChangeEnd((value + delta).clamp(.01, 1.0));
    return Semantics(
      slider: true,
      label: l10n.brightness,
      value: l10n.percent(percent),
      increasedValue: l10n.percent(
        ((value + .1).clamp(.01, 1.0) * 100).round(),
      ),
      decreasedValue: l10n.percent(
        ((value - .1).clamp(.01, 1.0) * 100).round(),
      ),
      onIncrease: enabled ? () => step(.1) : null,
      onDecrease: enabled ? () => step(-.1) : null,
      excludeSemantics: true,
      child: GestureDetector(
        onVerticalDragStart: enabled
            ? (details) => onChanged(_valueAt(details.localPosition.dy))
            : null,
        onVerticalDragUpdate: enabled
            ? (details) => onChanged(_valueAt(details.localPosition.dy))
            : null,
        onVerticalDragEnd: enabled ? (_) => onChangeEnd(value) : null,
        onTapUp: enabled
            ? (details) {
                Haptics.tap();
                onChangeEnd(_valueAt(details.localPosition.dy));
              }
            : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : .55,
          duration: Motion.of(context, Motion.quick),
          child: Container(
            width: 132,
            height: _height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.raised,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: Motion.of(
                      context,
                      const Duration(milliseconds: 90),
                    ),
                    height: _height * value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.gold.withValues(alpha: .85),
                          palette.goldDeep,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 26,
                  child: Column(
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        l10n.brightness,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.text.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round state display for lights without brightness control.
class LightStateOrb extends StatelessWidget {
  const LightStateOrb({required this.lit, required this.label, super.key});
  final bool lit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.standard),
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? palette.glow : palette.raised,
        border: Border.all(color: palette.accentTint, width: 12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            lit ? CupertinoIcons.lightbulb_fill : CupertinoIcons.lightbulb,
            size: 44,
            color: lit ? palette.goldDeep : palette.textMuted,
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

/// 72pt round power button: ink with a gold glyph when on.
class PowerButton extends StatelessWidget {
  const PowerButton({
    required this.on,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final bool on;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onPressed,
      tooltip: tooltip,
      semanticLabel: tooltip,
      toggled: on,
      excludeChildSemantics: true,
      pressedScale: .9,
      haptic: false,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.standard),
        curve: Motion.curve,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? palette.strong : palette.paper,
          border: Border.all(
            color: on ? palette.strong : palette.line,
            width: 1.5,
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: palette.gold.withValues(alpha: .35),
                    blurRadius: 18,
                  ),
                ]
              : const [],
        ),
        child: Icon(
          CupertinoIcons.power,
          size: 30,
          color: on ? palette.gold : palette.text,
        ),
      ),
    );
  }
}

/// Warm-to-cool gradient slider for white temperature.
class ToneSlider extends StatelessWidget {
  const ToneSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final double value;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  static const _thumb = 30.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);
    double kelvinAt(double dx, double width) {
      final t = ((dx - _thumb / 2) / (width - _thumb)).clamp(0.0, 1.0);
      return (min + t * (max - min)).roundToDouble();
    }

    double stepped(double delta) =>
        (value + delta * (max - min)).clamp(min, max).roundToDouble();
    void step(double delta) => onChangeEnd(stepped(delta));
    return Semantics(
      slider: true,
      label: l10n.temperature,
      value: l10n.kelvin(value.round()),
      increasedValue: l10n.kelvin(stepped(.1).round()),
      decreasedValue: l10n.kelvin(stepped(-.1).round()),
      onIncrease: enabled ? () => step(.1) : null,
      onDecrease: enabled ? () => step(-.1) : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragStart: enabled
                ? (d) => onChanged(kelvinAt(d.localPosition.dx, width))
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) => onChanged(kelvinAt(d.localPosition.dx, width))
                : null,
            onHorizontalDragEnd: enabled ? (_) => onChangeEnd(value) : null,
            onTapUp: enabled
                ? (d) {
                    Haptics.tap();
                    onChangeEnd(kelvinAt(d.localPosition.dx, width));
                  }
                : null,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : .55,
              duration: Motion.of(context, Motion.quick),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF2C57C),
                            Color(0xFFFFF4E0),
                            Color(0xFFD9E6F5),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: Motion.of(
                        context,
                        const Duration(milliseconds: 90),
                      ),
                      left: 3 + fraction * (width - _thumb - 6),
                      child: Container(
                        width: _thumb,
                        height: _thumb,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.paper,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .28),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Colour choices for colour mode.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({
    required this.selected,
    required this.enabled,
    required this.onSelected,
    super.key,
  });

  final Color? selected;
  final bool enabled;
  final ValueChanged<Color> onSelected;

  static const swatches = [
    (Color(0xFFD7B8CD), 'Rose'),
    (Color(0xFFBDB3DB), 'Lavender'),
    (Color(0xFFA6C4D6), 'Sky'),
    (Color(0xFFB9D1AB), 'Sage'),
    (Color(0xFFE6C38D), 'Amber'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final swatch in swatches)
        Pressable(
          onPressed: enabled ? () => onSelected(swatch.$1) : null,
          tooltip: context.l10n.swatch(swatch.$2),
          semanticLabel: context.l10n.swatch(swatch.$2),
          selected: selected == swatch.$1,
          excludeChildSemantics: true,
          pressedScale: .9,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.quick),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: swatch.$1,
              border: Border.all(
                color: selected == swatch.$1
                    ? context.palette.text
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: selected == swatch.$1
                ? const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 22,
                    color: CalmPalette.onGold,
                  )
                : null,
          ),
        ),
    ],
  );
}
