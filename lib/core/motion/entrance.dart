import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Fades and lifts a child in once when it first appears. [order] staggers
/// siblings; Reduce Motion shows the child immediately.
class Entrance extends StatelessWidget {
  const Entrance({required this.child, this.order = 0, super.key});

  final Widget child;
  final int order;

  static const _step = Duration(milliseconds: 55);

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    final delay = _step * order;
    final total = delay + Motion.gentle;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Motion.curve),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
