import 'package:flutter/foundation.dart';

import '../home/home_store.dart';
import '../lighting/lighting_service.dart';
import 'scene_models.dart';

@immutable
class SceneRunResult {
  const SceneRunResult({required this.applied, required this.failed});
  final int applied;
  final int failed;
}

/// Mock scene list (spec 012). Running a scene sends ordinary light commands
/// through [LightingService] and is offered for demo lights only, as before.
class SceneStore extends ChangeNotifier {
  SceneStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _scenes = [
      Scene(
        id: 'scene-sleep',
        presetKey: 'Sleep',
        icon: SceneIcon.moon,
        lastRun: DateTime(now.year, now.month, now.day - 1, 23, 10),
        actions: const [
          LightAction(
            target: LightTarget.device('bedside-lamp'),
            isOn: true,
            brightness: .1,
            temperature: 2700,
          ),
          LightAction(target: LightTarget.others(), isOn: false),
          LockCheckAction(),
        ],
      ),
      const Scene(
        id: 'scene-home',
        presetKey: 'Welcome home',
        icon: SceneIcon.home,
        actions: [
          LightAction(
            target: LightTarget.zone('Living room'),
            isOn: true,
            brightness: .8,
            temperature: 3000,
          ),
          LightAction(target: LightTarget.zone('Front yard'), isOn: true),
        ],
      ),
      const Scene(
        id: 'scene-leave',
        presetKey: 'Leave home',
        icon: SceneIcon.leave,
        actions: [
          LightAction(target: LightTarget.all(), isOn: false),
          LockCheckAction(),
        ],
      ),
      const Scene(
        id: 'scene-wake',
        presetKey: 'Wake up',
        icon: SceneIcon.sunrise,
        actions: [
          LightAction(
            target: LightTarget.zone('Bedroom'),
            isOn: true,
            brightness: .6,
            temperature: 4500,
          ),
        ],
      ),
    ];
  }

  final DateTime Function() _clock;
  late List<Scene> _scenes;
  String? _running;
  int _nextId = 0;

  List<Scene> get scenes => List.unmodifiable(_scenes);
  String? get runningId => _running;
  Scene? byId(String id) =>
      _scenes.where((scene) => scene.id == id).firstOrNull;

  bool canRun(LightingService lighting) => lighting.isDemo && _running == null;

  Scene draft() => Scene(
    id: 'scene-new-${_nextId++}',
    icon: SceneIcon.sparkle,
    actions: const [],
  );

  void save(Scene scene) {
    final exists = _scenes.any((item) => item.id == scene.id);
    _scenes = exists
        ? [for (final item in _scenes) item.id == scene.id ? scene : item]
        : [..._scenes, scene];
    notifyListeners();
  }

  void delete(String id) {
    _scenes = _scenes.where((scene) => scene.id != id).toList();
    notifyListeners();
  }

  Future<SceneRunResult> run(
    Scene scene, {
    required LightingService lighting,
    required HomeStore homes,
  }) async {
    if (!canRun(lighting)) {
      return const SceneRunResult(applied: 0, failed: 0);
    }
    _running = scene.id;
    notifyListeners();
    var applied = 0;
    var failed = 0;
    final touched = <String>{};
    try {
      for (final action in scene.actions.whereType<LightAction>()) {
        for (final device in _targets(
          action.target,
          lighting,
          homes,
          touched,
        )) {
          touched.add(device.id);
          final command = _command(action, device.capabilities);
          if (!device.online || command == null) continue;
          try {
            await lighting.sendCommand(device.id, command);
            applied++;
          } catch (_) {
            failed++;
          }
        }
      }
      _scenes = [
        for (final item in _scenes)
          item.id == scene.id ? item.copyWith(lastRun: _clock()) : item,
      ];
    } finally {
      _running = null;
      notifyListeners();
    }
    return SceneRunResult(applied: applied, failed: failed);
  }

  Iterable<LightDevice> _targets(
    LightTarget target,
    LightingService lighting,
    HomeStore homes,
    Set<String> touched,
  ) => lighting.devices.where(
    (device) => switch (target.kind) {
      LightTargetKind.device => device.id == target.key,
      LightTargetKind.zone => _zoneKey(device, homes) == target.key,
      LightTargetKind.others => !touched.contains(device.id),
      LightTargetKind.all => true,
    },
  );

  String? _zoneKey(LightDevice device, HomeStore homes) {
    final zone = homes.zoneFor(device);
    return zone == null ? device.room : zone.presetKey;
  }

  LightCommand? _command(LightAction action, LightCapabilities caps) {
    if (!caps.power) return null;
    if (!action.isOn) return const LightCommand(isOn: false);
    final temperature = action.temperature;
    final useTemperature = temperature != null && caps.hasTemperatureRange;
    return LightCommand(
      isOn: true,
      brightness: caps.brightness ? action.brightness : null,
      temperature: useTemperature
          ? temperature.clamp(caps.minTemperature!, caps.maxTemperature!)
          : null,
      whiteMode: useTemperature,
    );
  }
}
