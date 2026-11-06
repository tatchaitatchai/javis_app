import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/calm_palette.dart';
import '../../core/widgets/home_glow_mark.dart';
import '../../core/widgets/pressable.dart';
import '../lighting/lighting_service.dart';
import 'nearby_device_icon.dart';

/// The search for nearby devices, drawn as a soft sweep around the home mark
/// (spec 018). Found devices bloom onto the rings. Where a device lands is
/// decoration, not its direction or distance.
///
/// The screen's device list carries the semantics, so this stays decorative.
class NearbyRadar extends StatefulWidget {
  const NearbyRadar({
    required this.devices,
    required this.searching,
    required this.onChoose,
    super.key,
  });

  final List<NearbyDevice> devices;
  final bool searching;
  final ValueChanged<String> onChoose;

  @override
  State<NearbyRadar> createState() => _NearbyRadarState();
}

class _NearbyRadarState extends State<NearbyRadar>
    with SingleTickerProviderStateMixin {
  static const _maxDiameter = 300.0;
  static const _blipSize = 56.0;
  static const _centerSize = 76.0;

  /// More would crowd the rings; the list below always shows every device.
  static const _maxBlips = 6;
  static const _goldenAngle = 2.399963;
  static const _sweepPeriod = Duration(milliseconds: 4200);

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _sweepPeriod,
  );

  /// The sweep stands still with Reduce Motion or when the search cannot run.
  bool get _moving => widget.searching && !Motion.reduced(context);

  void _syncSweep() {
    if (_moving && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!_moving && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSweep();
  }

  @override
  void didUpdateWidget(NearbyRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.devices.length > oldWidget.devices.length) Haptics.confirm();
    _syncSweep();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Offset _blipCenter(int index, double diameter) {
    final outer = diameter / 2 - _blipSize / 2;
    final radius = index.isEven ? outer * .72 : outer;
    final angle = -math.pi / 3 + index * _goldenAngle;
    return Offset(math.cos(angle), math.sin(angle)) * radius +
        Offset(diameter / 2, diameter / 2);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(constraints.maxWidth, _maxDiameter);
      final blips = widget.devices.take(_maxBlips).toList(growable: false);
      return ExcludeSemantics(
        child: Center(
          child: SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size.square(diameter),
                    painter: _RingsPainter(context.palette),
                  ),
                ),
                RepaintBoundary(
                  child: AnimatedOpacity(
                    opacity: _moving ? 1 : 0,
                    duration: Motion.of(context, Motion.standard),
                    curve: Motion.curve,
                    child: CustomPaint(
                      size: Size.square(diameter),
                      painter: _SweepPainter(_sweep, context.palette),
                    ),
                  ),
                ),
                _RadarCenter(size: _centerSize, sweep: _sweep),
                for (var i = 0; i < blips.length; i++)
                  Positioned.fromRect(
                    key: ValueKey(blips[i].id),
                    rect: Rect.fromCenter(
                      center: _blipCenter(i, diameter),
                      width: _blipSize,
                      height: _blipSize,
                    ),
                    child: _Blip(
                      device: blips[i],
                      onTap: () => widget.onChoose(blips[i].id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _RadarCenter extends StatelessWidget {
  const _RadarCenter({required this.size, required this.sweep});

  final double size;
  final Animation<double> sweep;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.paper,
        shape: BoxShape.circle,
        border: Border.all(color: palette.hairline),
        boxShadow: [
          BoxShadow(
            color: palette.text.withValues(alpha: .08),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: sweep,
        builder: (_, _) => HomeGlowMark(
          size: size * .86,
          swell: (math.sin(sweep.value * 4 * math.pi) + 1) / 2,
        ),
      ),
    );
  }
}

class _Blip extends StatelessWidget {
  const _Blip({required this.device, required this.onTap});

  final NearbyDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.gentle),
      curve: Motion.emphasized,
      builder: (_, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: value, child: child),
      ),
      child: Pressable(
        key: ValueKey('radar-${device.id}'),
        onPressed: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: palette.paper,
            shape: BoxShape.circle,
            border: Border.all(color: palette.accentSoft, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: palette.text.withValues(alpha: .1),
                offset: const Offset(0, 5),
                blurRadius: 14,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: NearbyDeviceIcon(device: device, size: 28),
        ),
      ),
    );
  }
}

/// The still part of the radar, kept apart so it never repaints with the sweep.
class _RingsPainter extends CustomPainter {
  const _RingsPainter(this.palette);

  final CalmPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.accentTint, palette.accentTint.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = palette.line;
    for (final fraction in const [.42, .68, .96]) {
      canvas.drawCircle(center, radius * fraction, ring);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// The moving part: a trailing sweep and two echoes spreading from the home.
class _SweepPainter extends CustomPainter {
  _SweepPainter(this.sweep, this.palette) : super(repaint: sweep);

  final Animation<double> sweep;
  final CalmPalette palette;

  static const _trail = .24;
  static const _edgeAlpha = .34;
  static const _echoAlpha = .3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * .96;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final angle = sweep.value * 2 * math.pi;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            palette.accent.withValues(alpha: 0),
            palette.accent.withValues(alpha: 0),
            palette.accent.withValues(alpha: _edgeAlpha),
          ],
          stops: const [0, 1 - _trail, 1],
          transform: GradientRotation(angle),
        ).createShader(rect),
    );

    for (final phase in const [0.0, .5]) {
      final progress = (sweep.value + phase) % 1;
      final eased = Curves.easeOutCubic.transform(progress);
      canvas.drawCircle(
        center,
        radius * (.2 + .8 * eased),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.accent.withValues(
            alpha: _echoAlpha * (1 - progress),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.sweep != sweep;
}
