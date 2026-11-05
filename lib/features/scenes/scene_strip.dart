import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';
import 'scene_models.dart';

IconData sceneIcon(SceneIcon icon) => switch (icon) {
  SceneIcon.moon => CupertinoIcons.moon_fill,
  SceneIcon.home => CupertinoIcons.house_fill,
  SceneIcon.leave => CupertinoIcons.arrow_right_square,
  SceneIcon.sunrise => CupertinoIcons.sunrise_fill,
  SceneIcon.sparkle => CupertinoIcons.sparkles,
};

/// Runs a scene with feedback. Lights without a capability are skipped.
Future<void> runScene(BuildContext context, Scene scene) async {
  final app = context.app;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  if (!app.scenes.canRun) return;
  Haptics.confirm();
  final result = await app.scenes.run(
    scene,
    lighting: app.lighting,
    homes: app.homes,
  );
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          result.failed > 0
              ? l10n.sceneError
              : l10n.sceneRan(scene.label(l10n)),
        ),
      ),
    );
}

/// A tappable scene chip (design: 44pt, paper, icon + name).
class ScenePill extends StatelessWidget {
  const ScenePill({required this.scene, this.onPressed, super.key});
  final Scene scene;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scenes = context.app.scenes;
    return ListenableBuilder(
      listenable: scenes,
      builder: (context, _) {
        final running = scenes.runningId == scene.id;
        return Pressable(
          onPressed: onPressed ?? () => runScene(context, scene),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              widthFactor: 1,
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.quick),
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: running ? palette.glow : palette.paper,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.quick),
                      child: running
                          ? SizedBox.square(
                              key: const ValueKey('running'),
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.goldDeep,
                              ),
                            )
                          : Icon(
                              sceneIcon(scene.icon),
                              key: const ValueKey('icon'),
                              size: 18,
                              color: palette.accentDeep,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      scene.label(context.l10n),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
