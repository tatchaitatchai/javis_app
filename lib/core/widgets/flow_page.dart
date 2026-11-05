import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Layout for one step of a flow: a top bar, scrollable content and actions
/// that sit at the bottom on short content but scroll with it at large text.
class FlowPage extends StatelessWidget {
  const FlowPage({
    required this.children,
    this.top,
    this.footer,
    this.horizontalPadding = 24,
    super.key,
  });

  final Widget? top;
  final List<Widget> children;
  final Widget? footer;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.canvas,
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            children: [
              // Pinned so Back and Save stay reachable on long pages.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  0,
                ),
                child: top ?? const SizedBox(height: 48),
              ),
              Expanded(child: _scrollBody()),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _scrollBody() => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverList.list(children: children),
      ),
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [?footer],
          ),
        ),
      ),
    ],
  );
}

/// Top bar row: leading control, centred content, trailing control.
class FlowTopBar extends StatelessWidget {
  const FlowTopBar({this.leading, this.center, this.trailing, super.key});
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;

  /// Side slots hug their content, so a text action such as "ยกเลิก" stays on
  /// one line. The minimum keeps icon-only bars symmetrical; the maximum keeps
  /// room for the title at large text sizes.
  static const _side = BoxConstraints(minWidth: 56, maxWidth: 132);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Row(
      children: [
        ConstrainedBox(
          constraints: _side,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: leading,
          ),
        ),
        Expanded(child: Center(child: center)),
        ConstrainedBox(
          constraints: _side,
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: 1,
            child: trailing,
          ),
        ),
      ],
    ),
  );
}
