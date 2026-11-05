import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// Short segmented progress used by onboarding and device setup.
class StepBar extends StatelessWidget {
  const StepBar({
    required this.current,
    this.total = 3,
    this.showLabel = false,
    super.key,
  });

  final int current;
  final int total;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: context.l10n.stepOf(current, total),
      excludeSemantics: true,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var step = 1; step <= total; step++) ...[
              AnimatedContainer(
                duration: Motion.of(context, Motion.gentle),
                curve: Motion.curve,
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                  color: step <= current ? palette.accent : palette.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (step < total) const SizedBox(width: 6),
            ],
            if (showLabel) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  context.l10n.stepOf(current, total),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
