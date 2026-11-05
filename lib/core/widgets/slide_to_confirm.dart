import 'package:flutter/cupertino.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// Drag the knob to the end to confirm a sensitive action. Releasing early
/// springs back. Assistive technologies get a single activate action.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    required this.label,
    required this.icon,
    required this.onConfirmed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onConfirmed;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  static const _height = 72.0;
  static const _knob = 60.0;
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  double _travel = 1;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails details) {
    if (_done) return;
    _controller.value += details.primaryDelta! / _travel;
  }

  void _release(DragEndDetails details) {
    if (_done) return;
    if (_controller.value > .85) {
      _confirm();
    } else {
      _controller.animateBack(0, curve: Motion.curve);
    }
  }

  void _confirm() {
    if (_done || widget.onConfirmed == null) return;
    _done = true;
    Haptics.confirm();
    _controller.animateTo(1, curve: Motion.curve);
    widget.onConfirmed!();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = widget.onConfirmed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? _confirm : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _travel = constraints.maxWidth - _knob - 12;
          return Container(
            height: _height,
            decoration: BoxDecoration(
              color: palette.raised,
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: (1 - _controller.value * 1.6).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: _knob + 12,
                          right: 20,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: palette.accentDeep,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right_2,
                              size: 18,
                              color: palette.accentSoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6 + _controller.value * _travel,
                    child: GestureDetector(
                      onHorizontalDragUpdate: enabled ? _drag : null,
                      onHorizontalDragEnd: enabled ? _release : null,
                      child: Container(
                        width: _knob,
                        height: _knob,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.strong,
                        ),
                        child: Icon(widget.icon, color: palette.gold, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
