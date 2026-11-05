import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/calm_switch.dart';
import '../../core/widgets/flow_page.dart';
import 'lock_store.dart';
import 'unlock_sheet.dart';

/// 12 · Front door lock (preview data, spec 012).
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = context.app.lock;
    final homes = context.app.homes;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([lock, homes]),
      builder: (context, _) {
        final status = lock.status;
        final canUnlock = homes.activeHome?.canUnlock ?? false;
        return FlowPage(
          top: FlowTopBar(
            leading: const CalmBackButton(),
            center: Column(
              children: [
                Text(
                  l10n.frontDoor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${l10n.room('Front yard')} · ${l10n.preview}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                canUnlock ? l10n.lockPreviewNote : l10n.noUnlockRight,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: status == LockStatus.unlocked
                    ? l10n.relocksAutomatically
                    : l10n.unlockDoor,
                icon: CupertinoIcons.lock_open,
                loading: status == LockStatus.unlocking,
                onPressed: status == LockStatus.locked && canUnlock
                    ? () => showUnlockSheet(context)
                    : null,
              ),
            ],
          ),
          children: [
            const SizedBox(height: 24),
            Center(child: _LockBadge(status: status)),
            const SizedBox(height: 18),
            Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.quick),
                child: Text(
                  l10n.lockStatus(status.name),
                  key: ValueKey(status),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Text(
              l10n.updatedAgo(DateTime.now().difference(lock.updatedAt)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.door,
                    value: lock.doorClosed ? l10n.doorClosed : l10n.doorOpen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: l10n.batteryLabel,
                    value: '${lock.batteryPercent}%',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: l10n.autoLock,
                    value: lock.autoLock ? l10n.on : l10n.off,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListGroup(
              children: [
                ListRow(
                  title: l10n.autoLock,
                  subtitle: l10n.autoLockHint,
                  trailing: CalmSwitch(
                    value: lock.autoLock,
                    semanticLabel: l10n.autoLock,
                    onChanged: lock.setAutoLock,
                  ),
                ),
              ],
            ),
            SectionHeader(l10n.recentActivity),
            for (final entry in lock.activity) _ActivityRow(entry: entry),
          ],
        );
      },
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.status});
  final LockStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final unlocked = status == LockStatus.unlocked;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.gentle),
        curve: Motion.curve,
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Ink in both themes, matching the dashboard door card.
          color: unlocked ? palette.gold : CalmPalette.light.strong,
          boxShadow: [BoxShadow(color: palette.accentTint, spreadRadius: 12)],
        ),
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.standard),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: status == LockStatus.unlocking
              ? SizedBox.square(
                  key: const ValueKey('busy'),
                  dimension: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: palette.gold,
                  ),
                )
              : Icon(
                  unlocked
                      ? CupertinoIcons.lock_open_fill
                      : CupertinoIcons.lock_fill,
                  key: ValueKey(unlocked),
                  size: 56,
                  color: unlocked ? CalmPalette.onGold : palette.gold,
                ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => CalmPanel(
    padding: const EdgeInsets.all(12),
    radius: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final LockActivity entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.event == LockEvent.autoLocked
                  ? palette.accent
                  : palette.goldDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.lockEvent(entry.event.name, entry.actor ?? ''),
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
          Text(
            l10n.clock(entry.at),
            style: TextStyle(fontSize: 13, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
