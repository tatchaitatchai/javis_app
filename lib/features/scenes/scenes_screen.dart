import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/motion/entrance.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calm_buttons.dart';
import '../../core/widgets/calm_surfaces.dart';
import '../../core/widgets/pressable.dart';
import 'scene_editor_screen.dart';
import 'scene_labels.dart';
import 'scene_models.dart';
import 'scene_strip.dart';

void openSceneEditor(BuildContext context, {String? sceneId}) =>
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: sceneId == null,
        builder: (_) => SceneEditorScreen(sceneId: sceneId),
      ),
    );

/// 19 · Scenes tab: one tap runs several lights at once.
class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([app.scenes, app.lighting, app.homes]),
      builder: (context, _) {
        final scenes = app.scenes.scenes;
        final canManage = app.homes.activeHome?.canManage ?? false;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.scenesTab,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      if (canManage)
                        CircleIconButton(
                          icon: CupertinoIcons.add,
                          tooltip: l10n.newScene,
                          onPressed: () => openSceneEditor(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scenesSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  for (final (index, scene) in scenes.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Entrance(
                        order: index,
                        child: _SceneCard(
                          scene: scene,
                          onOpen: canManage
                              ? () =>
                                    openSceneEditor(context, sceneId: scene.id)
                              : null,
                        ),
                      ),
                    ),
                  if (app.scenes.loadFailed)
                    CalmPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.cantLoadScenes),
                          const SizedBox(height: 8),
                          SecondaryButton(
                            label: l10n.tryAgain,
                            onPressed: app.scenes.reload,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene, this.onOpen});
  final Scene scene;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final app = context.app;
    final l10n = context.l10n;
    final running = app.scenes.runningId == scene.id;
    final name = scene.label(l10n);
    final summary = context.sceneSummary(scene);
    final content = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: running ? palette.glow : palette.accentTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            sceneIcon(scene.icon),
            color: running ? palette.goldDeep : palette.accentDeep,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: palette.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
    return AnimatedContainer(
      duration: Motion.of(context, Motion.standard),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: running ? palette.glow : palette.paper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: onOpen == null
                ? Semantics(label: '$name, $summary', child: content)
                : Pressable(
                    onPressed: onOpen,
                    pressedScale: .98,
                    semanticLabel: l10n.editSceneNamed(name),
                    excludeChildSemantics: true,
                    child: content,
                  ),
          ),
          const SizedBox(width: 10),
          _StartButton(
            running: running,
            label: l10n.startSceneShort,
            semanticLabel: l10n.startScene(name),
            onPressed: scene.actions.isEmpty || app.scenes.runningId != null
                ? null
                : () => runScene(context, scene),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.running,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final bool running;
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.quick),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled || running ? palette.strong : palette.raised,
              borderRadius: BorderRadius.circular(20),
            ),
            child: running
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.gold,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: enabled ? palette.onStrong : palette.textFaint,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
