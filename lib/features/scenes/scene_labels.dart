import 'package:flutter/widgets.dart';

import '../../app_scope.dart';
import '../../core/localization/app_localizations.dart';
import '../lighting/light_labels.dart';
import 'scene_models.dart';

/// How scenes and their actions are described in lists and the editor.
extension SceneLabels on BuildContext {
  /// What an action applies to: a light, a zone, “all other lights”…
  String actionTitle(SceneAction action) => switch (action) {
    LockCheckAction() => l10n.frontDoor,
    LightAction(:final target) => switch (target.kind) {
      LightTargetKind.device => _deviceName(target.key),
      LightTargetKind.zone => l10n.room(target.key),
      LightTargetKind.others => l10n.otherLights,
      LightTargetKind.all => l10n.allLights,
    },
  };

  /// What the action does: “On · 10% · Warm”, “Off”, “Check it is locked”.
  String actionDetail(SceneAction action) => switch (action) {
    LockCheckAction() => l10n.lockCheckDetail,
    LightAction(:final isOn, :final brightness, :final temperature) =>
      !isOn
          ? l10n.off
          : [
              l10n.on,
              if (brightness != null) '${(brightness * 100).round()}%',
              if (temperature != null) l10n.temperatureFeel(temperature),
            ].join(' · '),
  };

  /// One line under a scene name in the list.
  String sceneSummary(Scene scene) {
    final lastRun = scene.lastRun;
    if (scene.actions.isEmpty) return l10n.noActionsYet;
    if (lastRun != null) {
      return '${l10n.actionCount(scene.actions.length)} · '
          '${l10n.lastUsed(lastRun, DateTime.now())}';
    }
    return scene.actions.take(2).map(_actionShort).join(' · ');
  }

  /// Compact form for list rows: “Living room 80%”, “All lights off”.
  String _actionShort(SceneAction action) => switch (action) {
    LockCheckAction() => l10n.lockCheckShort,
    LightAction(:final isOn, :final brightness) =>
      !isOn
          ? l10n.targetOff(actionTitle(action))
          : brightness == null
          ? actionTitle(action)
          : '${actionTitle(action)} ${(brightness * 100).round()}%',
  };

  String _deviceName(String id) {
    final device = app.lighting.devices.where((d) => d.id == id).firstOrNull;
    if (device != null) return lightName(device);
    return app.lighting.isDemo ? l10n.demoDevice(id, id) : l10n.unavailable;
  }
}
