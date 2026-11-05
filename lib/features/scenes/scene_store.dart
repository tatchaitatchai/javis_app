import 'package:flutter/foundation.dart';

import '../../backend/backend_failure.dart';
import '../../backend/javis_backend.dart';
import '../home/home_store.dart';
import '../lighting/lighting_service.dart';
import 'scene_models.dart';

@immutable
class SceneRunResult {
  const SceneRunResult({required this.applied, required this.failed});
  final int applied;
  final int failed;
}

/// The active home's scenes. Running one sends ordinary light commands through
/// [LightingService], then records the run.
class SceneStore extends ChangeNotifier {
  SceneStore(this._backend);

  final JavisBackend _backend;
  List<Scene> _scenes = const [];
  String? _homeId;
  String? _running;
  bool _loadFailed = false;
  int _nextId = 0;

  List<Scene> get scenes => List.unmodifiable(_scenes);
  String? get runningId => _running;
  bool get loadFailed => _loadFailed;
  Scene? byId(String id) =>
      _scenes.where((scene) => scene.id == id).firstOrNull;

  bool get canRun => _running == null;

  /// Uses scenes that are already at hand.
  void adopt(String homeId, List<Scene> scenes) {
    _homeId = homeId;
    _scenes = scenes;
    notifyListeners();
  }

  void reset() {
    _homeId = null;
    _scenes = const [];
    _loadFailed = false;
    notifyListeners();
  }

  /// Shows the scenes of [homeId]. Does nothing if they are already showing.
  Future<void> show(String? homeId) async {
    if (homeId == _homeId) return;
    if (homeId == null) return reset();
    _homeId = homeId;
    _scenes = const [];
    await reload();
  }

  Future<void> reload() async {
    final homeId = _homeId;
    if (homeId == null) return;
    _loadFailed = false;
    notifyListeners();
    try {
      final scenes = await _backend.loadScenes(homeId);
      if (homeId != _homeId) return; // The home changed while this was loading.
      _scenes = scenes;
    } on BackendFailure {
      if (homeId != _homeId) return;
      _scenes = const [];
      _loadFailed = true;
    }
    notifyListeners();
  }

  Scene draft() => Scene(
    id: '$_draftPrefix${_nextId++}',
    icon: SceneIcon.sparkle,
    actions: const [],
  );

  static const _draftPrefix = 'scene-new-';

  /// Throws `BackendFailure`; the editor stays open with the draft intact.
  Future<void> save(Scene scene) async {
    final homeId = _homeId;
    if (homeId == null) return;
    if (scene.id.startsWith(_draftPrefix)) {
      final saved = await _backend.createScene(homeId, scene);
      _scenes = [..._scenes, saved];
    } else {
      final saved = await _backend.updateScene(homeId, scene);
      _scenes = [
        for (final item in _scenes) item.id == saved.id ? saved : item,
      ];
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final homeId = _homeId;
    if (homeId == null) return;
    await _backend.deleteScene(homeId, id);
    _scenes = _scenes.where((scene) => scene.id != id).toList();
    notifyListeners();
  }

  Future<SceneRunResult> run(
    Scene scene, {
    required LightingService lighting,
    required HomeStore homes,
  }) async {
    if (!canRun) return const SceneRunResult(applied: 0, failed: 0);
    _running = scene.id;
    notifyListeners();
    var applied = 0;
    var failed = 0;
    final touched = <String>{};
    final lights = homes.lightsIn(lighting);
    try {
      for (final action in scene.actions.whereType<LightAction>()) {
        for (final device in _targets(action.target, lights, homes, touched)) {
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
      await _recordRun(scene);
    } finally {
      _running = null;
      notifyListeners();
    }
    return SceneRunResult(applied: applied, failed: failed);
  }

  /// The lights have already changed, so a failure here only leaves the
  /// server's last-run time behind. It does not fail the scene.
  Future<void> _recordRun(Scene scene) async {
    final homeId = _homeId;
    if (homeId == null) return;
    var lastRun = DateTime.now();
    try {
      lastRun = await _backend.recordSceneRun(homeId, scene.id);
    } on BackendFailure catch (failure) {
      debugPrint('Recording a scene run failed: ${failure.code}');
    }
    _scenes = [
      for (final item in _scenes)
        item.id == scene.id ? item.copyWith(lastRun: lastRun) : item,
    ];
  }

  Iterable<LightDevice> _targets(
    LightTarget target,
    List<LightDevice> lights,
    HomeStore homes,
    Set<String> touched,
  ) => lights.where(
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
