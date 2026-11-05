import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Paints the dashed outline used by “add” affordances.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.radius = 16,
    this.strokeWidth = 1.5,
    this.dash = 6,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final PathMetric metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      strokeWidth != oldDelegate.strokeWidth;
}
