import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

enum LightingReadiness {
  initializing,
  ready,
  configurationMissing,
  sdkUnavailable,
  sessionRequired,
  unsupportedSimulator,
  permissionDenied,
  transportFailure,
  invalidProvider,
}

enum LightingError {
  unavailable,
  busy,
  cancelled,
  timeout,
  permissionDenied,
  configurationMissing,
  sdkUnavailable,
  sessionRequired,
  unsupportedSimulator,
  transportFailure,
  unsupportedCommand,
  pairingFailed,
  invalidNetwork,
  noDevices,
  multicastEntitlementRequired,
  deviceNotReady,
  bluetoothOff,
}

class LightingException implements Exception {
  const LightingException(this.code);
  final LightingError code;
}

enum PairingPhase { searching, activating, found, success, cancelled, failed }

/// `ble` sends Wi-Fi to a nearby dual-mode device over Bluetooth (spec 013).
enum WifiPairingMode { ap, ez, ble }

/// `unknown` covers the moment before iOS reports the radio state.
enum BluetoothState { unknown, on, off, unauthorized, unsupported }

/// A device found by the Bluetooth scan. [id] is app-owned and valid only for
/// the current scan; vendor identifiers stay in the native adapter.
@immutable
class NearbyDevice {
  const NearbyDevice(this.id);
  final String id;
}

@immutable
class PairingCapabilities {
  const PairingCapabilities({required this.ezAvailable, this.ezReason});
  final bool ezAvailable;
  final String? ezReason;
}

@immutable
class PairingOperation {
  const PairingOperation(this.id, this.phase);
  final String id;
  final PairingPhase phase;
}

/// Kept only for the active request. Never persist or log network credentials.
@immutable
class WifiPairingConfiguration {
  const WifiPairingConfiguration({
    required this.ssid,
    required this.password,
    this.mode = WifiPairingMode.ap,
    this.deviceId,
  });
  final String ssid;
  final String password;
  final WifiPairingMode mode;

  /// The chosen [NearbyDevice.id]; required for [WifiPairingMode.ble].
  final String? deviceId;

  bool get isValid =>
      ssid.trim().isNotEmpty &&
      password.isNotEmpty &&
      (mode != WifiPairingMode.ble || (deviceId?.isNotEmpty ?? false));
}

/// A joined, verified setup hotspot. This is not a paired device identity.
@immutable
class DeviceHotspot {
  const DeviceHotspot({required this.ssid});
  final String ssid;
}

@immutable
class LightCapabilities {
  const LightCapabilities({
    this.power = false,
    this.brightness = false,
    this.temperature = false,
    this.color = false,
    this.minTemperature,
    this.maxTemperature,
  });
  static const demo = LightCapabilities(
    power: true,
    brightness: true,
    temperature: true,
    color: true,
    minTemperature: 2700,
    maxTemperature: 6500,
  );
  final bool power;
  final bool brightness;
  final bool temperature;
  final bool color;
  final int? minTemperature;
  final int? maxTemperature;
  bool get hasTemperatureRange =>
      temperature &&
      minTemperature != null &&
      maxTemperature != null &&
      minTemperature! < maxTemperature!;
}

@immutable
class LightDevice {
  const LightDevice({
    required this.id,
    required this.name,
    required this.room,
    this.isOn = true,
    this.online = true,
    this.brightness = .72,
    this.temperature = 2700,
    this.color,
    this.capabilities = const LightCapabilities(),
  });
  final String id;
  final String name;
  final String room;
  final bool isOn;
  final bool online;
  final double brightness;
  final int temperature;
  final Color? color;
  final LightCapabilities capabilities;

  LightDevice copyWith({
    bool? isOn,
    double? brightness,
    int? temperature,
    Color? color,
    bool whiteMode = false,
  }) => LightDevice(
    id: id,
    name: name,
    room: room,
    online: online,
    isOn: isOn ?? this.isOn,
    brightness: brightness ?? this.brightness,
    temperature: temperature ?? this.temperature,
    color: whiteMode ? null : color ?? this.color,
    capabilities: capabilities,
  );
}

/// Explicit desired values. Omitted values leave the confirmed state untouched.
@immutable
class LightCommand {
  const LightCommand({
    this.isOn,
    this.brightness,
    this.temperature,
    this.color,
    this.whiteMode = false,
  });
  final bool? isOn;
  final double? brightness;
  final int? temperature;
  final Color? color;
  final bool whiteMode;

  Map<String, Object> toMap() => {
    'isOn': ?isOn,
    'brightness': ?brightness,
    'temperature': ?temperature,
    if (color != null) 'color': color!.toARGB32(),
    if (whiteMode) 'whiteMode': true,
  };

  bool supports(LightCapabilities c) =>
      toMap().isNotEmpty &&
      (isOn == null || c.power) &&
      (brightness == null ||
          (c.brightness &&
              brightness!.isFinite &&
              brightness! >= .01 &&
              brightness! <= 1)) &&
      (temperature == null ||
          (c.hasTemperatureRange &&
              temperature! >= c.minTemperature! &&
              temperature! <= c.maxTemperature!)) &&
      (color == null || c.color) &&
      (!whiteMode || c.hasTemperatureRange);
}

/// Owns operation lifetime and app state; provider details remain in adapters.
abstract class LightingService extends ChangeNotifier {
  bool get isDemo;
  LightingReadiness get readiness;
  List<LightDevice> get devices;
  PairingOperation? get pairing => _pairing;
  PairingOperation? _pairing;
  Completer<LightDevice>? _pairingResult;
  int _operationSequence = 0;
  bool _disposed = false;
  final Set<String> _pendingCommands = {};
  final Set<String> _pendingRemovals = {};

  Future<void> initialize();
  bool get preparingHome => false;
  Future<void> prepareHome() async =>
      throw const LightingException(LightingError.sessionRequired);
  Future<void> preparePairing() async =>
      throw const LightingException(LightingError.unavailable);
  Future<String?> currentWifi() async => null;
  Future<PairingCapabilities> pairingCapabilities() async =>
      const PairingCapabilities(ezAvailable: false);
  Future<DeviceHotspot> discoverBulbHotspot() async =>
      throw const LightingException(LightingError.unavailable);
  Future<List<String>> listBulbWifi() async => const [];
  Future<void> cancelSetup() async {}
  BluetoothState get bluetooth => BluetoothState.unknown;
  List<NearbyDevice> get nearbyDevices => const [];
  bool get scanning => false;
  Future<void> startDeviceScan() async =>
      throw const LightingException(LightingError.unavailable);
  Future<void> stopDeviceScan() async {}
  Future<void> refreshDevices();
  Future<LightDevice> performPairing(
    String operationId, {
    bool simulateFailure = false,
    WifiPairingConfiguration? network,
  });
  Future<void> stopPairing(String operationId);
  Future<void> performCommand(String deviceId, LightCommand command);
  Future<void> performRemoval(String deviceId) async =>
      throw const LightingException(LightingError.unavailable);

  bool get pairingActive => _pairingResult != null;
  bool isCommandPending(String deviceId) => _pendingCommands.contains(deviceId);
  bool isRemovalPending(String deviceId) => _pendingRemovals.contains(deviceId);
  bool isCurrentPairing(String operationId) =>
      !_disposed && pairingActive && _pairing?.id == operationId;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  void pairingProgress(String operationId, PairingPhase phase) {
    if (!isCurrentPairing(operationId)) return;
    _pairing = PairingOperation(operationId, phase);
    changed();
  }

  Future<LightDevice> startPairing({
    bool simulateFailure = false,
    WifiPairingConfiguration? network,
  }) {
    if (pairingActive) {
      return Future.error(const LightingException(LightingError.busy));
    }
    if (_disposed || readiness != LightingReadiness.ready) {
      return Future.error(const LightingException(LightingError.unavailable));
    }
    if (!isDemo && !(network?.isValid ?? false)) {
      return Future.error(
        const LightingException(LightingError.invalidNetwork),
      );
    }
    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${++_operationSequence}';
    final result = Completer<LightDevice>();
    _pairingResult = result;
    _pairing = PairingOperation(id, PairingPhase.searching);
    changed();
    unawaited(_runPairing(id, result, simulateFailure, network));
    return result.future;
  }

  Future<void> _runPairing(
    String id,
    Completer<LightDevice> result,
    bool fail,
    WifiPairingConfiguration? network,
  ) async {
    try {
      final device = await performPairing(
        id,
        simulateFailure: fail,
        network: network,
      );
      if (!isCurrentPairing(id)) return;
      _pairingResult = null;
      _pairing = PairingOperation(
        id,
        isDemo ? PairingPhase.found : PairingPhase.success,
      );
      result.complete(device);
      changed();
    } catch (error) {
      if (!isCurrentPairing(id)) return;
      _pairingResult = null;
      _pairing = PairingOperation(id, PairingPhase.failed);
      result.completeError(
        error is LightingException
            ? error
            : const LightingException(LightingError.transportFailure),
      );
      changed();
    }
  }

  Future<void> cancelPairing({bool notify = true}) async {
    final result = _pairingResult;
    final id = _pairing?.id;
    if (result == null || id == null) return;
    // Invalidate locally before transport cancellation can yield or fail.
    _pairingResult = null;
    _pairing = PairingOperation(id, PairingPhase.cancelled);
    result.completeError(const LightingException(LightingError.cancelled));
    if (notify) changed();
    try {
      await stopPairing(id);
    } catch (_) {
      // A disconnected transport must never revive a cancelled operation.
    }
  }

  Future<void> sendCommand(String deviceId, LightCommand command) async {
    final device = devices.where((d) => d.id == deviceId).firstOrNull;
    if (readiness != LightingReadiness.ready ||
        device == null ||
        !device.online) {
      throw const LightingException(LightingError.unavailable);
    }
    if (!command.supports(device.capabilities)) {
      throw const LightingException(LightingError.unsupportedCommand);
    }
    if (_pendingRemovals.contains(deviceId) ||
        !_pendingCommands.add(deviceId)) {
      throw const LightingException(LightingError.busy);
    }
    changed();
    try {
      await performCommand(deviceId, command);
    } finally {
      _pendingCommands.remove(deviceId);
      changed();
    }
  }

  Future<void> removeDevice(String deviceId) async {
    if (isDemo ||
        readiness != LightingReadiness.ready ||
        !devices.any((device) => device.id == deviceId)) {
      throw const LightingException(LightingError.unavailable);
    }
    if (pairingActive ||
        _pendingCommands.contains(deviceId) ||
        !_pendingRemovals.add(deviceId)) {
      throw const LightingException(LightingError.busy);
    }
    changed();
    try {
      await performRemoval(deviceId);
    } finally {
      _pendingRemovals.remove(deviceId);
      changed();
    }
  }

  /// Demo confirmation is separate from real provider activation.
  void confirmPairing(LightDevice device) {}

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancelPairing(notify: false));
    super.dispose();
  }
}

class MockLightingService extends LightingService {
  MockLightingService({this.pairingDelay = const Duration(milliseconds: 1400)});
  final Duration pairingDelay;
  final List<LightDevice> _devices = [
    const LightDevice(
      id: 'living-lamp',
      name: 'Ceiling light',
      room: 'Living room',
      brightness: .8,
      capabilities: LightCapabilities.demo,
    ),
    const LightDevice(
      id: 'bedroom-ceiling',
      name: 'Bedroom ceiling light',
      room: 'Bedroom',
      isOn: false,
      brightness: .6,
      temperature: 4000,
      capabilities: LightCapabilities.demo,
    ),
    const LightDevice(
      id: 'bedside-lamp',
      name: 'Bedside light',
      room: 'Bedroom',
      brightness: .3,
      capabilities: LightCapabilities.demo,
    ),
    const LightDevice(
      id: 'kitchen-lamp',
      name: 'Kitchen light',
      room: 'Kitchen',
      brightness: 1,
      temperature: 4000,
      capabilities: LightCapabilities.demo,
    ),
    const LightDevice(
      id: 'porch-lamp',
      name: 'Porch light',
      room: 'Front yard',
      online: false,
      isOn: false,
      capabilities: LightCapabilities.demo,
    ),
  ];
  @override
  bool get isDemo => true;
  @override
  LightingReadiness get readiness => LightingReadiness.ready;
  @override
  List<LightDevice> get devices => List.unmodifiable(_devices);
  @override
  Future<void> initialize() async {}
  @override
  Future<void> refreshDevices() async {}
  @override
  Future<void> performCommand(String deviceId, LightCommand command) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    _devices[index] = _devices[index].copyWith(
      isOn: command.isOn,
      brightness: command.brightness,
      temperature: command.temperature,
      color: command.color,
      whiteMode: command.whiteMode,
    );
    changed();
  }

  @override
  Future<LightDevice> performPairing(
    String operationId, {
    bool simulateFailure = false,
    WifiPairingConfiguration? network,
  }) async {
    await Future<void>.delayed(pairingDelay);
    if (simulateFailure) {
      throw const LightingException(LightingError.pairingFailed);
    }
    return const LightDevice(
      id: 'new-demo-bulb',
      name: 'New ambient bulb',
      room: 'Living room',
      capabilities: LightCapabilities.demo,
    );
  }

  @override
  Future<void> stopPairing(String operationId) async {}
  @override
  void confirmPairing(LightDevice device) {
    if (_devices.any((d) => d.id == device.id)) return;
    _devices.add(device);
    changed();
  }
}
