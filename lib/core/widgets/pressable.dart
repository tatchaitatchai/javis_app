import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// The single tap primitive: it shrinks on finger-down (not after the tap
/// timeout), gives a selection haptic, and exposes button semantics.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.selected,
    this.toggled,
    this.pressedScale = .96,
    this.haptic = true,
    this.excludeChildSemantics = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool? selected;
  final bool? toggled;
  final double pressedScale;
  final bool haptic;
  final bool excludeChildSemantics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool value) {
    if (_down == value || !mounted) return;
    setState(() => _down = value);
  }

  void _handleTap() {
    if (widget.haptic) Haptics.tap();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Listener(
      onPointerDown: _enabled ? (_) => _setDown(true) : null,
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? _handleTap : null,
        onTapCancel: () => _setDown(false),
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1,
          duration: Motion.of(context, Motion.press),
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : .45,
            duration: Motion.of(context, Motion.quick),
            child: widget.child,
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      result = Tooltip(
        message: widget.tooltip,
        excludeFromSemantics: widget.semanticLabel != null,
        child: result,
      );
    }
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: widget.excludeChildSemantics && _enabled ? _handleTap : null,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: result,
      ),
    );
  }
}
