import 'dart:async';

import 'package:flutter/services.dart';

import 'lighting_service.dart';

LightingService createLightingService({
  String provider = const String.fromEnvironment(
    'JAVIS_LIGHTING_PROVIDER',
    defaultValue: 'demo',
  ),
}) => switch (provider) {
  'demo' => MockLightingService(),
  'tuya' => TuyaLightingService(),
  _ => _InvalidProviderService(),
};

/// The native adapter exchanges only app-owned values, never vendor SDK objects.
class TuyaLightingService extends LightingService {
  TuyaLightingService({
    this.methods = const MethodChannel('com.javis.home/lighting'),
    this.events = const EventChannel('com.javis.home/lighting/events'),
    this.pairingTimeout = const Duration(minutes: 2),
  });
  final MethodChannel methods;
  final EventChannel events;
  final Duration pairingTimeout;
  StreamSubscription<dynamic>? _subscription;
  Future<void>? _initialization;
  Future<void>? _homePreparation;
  Future<void>? _pairingPreparation;
  Future<DeviceHotspot>? _hotspotDiscovery;
  LightingReadiness _readiness = LightingReadiness.initializing;
  List<LightDevice> _devices = const [];
  Completer<String>? _nativePairing;
  String? _nativeOperation;
  bool _closed = false;
  int _sessionGeneration = 0;
  int _setupGeneration = 0;
  BluetoothState _bluetooth = BluetoothState.unknown;
  List<NearbyDevice> _nearby = const [];
  bool _scanning = false;
  int _scanGeneration = 0;

  @override
  bool get isDemo => false;
  @override
  LightingReadiness get readiness => _readiness;
  @override
  List<LightDevice> get devices => _devices;
  @override
  bool get preparingHome => _homePreparation != null;
  @override
  BluetoothState get bluetooth => _bluetooth;
  @override
  List<NearbyDevice> get nearbyDevices => _nearby;
  @override
  bool get scanning => _scanning;

  @override
  Future<void> prepareHome() {
    if (_homePreparation != null) return _homePreparation!;
    if (_closed || pairingActive || _initialization != null) {
      return Future.error(const LightingException(LightingError.busy));
    }
    final preparation = _prepareHome();
    _homePreparation = preparation;
    changed();
    return preparation;
  }

  Future<void> _prepareHome() async {
    final generation = _sessionGeneration;
    try {
      final snapshot = await _invoke(
        'prepareHome',
        null,
        const Duration(seconds: 60),
      );
      if (_closed || generation != _sessionGeneration) {
        throw const LightingException(LightingError.unavailable);
      }
      _setReadiness(_parseReadiness(snapshot['readiness']));
      if (_readiness == LightingReadiness.ready) {
        _replaceDevices(snapshot['devices']);
      } else {
        throw const LightingException(LightingError.sessionRequired);
      }
    } finally {
      _homePreparation = null;
      changed();
    }
  }

  @override
  Future<void> preparePairing() => _pairingPreparation ??= _preparePairing();

  Future<void> _preparePairing() async {
    final generation = _sessionGeneration;
    final setupGeneration = _setupGeneration;
    try {
      _requireSetup(generation, setupGeneration);
      await _invoke('preparePairing', null, const Duration(seconds: 60));
      _requireSetup(generation, setupGeneration);
    } finally {
      if (setupGeneration == _setupGeneration) _pairingPreparation = null;
    }
  }

  @override
  Future<PairingCapabilities> pairingCapabilities() async {
    final generation = _sessionGeneration;
    final setupGeneration = _setupGeneration;
    _requireSetup(generation, setupGeneration);
    final snapshot = await _invoke('pairingCapabilities');
    _requireSetup(generation, setupGeneration);
    if (snapshot['ezAvailable'] is! bool ||
        (snapshot['ezReason'] != null && snapshot['ezReason'] is! String)) {
      throw const LightingException(LightingError.transportFailure);
    }
    return PairingCapabilities(
      ezAvailable: snapshot['ezAvailable'] as bool,
      ezReason: snapshot['ezReason'] as String?,
    );
  }

  @override
  Future<String?> currentWifi() async {
    final generation = _sessionGeneration;
    final setupGeneration = _setupGeneration;
    _requireSetup(generation, setupGeneration);
    final snapshot = await _invoke(
      'currentWifi',
      null,
      const Duration(seconds: 60),
    );
    _requireSetup(generation, setupGeneration);
    final ssid = snapshot['ssid'];
    if (ssid == null) return null;
    if (ssid is! String) {
      throw const LightingException(LightingError.transportFailure);
    }
    return ssid.trim().isEmpty || ssid.startsWith('SmartLife') ? null : ssid;
  }

  @override
  Future<DeviceHotspot> discoverBulbHotspot() =>
      _hotspotDiscovery ??= _discoverBulbHotspot();

  Future<DeviceHotspot> _discoverBulbHotspot() async {
    final generation = _sessionGeneration;
    final setupGeneration = _setupGeneration;
    try {
      _requireSetup(generation, setupGeneration);
      if (pairingActive) {
        throw const LightingException(LightingError.busy);
      }
      final snapshot = await _invoke(
        'discoverBulbHotspot',
        null,
        const Duration(seconds: 60),
      );
      _requireSetup(generation, setupGeneration);
      final ssid = snapshot['ssid'];
      if (ssid is! String || !ssid.startsWith('SmartLife')) {
        throw const LightingException(LightingError.noDevices);
      }
      return DeviceHotspot(ssid: ssid);
    } finally {
      if (setupGeneration == _setupGeneration) _hotspotDiscovery = null;
    }
  }

  @override
  Future<List<String>> listBulbWifi() async {
    final generation = _sessionGeneration;
    final setupGeneration = _setupGeneration;
    _requireSetup(generation, setupGeneration);
    final snapshot = await _invoke(
      'listBulbWifi',
      null,
      const Duration(seconds: 30),
    );
    _requireSetup(generation, setupGeneration);
    final networks = snapshot['networks'];
    if (networks is! List) {
      throw const LightingException(LightingError.transportFailure);
    }
    return List.unmodifiable({
      for (final network in networks)
        if (network is Map &&
            network['ssid'] is String &&
            (network['ssid'] as String).trim().isNotEmpty &&
            !(network['ssid'] as String).startsWith('SmartLife'))
          network['ssid'] as String,
    });
  }

  @override
  Future<void> cancelSetup() async {
    // Invalidate locally before transport can yield; a new screen must never
    // reuse a cancelled screen's in-flight hotspot or token-preparation reply.
    _setupGeneration++;
    _hotspotDiscovery = null;
    _pairingPreparation = null;
    try {
      await _invoke('cancelSetup');
    } on LightingException {
      // Route disposal cannot surface cleanup errors or revive cancelled work.
    }
  }

  /// Starts a fresh Bluetooth scan. Results arrive as `nearby` events, and
  /// `bluetooth` events report the radio while the scan is wanted.
  @override
  Future<void> startDeviceScan() async {
    final generation = _sessionGeneration;
    _requireSession(generation);
    if (pairingActive) throw const LightingException(LightingError.busy);
    final scan = ++_scanGeneration;
    _nearby = const [];
    _scanning = true;
    changed();
    try {
      final snapshot = await _invoke('startDeviceScan');
      _requireSession(generation);
      if (scan == _scanGeneration) {
        _bluetooth = _parseBluetooth(snapshot['bluetooth']);
      }
    } catch (_) {
      if (scan == _scanGeneration) _scanning = false;
      rethrow;
    } finally {
      changed();
    }
  }

  /// Safe to call from route disposal: it does not notify listeners.
  @override
  Future<void> stopDeviceScan() async {
    _endScan();
    try {
      await _invoke('stopDeviceScan');
    } on LightingException {
      // Leaving the screen cannot surface cleanup errors.
    }
  }

  void _endScan() {
    _scanGeneration++;
    _scanning = false;
    _nearby = const [];
  }

  void _requireSetup(int generation, int setupGeneration) {
    _requireSession(generation);
    if (setupGeneration != _setupGeneration) {
      throw const LightingException(LightingError.cancelled);
    }
  }

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    _setReadiness(LightingReadiness.initializing);
    final generation = _sessionGeneration;
    var restoreExistingHome = false;
    changed();
    // Listen before initialization; its complete snapshot repairs missed events.
    _subscription ??= events.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object error) {
        if (_closed) return;
        _setReadiness(
          LightingReadiness.transportFailure,
          LightingError.transportFailure,
        );
        changed();
      },
      onDone: () {
        if (_closed) return;
        _setReadiness(
          LightingReadiness.transportFailure,
          LightingError.transportFailure,
        );
        changed();
      },
    );
    try {
      final snapshot = await _invoke('initialize');
      restoreExistingHome = snapshot['canRestoreHome'] == true;
      if (_closed || generation != _sessionGeneration) return;
      _setReadiness(_parseReadiness(snapshot['readiness']));
      if (_readiness == LightingReadiness.ready) {
        _replaceDevices(snapshot['devices']);
      } else {
        _devices = const [];
      }
    } on LightingException catch (error) {
      if (_closed || generation != _sessionGeneration) return;
      _setReadiness(switch (error.code) {
        LightingError.configurationMissing =>
          LightingReadiness.configurationMissing,
        LightingError.sdkUnavailable => LightingReadiness.sdkUnavailable,
        LightingError.sessionRequired => LightingReadiness.sessionRequired,
        LightingError.unsupportedSimulator =>
          LightingReadiness.unsupportedSimulator,
        LightingError.permissionDenied => LightingReadiness.permissionDenied,
        _ => LightingReadiness.transportFailure,
      }, error.code);
    } finally {
      _initialization = null;
      changed();
      if (restoreExistingHome &&
          !_closed &&
          _readiness == LightingReadiness.sessionRequired) {
        unawaited(_restoreExistingHome());
      }
    }
  }

  Future<void> _restoreExistingHome() async {
    try {
      await prepareHome();
    } on LightingException {
      // Keep the explicit setup/retry action available if the network is down.
    }
  }

  @override
  Future<void> refreshDevices() async {
    final generation = _sessionGeneration;
    _requireSession(generation);
    final snapshot = await _invoke('refreshDevices');
    _requireSession(generation);
    _replaceDevices(snapshot['devices']);
    changed();
  }

  @override
  Future<LightDevice> performPairing(
    String operationId, {
    bool simulateFailure = false,
    WifiPairingConfiguration? network,
  }) async {
    if (network == null || !network.isValid) {
      throw const LightingException(LightingError.invalidNetwork);
    }
    final generation = _sessionGeneration;
    _requireSession(generation);
    if (network.mode == WifiPairingMode.ez) {
      final capabilities = await pairingCapabilities();
      _requireSession(generation);
      if (!isCurrentPairing(operationId)) {
        throw const LightingException(LightingError.cancelled);
      }
      if (!capabilities.ezAvailable) {
        throw LightingException(
          capabilities.ezReason == 'multicastEntitlementRequired'
              ? LightingError.multicastEntitlementRequired
              : LightingError.unavailable,
        );
      }
    }
    // Native pauses the Bluetooth scan while it talks to the chosen device.
    if (network.mode == WifiPairingMode.ble) _endScan();
    final result = Completer<String>();
    _nativeOperation = operationId;
    _nativePairing = result;
    // Attach the listener before invoking native code, which may emit immediately.
    final completion = result.future.timeout(
      pairingTimeout,
      onTimeout: () {
        throw const LightingException(LightingError.timeout);
      },
    );
    try {
      // Observe the future immediately so a synchronous native error/event cannot
      // become an unhandled asynchronous error while the method reply is pending.
      final replies = await Future.wait<Object>([
        _invoke('startPairing', {
          'operationId': operationId,
          'ssid': network.ssid,
          'password': network.password,
          'mode': network.mode.name,
          'deviceId': ?network.deviceId,
        }),
        completion,
      ], eagerError: true);
      final deviceId = replies[1] as String;
      _requireSession(generation);
      if (!isCurrentPairing(operationId)) {
        throw const LightingException(LightingError.cancelled);
      }
      final snapshot = await _invoke('refreshDevices');
      _requireSession(generation);
      if (!isCurrentPairing(operationId)) {
        throw const LightingException(LightingError.cancelled);
      }
      _replaceDevices(snapshot['devices']);
      final device = _devices.where((d) => d.id == deviceId).firstOrNull;
      if (device == null) {
        throw const LightingException(LightingError.pairingFailed);
      }
      changed();
      return device;
    } catch (_) {
      // Stop every failed provider attempt, including stream loss and a failed
      // post-activation refresh. Local cancellation has already cleared this ID.
      if (_nativeOperation == operationId) {
        try {
          await stopPairing(operationId);
        } catch (_) {
          // Preserve the failure that ended pairing if transport cleanup fails.
        }
      }
      rethrow;
    } finally {
      if (!result.isCompleted) {
        result.completeError(const LightingException(LightingError.cancelled));
      }
      if (_nativeOperation == operationId) {
        _nativeOperation = null;
        _nativePairing = null;
      }
    }
  }

  @override
  Future<void> stopPairing(String operationId) async {
    if (_nativeOperation != operationId) return;
    _failNativePairing(const LightingException(LightingError.cancelled));
    _nativeOperation = null;
    _nativePairing = null;
    await _invoke('cancelPairing', {'operationId': operationId});
  }

  @override
  Future<void> performCommand(String deviceId, LightCommand command) async {
    final generation = _sessionGeneration;
    _requireSession(generation);
    await _invoke('sendCommand', {
      'deviceId': deviceId,
      'command': command.toMap(),
    });
    _requireSession(generation);
    // Acceptance is not confirmation. Only reported snapshots change UI state.
    await refreshDevices();
  }

  @override
  Future<void> performRemoval(String deviceId) async {
    final generation = _sessionGeneration;
    _requireSession(generation);
    final snapshot = await _invoke('removeDevice', {
      'deviceId': deviceId,
    }, const Duration(seconds: 30));
    _requireSession(generation);
    _replaceDevices(snapshot['devices']);
    changed();
  }

  Future<Map<Object?, Object?>> _invoke(
    String method, [
    Map<String, Object>? arguments,
    Duration timeout = const Duration(seconds: 15),
  ]) async {
    try {
      final value = await methods
          .invokeMethod<Object?>(method, arguments)
          .timeout(timeout);
      if (value is! Map) {
        throw const LightingException(LightingError.transportFailure);
      }
      return Map<Object?, Object?>.from(value);
    } on MissingPluginException {
      throw const LightingException(LightingError.sdkUnavailable);
    } on PlatformException catch (error) {
      throw LightingException(_parseError(error.code));
    } on TimeoutException {
      throw const LightingException(LightingError.transportFailure);
    }
  }

  void _onEvent(dynamic value) {
    if (_closed || value is! Map) return;
    switch (value['type']) {
      case 'readiness':
        _setReadiness(_parseReadiness(value['readiness']));
        changed();
      case 'devices':
        if (_readiness != LightingReadiness.ready) return;
        if (value['devices'] is! List) {
          _setReadiness(
            LightingReadiness.transportFailure,
            LightingError.transportFailure,
          );
          changed();
          return;
        }
        _replaceDevices(value['devices']);
        changed();
      case 'bluetooth':
        if (!_scanning) return;
        _bluetooth = _parseBluetooth(value['state']);
        changed();
      case 'nearby':
        final found = value['devices'];
        if (!_scanning || found is! List) return;
        _nearby = List.unmodifiable(
          {
            for (final item in found)
              if (item is Map &&
                  item['id'] is String &&
                  (item['id'] as String).isNotEmpty)
                item['id'] as String,
          }.map(NearbyDevice.new),
        );
        changed();
      case 'pairing':
        final operationId = value['operationId'];
        if (operationId is! String ||
            !isCurrentPairing(operationId) ||
            _nativeOperation != operationId) {
          return;
        }
        switch (value['status']) {
          case 'searching':
            pairingProgress(operationId, PairingPhase.searching);
          case 'activating':
            pairingProgress(operationId, PairingPhase.activating);
          case 'success':
            final deviceId = value['deviceId'];
            if (deviceId is String && deviceId.isNotEmpty) {
              if (!(_nativePairing?.isCompleted ?? true)) {
                _nativePairing!.complete(deviceId);
              }
            } else {
              _failNativePairing(
                const LightingException(LightingError.pairingFailed),
              );
            }
          case 'failed':
            _failNativePairing(
              LightingException(_parseError(value['errorCode'])),
            );
        }
    }
  }

  void _failNativePairing(LightingException error) {
    if (!(_nativePairing?.isCompleted ?? true)) {
      _nativePairing!.completeError(error);
    }
  }

  void _setReadiness(
    LightingReadiness readiness, [
    LightingError error = LightingError.unavailable,
  ]) {
    _readiness = readiness;
    if (readiness != LightingReadiness.ready) {
      // Also invalidate initialization in flight when a newer non-ready event
      // arrives before its first ready snapshot has returned.
      _sessionGeneration++;
      _devices = const [];
      _endScan();
      _failNativePairing(LightingException(error));
    }
  }

  void _requireSession(int generation) {
    if (_closed ||
        generation != _sessionGeneration ||
        _readiness != LightingReadiness.ready) {
      throw const LightingException(LightingError.unavailable);
    }
  }

  void _replaceDevices(Object? value) {
    if (value is! List) {
      throw const LightingException(LightingError.transportFailure);
    }
    final unique = <String, LightDevice>{};
    for (final item in value) {
      if (item is! Map ||
          item['id'] is! String ||
          (item['id'] as String).isEmpty ||
          item['name'] is! String) {
        continue;
      }
      final capabilities = item['capabilities'] is Map
          ? item['capabilities'] as Map
          : const {};
      final brightness = item['brightness'];
      unique[item['id'] as String] = LightDevice(
        id: item['id'] as String,
        name: item['name'] as String,
        room: item['room'] is String ? item['room'] as String : '',
        isOn: item['isOn'] == true,
        online: item['online'] == true,
        brightness: brightness is num && brightness.isFinite
            ? brightness.toDouble().clamp(.01, 1)
            : .01,
        temperature: item['temperature'] is int
            ? item['temperature'] as int
            : 0,
        color: item['color'] is int ? Color(item['color'] as int) : null,
        capabilities: LightCapabilities(
          power: capabilities['power'] == true,
          brightness: capabilities['brightness'] == true,
          temperature: capabilities['temperature'] == true,
          color: capabilities['color'] == true,
          minTemperature: capabilities['minTemperature'] is int
              ? capabilities['minTemperature'] as int
              : null,
          maxTemperature: capabilities['maxTemperature'] is int
              ? capabilities['maxTemperature'] as int
              : null,
        ),
      );
    }
    _devices = List.unmodifiable(unique.values);
  }

  static LightingReadiness _parseReadiness(Object? value) =>
      LightingReadiness.values
          .where((r) => r.name == value && r != LightingReadiness.initializing)
          .firstOrNull ??
      LightingReadiness.transportFailure;
  static BluetoothState _parseBluetooth(Object? value) =>
      BluetoothState.values.where((s) => s.name == value).firstOrNull ??
      BluetoothState.unknown;
  static LightingError _parseError(Object? value) =>
      LightingError.values.where((e) => e.name == value).firstOrNull ??
      LightingError.transportFailure;

  @override
  void dispose() {
    _closed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class _InvalidProviderService extends LightingService {
  @override
  bool get isDemo => false;
  @override
  LightingReadiness get readiness => LightingReadiness.invalidProvider;
  @override
  List<LightDevice> get devices => const [];
  @override
  Future<void> initialize() async {}
  @override
  Future<void> refreshDevices() async {}
  @override
  Future<LightDevice> performPairing(
    String operationId, {
    bool simulateFailure = false,
    WifiPairingConfiguration? network,
  }) async => throw const LightingException(LightingError.unavailable);
  @override
  Future<void> stopPairing(String operationId) async {}
  @override
  Future<void> performCommand(String deviceId, LightCommand command) async =>
      throw const LightingException(LightingError.unavailable);
}
