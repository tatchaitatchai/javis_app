import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// The design's pill switch. The knob slides as soon as [value] changes, so a
/// caller that flips [value] optimistically gets same-frame feedback.
class CalmSwitch extends StatelessWidget {
  const CalmSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.compact = false,
    this.busy = false,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;
  final bool compact;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = compact ? 40.0 : 48.0;
    final height = compact ? 24.0 : 28.0;
    final knob = height - 6;
    final duration = Motion.of(context, Motion.standard);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      onTap: onChanged == null ? null : () => _toggle(),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : _toggle,
        child: SizedBox(
          width: width + 8,
          height: 48,
          child: Center(
            child: AnimatedOpacity(
              opacity: onChanged == null && !busy ? .45 : 1,
              duration: Motion.of(context, Motion.quick),
              child: AnimatedContainer(
                duration: duration,
                curve: Motion.curve,
                width: width,
                height: height,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: value ? palette.accent : palette.line,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: AnimatedAlign(
                  duration: duration,
                  curve: Motion.curve,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.paper,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .12),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: busy
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: palette.accent,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle() {
    Haptics.toggle();
    onChanged?.call(!value);
  }
}
