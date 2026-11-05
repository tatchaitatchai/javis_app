import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';
import 'lock_screen.dart';
import 'lock_store.dart';
import 'unlock_sheet.dart';

/// Dashboard card for the front door (design 09). Preview data only.
class LockCard extends StatelessWidget {
  const LockCard({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = context.app.lock;
    // The door card stays ink in both themes: an inverted cream slab reads
    // as a glare on the dark canvas and drops the gold icon's contrast.
    const palette = CalmPalette.light;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        final locked = lock.status == LockStatus.locked;
        return Pressable(
          onPressed: () => Navigator.of(
            context,
          ).push(CupertinoPageRoute<void>(builder: (_) => const LockScreen())),
          pressedScale: .98,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.standard),
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: palette.strong,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.strongRaised,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.quick),
                    child: Icon(
                      locked
                          ? CupertinoIcons.lock_fill
                          : CupertinoIcons.lock_open_fill,
                      key: ValueKey(locked),
                      size: 22,
                      color: palette.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.frontDoor,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: palette.onStrong,
                        ),
                      ),
                      Text(
                        '${l10n.lockStatus(lock.status.name)} · '
                        '${l10n.battery(lock.batteryPercent)}',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: palette.onStrongMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onPressed: locked ? () => showUnlockSheet(context) : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.unlock,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CalmPalette.onGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
