import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';

/// Large sage circle with a bulb; a slow arc turns while [busy].
class PairingOrb extends StatelessWidget {
  const PairingOrb({
    required this.icon,
    this.busy = false,
    this.done = false,
    super.key,
  });

  final IconData icon;
  final bool busy;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = done ? 88.0 : 160.0;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.gentle),
        curve: Motion.emphasized,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? palette.accent : palette.accentTint,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (busy)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: palette.goldDeep,
                    backgroundColor: palette.line.withValues(alpha: .5),
                    value: Motion.reduced(context) ? .3 : null,
                  ),
                ),
              ),
            Icon(
              icon,
              size: done ? 42 : 56,
              color: done ? palette.onStrong : palette.accentDeep,
            ),
          ],
        ),
      ),
    );
  }
}

enum ChecklistState { done, active, waiting }

/// Checklist used while connecting (design 17).
class PairingChecklist extends StatelessWidget {
  const PairingChecklist({required this.steps, super.key});
  final List<(String, ChecklistState)> steps;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.standard),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: switch (steps[i].$2) {
                      ChecklistState.done => Icon(
                        CupertinoIcons.checkmark_alt_circle_fill,
                        key: const ValueKey('done'),
                        color: palette.accent,
                      ),
                      ChecklistState.active => Padding(
                        key: const ValueKey('active'),
                        padding: const EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: palette.goldDeep,
                          value: Motion.reduced(context) ? .7 : null,
                        ),
                      ),
                      ChecklistState.waiting => Container(
                        key: const ValueKey('waiting'),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.line, width: 2),
                        ),
                      ),
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    steps[i].$1,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: steps[i].$2 == ChecklistState.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: steps[i].$2 == ChecklistState.waiting
                          ? palette.textFaint
                          : palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Numbered instruction list (design 16).
class NumberedSteps extends StatelessWidget {
  const NumberedSteps({required this.steps, super.key});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.strong,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.onStrong,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A selectable connection-method card (home Wi-Fi vs bulb Wi-Fi).
class ModeOption extends StatelessWidget {
  const ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      onPressed: onTap,
      selected: selected,
      pressedScale: .98,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.quick),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? palette.accentTint : palette.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.accent : palette.line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.checkmark_alt_circle_fill
                  : CupertinoIcons.circle,
              color: selected ? palette.accent : palette.textFaint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
