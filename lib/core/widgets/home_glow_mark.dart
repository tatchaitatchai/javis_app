import 'package:flutter/material.dart';

import '../theme/calm_palette.dart';

/// The JAVIS Home brand mark (spec 014): an open-bottom house outline around a
/// warm light. [swell] (0-1) grows and brightens the light's halos.
class HomeGlowMark extends StatelessWidget {
  const HomeGlowMark({this.size = 200, this.swell = 0, super.key});

  final double size;
  final double swell;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _HomeGlowPainter(
            swell: swell,
            outline: palette.text,
            light: Theme.of(context).brightness == Brightness.dark
                ? palette.gold
                : palette.goldDeep,
          ),
        ),
      ),
    );
  }
}

/// Draws the Home glow mark from `Design/brand`: an open-bottom house outline
/// around a warm light whose halos grow and brighten as [swell] rises to 1.
class _HomeGlowPainter extends CustomPainter {
  const _HomeGlowPainter({
    required this.swell,
    required this.outline,
    required this.light,
  });
  final double swell;
  final Color outline;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    // The SVG master uses a 1024-unit grid; at 0.3 pt per unit on a 200 pt
    // box this matches the native LaunchMark image, centred on the house.
    // The splash uses a lighter 44-unit stroke than the 60-unit app icon.
    final scale = size.shortestSide / 200 * .3;
    final center = size.center(Offset.zero);
    Offset at(double x, double y) => center + Offset(x - 512, y - 515) * scale;

    final glow = at(512, 566);
    canvas.drawCircle(
      glow,
      138 * (1 + .35 * swell) * scale,
      Paint()..color = light.withValues(alpha: .08 + .06 * swell),
    );
    canvas.drawCircle(
      glow,
      98 * (1 + .18 * swell) * scale,
      Paint()..color = light.withValues(alpha: .2 + .1 * swell),
    );
    canvas.drawCircle(glow, 56 * scale, Paint()..color = light);

    final house = Path()
      ..addPolygon([
        at(316, 732),
        at(316, 472),
        at(512, 298),
        at(708, 472),
        at(708, 732),
      ], false);
    canvas.drawPath(
      house,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 44 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HomeGlowPainter oldDelegate) =>
      swell != oldDelegate.swell ||
      outline != oldDelegate.outline ||
      light != oldDelegate.light;
}
