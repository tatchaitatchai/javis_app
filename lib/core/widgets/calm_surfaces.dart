import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'dashed_border.dart';
import 'pressable.dart';

/// Page title with the optional muted line beneath it.
class FlowHeader extends StatelessWidget {
  const FlowHeader({required this.title, this.subtitle, super.key});
  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: context.palette.textMuted,
          ),
          child: subtitle!,
        ),
      ],
    ],
  );
}

/// Section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.action,
    this.padding = const EdgeInsets.only(top: 24, bottom: 10),
    super.key,
  });
  final String title;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// Paper card. When [onTap] is set it presses like every other control.
class CalmPanel extends StatelessWidget {
  const CalmPanel({
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final panel = AnimatedContainer(
      duration: Motion.of(context, Motion.standard),
      curve: Motion.curve,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.palette.paper,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return Pressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      pressedScale: .98,
      child: panel,
    );
  }
}

enum NoteTone { neutral, warm }

/// Icon + explanatory text block (“Before you start”, 2.4 GHz warning…).
class InfoNote extends StatelessWidget {
  const InfoNote({
    required this.text,
    this.title,
    this.icon = CupertinoIcons.info_circle,
    this.tone = NoteTone.neutral,
    super.key,
  });

  final String text;
  final String? title;
  final IconData icon;
  final NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final warm = tone == NoteTone.warm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: warm ? palette.noteBg : palette.raised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 20,
              color: warm ? palette.warnText : palette.accentDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: warm ? palette.noteText : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grouped rows on one paper card with hairline separators.
class ListGroup extends StatelessWidget {
  const ListGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: context.palette.paper,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, color: context.palette.hairline),
          children[i],
        ],
      ],
    ),
  );
}

/// One row: optional leading, title/subtitle, trailing value or chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.value,
    this.onTap,
    this.chevron = false,
    this.titleColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? value;
  final VoidCallback? onTap;
  final bool chevron;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15.5, color: titleColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: palette.textMuted),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              // Align fills the flex slot so the value hugs the trailing edge.
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 14.5, color: palette.textMuted),
                  ),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (chevron) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Pressable(onPressed: onTap, pressedScale: .985, child: row);
  }
}

/// Initial-letter avatar for members.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(
    this.name, {
    this.size = 36,
    this.strong = false,
    super.key,
  });
  final String name;
  final double size;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: strong ? palette.accent : palette.glow,
          borderRadius: BorderRadius.circular(size * .32),
        ),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * .42,
            fontWeight: FontWeight.w700,
            color: strong ? palette.onStrong : palette.text,
          ),
        ),
      ),
    );
  }
}

/// Small warm pill such as “Offline” or “Preview”.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {this.subtle = false, super.key});
  final String label;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: subtle ? palette.accentTint : palette.warnBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: subtle ? palette.accentDeep : palette.warnText,
        ),
      ),
    );
  }
}

/// Large selectable tile with a check (zone picker grid).
class SelectTile extends StatelessWidget {
  const SelectTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final duration = Motion.of(context, Motion.quick);
    return Pressable(
      onPressed: onTap,
      selected: selected,
      child: AnimatedContainer(
        duration: duration,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: selected
                  ? Icon(
                      CupertinoIcons.checkmark_alt_circle_fill,
                      key: const ValueKey(true),
                      size: 24,
                      color: palette.accent,
                    )
                  : Container(
                      key: const ValueKey(false),
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.textFaint,
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded choice chip (zone on the success screen, name presets, filters).
class SelectPill extends StatelessWidget {
  const SelectPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.filled = false,
    this.dashed = false,
    this.height = 44,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Filter style: ink fill when selected instead of sage tint.
  final bool filled;
  final bool dashed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color background;
    final Color foreground;
    final Color border;
    if (dashed) {
      background = Colors.transparent;
      foreground = palette.accentDeep;
      border = Colors.transparent;
    } else if (filled) {
      background = selected ? palette.strong : Colors.transparent;
      foreground = selected ? palette.onStrong : palette.text;
      border = selected ? palette.strong : palette.line;
    } else {
      background = selected ? palette.accentTint : palette.paper;
      foreground = palette.text;
      border = selected ? palette.accent : palette.line;
    }
    Widget pill = AnimatedContainer(
      duration: Motion.of(context, Motion.quick),
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: border, width: selected && !filled ? 2 : 1.2),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: foreground,
            fontWeight: selected || dashed ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
    if (dashed) {
      pill = CustomPaint(
        painter: DashedBorderPainter(
          color: palette.accentSoft,
          radius: height / 2,
        ),
        child: pill,
      );
    }
    return Pressable(
      onPressed: onTap,
      selected: dashed ? null : selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(widthFactor: 1, child: pill),
      ),
    );
  }
}
