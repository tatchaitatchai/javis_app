import 'package:flutter/foundation.dart';

import '../lighting/lighting_service.dart';
import 'home_models.dart';

/// In-memory homes, zones, members and invitations (spec 012).
///
/// This is the seam the Go API replaces later; nothing here is persisted or
/// sent anywhere.
class HomeStore extends ChangeNotifier {
  List<Home> _homes = const [];
  List<HomeInvite> _invites = const [];
  String? _activeId;
  final Map<String, String> _deviceZones = {};
  final Map<String, String> _deviceNames = {};
  int _nextId = 0;

  List<Home> get homes => List.unmodifiable(_homes);
  List<HomeInvite> get invites => List.unmodifiable(_invites);
  bool get hasHome => _homes.isNotEmpty;
  Home? get activeHome =>
      _homes.where((home) => home.id == _activeId).firstOrNull ??
      _homes.firstOrNull;

  /// The seeded demo account: a connected home, a second owned home and one
  /// pending invitation.
  void loadDemoAccount({required String yourName, required String yourPhone}) {
    final you = Member(
      id: 'you',
      name: yourName,
      phone: yourPhone,
      role: HomeRole.owner,
      canUnlock: true,
      isYou: true,
    );
    _homes = [
      Home(
        id: 'home-ladprao',
        name: 'บ้านลาดพร้าว',
        role: HomeRole.owner,
        connected: true,
        zones: [
          for (final key in const [
            'Living room',
            'Bedroom',
            'Kitchen',
            'Front yard',
          ])
            Zone(id: 'zone-$key', presetKey: key),
        ],
        members: [
          you,
          const Member(
            id: 'member-ton',
            name: 'ต้น',
            phone: '0861112233',
            role: HomeRole.admin,
            canUnlock: true,
          ),
          const Member(
            id: 'member-pending',
            phone: '0891234521',
            role: HomeRole.member,
            pending: true,
          ),
        ],
      ),
      Home(
        id: 'home-condo',
        name: 'คอนโดสามย่าน',
        role: HomeRole.owner,
        previewDeviceCount: 3,
        zones: const [
          Zone(id: 'condo-living', presetKey: 'Living room'),
          Zone(id: 'condo-bedroom', presetKey: 'Bedroom'),
        ],
        members: [you],
      ),
    ];
    _invites = _parentsInvite;
    _activeId = _homes.first.id;
    notifyListeners();
  }

  /// A new account starts with no home and one invitation waiting.
  void startNewAccount() {
    _homes = const [];
    _invites = _parentsInvite;
    _activeId = null;
    notifyListeners();
  }

  void reset() {
    _homes = const [];
    _invites = const [];
    _activeId = null;
    _deviceZones.clear();
    _deviceNames.clear();
    notifyListeners();
  }

  void switchHome(String id) {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }

  /// Creates a home with the chosen zones and makes it active. The first home
  /// created is the one the lighting provider is connected to.
  Home createHome({
    required String name,
    required List<String> presetKeys,
    required List<String> customZones,
    required Member owner,
  }) {
    final home = Home(
      id: _id('home'),
      name: name.trim(),
      role: HomeRole.owner,
      connected: !_homes.any((home) => home.connected),
      zones: [
        for (final key in presetKeys) Zone(id: _id('zone'), presetKey: key),
        for (final custom in customZones)
          Zone(id: _id('zone'), customName: custom.trim()),
      ],
      members: [owner],
    );
    _homes = [..._homes, home];
    _activeId = home.id;
    notifyListeners();
    return home;
  }

  void acceptInvite(String inviteId, Member you) {
    final invite = _invites.where((item) => item.id == inviteId).firstOrNull;
    if (invite == null) return;
    final home = Home(
      id: _id('home'),
      name: invite.homeName,
      role: invite.role,
      previewDeviceCount: invite.deviceCount,
      invitedBy: invite.invitedBy,
      zones: [
        for (final key in invite.zoneKeys)
          Zone(id: _id('zone'), presetKey: key),
      ],
      members: [
        Member(
          id: _id('member'),
          name: invite.invitedBy,
          phone: '',
          role: HomeRole.owner,
          canUnlock: true,
        ),
        Member(
          id: you.id,
          name: you.name,
          phone: you.phone,
          role: invite.role,
          isYou: true,
        ),
      ],
    );
    _homes = [..._homes, home];
    _invites = _invites.where((item) => item.id != inviteId).toList();
    _activeId = home.id;
    notifyListeners();
  }

  void declineInvite(String inviteId) {
    _invites = _invites.where((item) => item.id != inviteId).toList();
    notifyListeners();
  }

  void renameActiveHome(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _updateActive((home) => home.copyWith(name: trimmed));
  }

  Zone? addZone(String name) {
    final trimmed = name.trim();
    final home = activeHome;
    if (trimmed.isEmpty || home == null) return null;
    final zone = Zone(id: _id('zone'), customName: trimmed);
    _updateActive((home) => home.copyWith(zones: [...home.zones, zone]));
    return zone;
  }

  void inviteMember({
    required String phone,
    required HomeRole role,
    required bool canUnlock,
  }) {
    final member = Member(
      id: _id('member'),
      phone: phone,
      role: role,
      canUnlock: canUnlock,
      pending: true,
    );
    _updateActive((home) => home.copyWith(members: [...home.members, member]));
  }

  /// Only preview homes can be deleted; the connected home owns real devices.
  bool canDeleteActive() {
    final home = activeHome;
    return home != null &&
        !home.connected &&
        home.role == HomeRole.owner &&
        _homes.length > 1;
  }

  void deleteActiveHome() {
    if (!canDeleteActive()) return;
    _homes = _homes.where((home) => home.id != activeHome!.id).toList();
    _activeId = _homes.first.id;
    notifyListeners();
  }

  /// Zone of a light: local assignment first, then the provider room.
  String? zoneIdFor(LightDevice device) {
    final home = activeHome;
    if (home == null) return null;
    final assigned = _deviceZones[device.id];
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

  /// A name typed after pairing. It is local only and never sent to Tuya.
  String? customDeviceName(String deviceId) => _deviceNames[deviceId];

  void labelDevice(String deviceId, {String? name, String? zoneId}) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) _deviceNames[deviceId] = trimmed;
    if (zoneId != null) _deviceZones[deviceId] = zoneId;
    notifyListeners();
  }

  void _updateActive(Home Function(Home home) update) {
    final active = activeHome;
    if (active == null) return;
    _homes = [
      for (final home in _homes) home.id == active.id ? update(home) : home,
    ];
    notifyListeners();
  }

  String _id(String prefix) => '$prefix-${_nextId++}';

  static const _parentsInvite = [
    HomeInvite(
      id: 'invite-parents',
      homeName: 'บ้านพ่อแม่',
      invitedBy: 'คุณแม่',
      role: HomeRole.member,
      zoneKeys: ['Living room', 'Bedroom', 'Kitchen'],
      deviceCount: 4,
      expiresInDays: 6,
    ),
  ];
}
