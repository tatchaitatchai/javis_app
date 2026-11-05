import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';
import '../account/me_screen.dart';
import '../home/dashboard_screen.dart';
import '../scenes/scenes_screen.dart';

/// Signed-in shell with the three tabs from the design: Home, Scenes, Me.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      (CupertinoIcons.house, CupertinoIcons.house_fill, l10n.homeTab),
      (CupertinoIcons.sparkles, CupertinoIcons.sparkles, l10n.scenesTab),
      (CupertinoIcons.person, CupertinoIcons.person_fill, l10n.meTab),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(onOpenScenes: () => setState(() => _tab = 1)),
          const ScenesScreen(),
          const MeScreen(),
        ],
      ),
      bottomNavigationBar: _TabBar(
        tabs: tabs,
        selected: _tab,
        onSelected: (index) => setState(() => _tab = index),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<(IconData, IconData, String)> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.paper,
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Semantics(
          container: true,
          label: context.l10n.mainMenu,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Pressable(
                    onPressed: () => onSelected(i),
                    selected: i == selected,
                    pressedScale: .92,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 58),
                      child: _TabItem(tab: tabs[i], active: i == selected),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.active});
  final (IconData, IconData, String) tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = active ? palette.text : palette.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.quick),
            child: Icon(
              active ? tab.$2 : tab.$1,
              key: ValueKey(active),
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tab.$3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
