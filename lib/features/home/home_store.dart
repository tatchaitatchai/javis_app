import 'package:flutter/foundation.dart';

import '../../backend/backend_failure.dart';
import '../../backend/javis_backend.dart';
import '../lighting/lighting_service.dart';
import 'home_models.dart';

/// The account's homes, zones, members, invitations and device registry.
///
/// Calls throw `BackendFailure` for the screen that started them to report.
/// Reversible edits show at once and go back if the server refuses them.
class HomeStore extends ChangeNotifier {
  HomeStore(this._backend);

  final JavisBackend _backend;
  List<Home> _homes = const [];
  List<HomeInvite> _invites = const [];
  String? _activeId;
  bool _loading = false;
  bool _loadFailed = false;
  final Map<String, String> _deviceZones = {};
  final Map<String, String> _deviceNames = {};
  final Set<String> _foreignLights = {};
  final Set<String> _claiming = {};
  bool _sweepingLights = false;

  List<Home> get homes => List.unmodifiable(_homes);
  List<HomeInvite> get invites => List.unmodifiable(_invites);
  bool get hasHome => _homes.isNotEmpty;
  bool get loading => _loading;
  bool get loadFailed => _loadFailed;
  Home? get activeHome =>
      _homes.where((home) => home.id == _activeId).firstOrNull ??
      _homes.firstOrNull;

  /// Uses homes that are already at hand.
  void adopt(AccountHomes account) {
    _homes = account.homes;
    _invites = account.invites;
    _activeId = _homes.firstOrNull?.id;
    notifyListeners();
  }

  /// Loads everything for the signed-in account. Failure is shown by the
  /// screens through [loadFailed], with a retry.
  Future<void> load() async {
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      _apply(await _backend.loadHomes());
    } on BackendFailure {
      _loadFailed = true;
    }
    _loading = false;
    notifyListeners();
  }

  /// Picks up changes made elsewhere. What is on screen stays if this fails.
  Future<void> refresh() async {
    if (_loading) return;
    try {
      _apply(await _backend.loadHomes());
      _loadFailed = false;
      notifyListeners();
    } on BackendFailure catch (failure) {
      debugPrint('Home refresh failed: ${failure.code}');
    }
  }

  void _apply(AccountHomes account) {
    _homes = account.homes;
    _invites = account.invites;
    if (!_homes.any((home) => home.id == _activeId)) {
      _activeId = _homes.firstOrNull?.id;
    }
  }

  void reset() {
    _homes = const [];
    _invites = const [];
    _activeId = null;
    _loadFailed = false;
    _deviceZones.clear();
    _deviceNames.clear();
    _foreignLights.clear();
    notifyListeners();
  }

  void switchHome(String id) {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }

  /// Creates a home with the chosen zones and makes it active.
  Future<void> createHome({
    required String name,
    required List<String> presetKeys,
    required List<String> customZones,
  }) async {
    final home = await _backend.createHome(
      name: name.trim(),
      presetKeys: presetKeys,
      customZones: [for (final custom in customZones) custom.trim()],
    );
    _addAndActivate(home);
  }

  Future<void> acceptInvite(String inviteId) async {
    final invite = _invites.where((item) => item.id == inviteId).firstOrNull;
    if (invite == null) return;
    final home = await _backend.acceptInvite(invite);
    _invites = _invites.where((item) => item.id != inviteId).toList();
    _addAndActivate(home);
  }

  void _addAndActivate(Home home) {
    _homes = [..._homes, home];
    _activeId = home.id;
    notifyListeners();
  }

  Future<void> declineInvite(String inviteId) async {
    await _backend.declineInvite(inviteId);
    _invites = _invites.where((item) => item.id != inviteId).toList();
    notifyListeners();
  }

  Future<void> renameActiveHome(String name) async {
    final trimmed = name.trim();
    final home = activeHome;
    if (trimmed.isEmpty || home == null) return;
    await _optimistic(
      (home) => home.copyWith(name: trimmed),
      () => _backend.renameHome(home.id, trimmed),
    );
  }

  Future<void> addZone(String name) async {
    final trimmed = name.trim();
    final home = activeHome;
    if (trimmed.isEmpty || home == null) return;
    final zone = await _backend.addZone(home.id, trimmed);
    _update(home.id, (home) => home.copyWith(zones: [...home.zones, zone]));
  }

  Future<void> inviteMember({
    required String phone,
    required HomeRole role,
    required bool canUnlock,
  }) async {
    final home = activeHome;
    if (home == null) return;
    final member = await _backend.inviteMember(
      home.id,
      phone: phone,
      role: role,
      canUnlock: canUnlock,
    );
    _update(
      home.id,
      (home) => home.copyWith(members: [...home.members, member]),
    );
  }

  Future<void> updateMember(
    Member member, {
    HomeRole? role,
    bool? canUnlock,
  }) async {
    final home = activeHome;
    if (home == null) return;
    await _optimistic(
      (home) => home.copyWith(
        members: [
          for (final item in home.members)
            item.id == member.id
                ? item.copyWith(role: role, canUnlock: canUnlock)
                : item,
        ],
      ),
      () => _backend.updateMember(
        home.id,
        member.id,
        role: role,
        canUnlock: canUnlock,
      ),
    );
  }

  /// Removes someone from the active home, or takes back their invitation.
  Future<void> removeMember(Member member) async {
    final home = activeHome;
    if (home == null) return;
    await _optimistic(
      (home) => home.copyWith(
        members: home.members.where((item) => item.id != member.id).toList(),
      ),
      () => member.pending
          ? _backend.revokeInvite(home.id, member.id)
          : _backend.removeMember(home.id, member.id),
    );
  }

  /// Who the signed-in person may remove. The server enforces the same rule.
  bool canRemove(Member member) {
    final home = activeHome;
    if (home == null || member.isYou || member.role == HomeRole.owner) {
      return false;
    }
    if (member.pending) return home.canManage;
    return home.isOwner ||
        (home.role == HomeRole.admin && member.role == HomeRole.member);
  }

  bool get canLeaveActive {
    final home = activeHome;
    return home != null && !home.isOwner;
  }

  Future<void> leaveActiveHome() async {
    final home = activeHome;
    final you = home?.members.where((member) => member.isYou).firstOrNull;
    if (home == null || you == null || home.isOwner) return;
    await _backend.removeMember(home.id, you.id);
    _dropHome(home.id);
  }

  /// A home with registered devices cannot be deleted. In the demo, the
  /// connected home stands for that.
  bool canDeleteActive() {
    final home = activeHome;
    if (home == null || !home.isOwner || _homes.length < 2) return false;
    return _backend.isDemo ? !home.connected : home.devices.isEmpty;
  }

  Future<void> deleteActiveHome() async {
    final home = activeHome;
    if (home == null || !canDeleteActive()) return;
    await _backend.deleteHome(home.id);
    _dropHome(home.id);
  }

  void _dropHome(String id) {
    _homes = _homes.where((home) => home.id != id).toList();
    if (_activeId == id) _activeId = _homes.firstOrNull?.id;
    notifyListeners();
  }

  /// With the API and a real provider, each home owns the lights in its
  /// registry. Otherwise there is nothing real to register.
  bool _registersLights(LightingService lighting) =>
      !_backend.isDemo && !lighting.isDemo;

  /// The lights of the active home.
  List<LightDevice> lightsIn(LightingService lighting) {
    final home = activeHome;
    if (home == null || !home.connected) return const [];
    if (!_registersLights(lighting)) return lighting.devices;
    final refs = {for (final device in home.devices) device.externalRef};
    return lighting.devices.where((light) => refs.contains(light.id)).toList();
  }

  int deviceCount(Home home, LightingService lighting) {
    if (!_backend.isDemo) return home.devices.length;
    // The demo counts the preview lock too.
    return home.connected
        ? lighting.devices.length + 1
        : home.previewDeviceCount;
  }

  /// Registers lights the provider reports that no home has yet, so a bulb
  /// that was paired earlier does not vanish. One that another home owns stays
  /// hidden. Runs whenever the provider's list changes.
  Future<void> claimNewLights(LightingService lighting) async {
    final home = activeHome;
    if (_sweepingLights || !_registersLights(lighting)) return;
    if (home == null || !home.canManage) return;
    final known = {
      for (final home in _homes)
        for (final device in home.devices) device.externalRef,
      ..._foreignLights,
    };
    _sweepingLights = true;
    try {
      for (final light in lighting.devices) {
        if (known.contains(light.id) || _claiming.contains(light.id)) continue;
        try {
          await _claim(home.id, light.id);
        } on BackendFailure catch (failure) {
          if (failure.code != 'device_claimed') {
            debugPrint('Claiming a light failed: ${failure.code}');
            return; // Tried again the next time the list changes.
          }
          _foreignLights.add(light.id);
        }
      }
    } finally {
      _sweepingLights = false;
    }
  }

  Future<HomeDevice> _claim(String homeId, String externalRef) async {
    _claiming.add(externalRef);
    try {
      final device = await _backend.claimDevice(homeId, externalRef);
      _replaceDevice(homeId, device);
      return device;
    } finally {
      _claiming.remove(externalRef);
    }
  }

  void _replaceDevice(String homeId, HomeDevice device) => _update(
    homeId,
    (home) => home.copyWith(
      devices: [
        for (final item in home.devices)
          if (item.id != device.id) item,
        device,
      ],
    ),
  );

  HomeDevice? _registered(String lightId) => activeHome?.devices
      .where((device) => device.externalRef == lightId)
      .firstOrNull;

  /// Zone of a light: chosen zone first, then the provider room.
  String? zoneIdFor(LightDevice device) {
    final home = activeHome;
    if (home == null) return null;
    final assigned = _registered(device.id)?.zoneId ?? _deviceZones[device.id];
    if (assigned != null && home.zones.any((zone) => zone.id == assigned)) {
      return assigned;
    }
    return home.zones
        .where((zone) => zone.matchesRoom(device.room))
        .firstOrNull
        ?.id;
  }

  Zone? zoneFor(LightDevice device) {
    final id = zoneIdFor(device);
    return activeHome?.zones.where((zone) => zone.id == id).firstOrNull;
  }

  /// A name typed after pairing. It is never sent to the device provider.
  String? customDeviceName(String deviceId) =>
      _registered(deviceId)?.name ?? _deviceNames[deviceId];

  /// Saves the name and zone chosen after pairing. It shows at once; the
  /// server copy follows in [lighting]'s registered home.
  Future<void> labelDevice(
    LightingService lighting,
    String deviceId, {
    String? name,
    String? zoneId,
  }) async {
    final trimmed = name?.trim() ?? '';
    final typed = trimmed.isEmpty ? null : trimmed;
    if (typed != null) _deviceNames[deviceId] = typed;
    if (zoneId != null) _deviceZones[deviceId] = zoneId;
    notifyListeners();
    final home = activeHome;
    if (!_registersLights(lighting) || home == null) return;
    final device = _registered(deviceId) ?? await _claim(home.id, deviceId);
    if (typed == null && zoneId == null) return;
    _replaceDevice(
      home.id,
      await _backend.updateDevice(
        home.id,
        device.id,
        name: typed,
        zoneId: zoneId,
      ),
    );
  }

  /// Takes a light removed from the provider out of the home's registry.
  Future<void> forgetDevice(LightingService lighting, String deviceId) async {
    _deviceNames.remove(deviceId);
    _deviceZones.remove(deviceId);
    final home = activeHome;
    final device = _registered(deviceId);
    if (!_registersLights(lighting) || home == null || device == null) return;
    await _backend.removeDevice(home.id, device.id);
    _update(
      home.id,
      (home) => home.copyWith(
        devices: home.devices.where((item) => item != device).toList(),
      ),
    );
  }

  Future<void> _optimistic(
    Home Function(Home home) change,
    Future<void> Function() send,
  ) async {
    final home = activeHome;
    if (home == null) return;
    final before = _homes;
    _update(home.id, change);
    try {
      await send();
    } on BackendFailure {
      _homes = before;
      notifyListeners();
      rethrow;
    }
  }

  void _update(String id, Home Function(Home home) change) {
    _homes = [for (final home in _homes) home.id == id ? change(home) : home];
    notifyListeners();
  }
}
