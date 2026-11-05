import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Segmented control with a sliding thumb.
class CalmSegment<T> extends StatelessWidget {
  const CalmSegment({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final index = options.indexWhere((option) => option.$1 == selected);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: Motion.of(context, Motion.standard),
              curve: Motion.curve,
              alignment: Alignment(
                options.length == 1 ? 0 : -1 + 2 * index / (options.length - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / options.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.paper,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final option in options)
                Expanded(
                  child: Pressable(
                    // The selected option stays enabled so it does not dim.
                    onPressed: onChanged == null
                        ? null
                        : () {
                            if (option.$1 != selected) onChanged!(option.$1);
                          },
                    selected: option.$1 == selected,
                    pressedScale: .97,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          // Large text shrinks to fit rather than break a word.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              option.$2,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: option.$1 == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: option.$1 == selected
                                    ? palette.text
                                    : palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
