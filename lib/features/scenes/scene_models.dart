import 'package:flutter/foundation.dart';

import '../../core/localization/app_localizations.dart';

enum SceneIcon { moon, home, leave, sunrise, sparkle }

enum LightTargetKind { device, zone, others, all }

/// Which lights an action applies to. `others` means every light the scene
/// has not already set.
@immutable
class LightTarget {
  const LightTarget.device(String id) : kind = LightTargetKind.device, key = id;
  const LightTarget.zone(String presetKey)
    : kind = LightTargetKind.zone,
      key = presetKey;
  const LightTarget.others() : kind = LightTargetKind.others, key = '';
  const LightTarget.all() : kind = LightTargetKind.all, key = '';

  final LightTargetKind kind;
  final String key;
}

sealed class SceneAction {
  const SceneAction();
}

class LightAction extends SceneAction {
  const LightAction({
    required this.target,
    required this.isOn,
    this.brightness,
    this.temperature,
  });

  final LightTarget target;
  final bool isOn;
  final double? brightness;
  final int? temperature;
}

/// Checks the lock and would warn if it is still open. Never unlocks.
class LockCheckAction extends SceneAction {
  const LockCheckAction();
}

@immutable
class Scene {
  const Scene({
    required this.id,
    required this.icon,
    required this.actions,
    this.presetKey,
    this.customName = '',
    this.lastRun,
  });

  final String id;
  final SceneIcon icon;
  final List<SceneAction> actions;
  final String? presetKey;
  final String customName;
  final DateTime? lastRun;

  String label(AppLocalizations l10n) =>
      presetKey == null ? customName : l10n.scenePreset(presetKey!);

  Scene copyWith({
    String? customName,
    bool clearPreset = false,
    List<SceneAction>? actions,
    DateTime? lastRun,
  }) => Scene(
    id: id,
    icon: icon,
    actions: actions ?? this.actions,
    presetKey: clearPreset ? null : presetKey,
    customName: customName ?? this.customName,
    lastRun: lastRun ?? this.lastRun,
  );

  Scene withId(String id) => Scene(
    id: id,
    icon: icon,
    actions: actions,
    presetKey: presetKey,
    customName: customName,
    lastRun: lastRun,
  );

  /// Zones this scene changes, for “scenes in this room”.
  bool touchesZone(String presetKey) => actions.any(
    (action) =>
        action is LightAction &&
        (action.target.kind == LightTargetKind.all ||
            action.target.key == presetKey),
  );
}
