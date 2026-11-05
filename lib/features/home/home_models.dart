import 'package:flutter/foundation.dart';

import '../../core/localization/app_localizations.dart';

enum HomeRole { owner, admin, member }

/// A zone is either an app preset (translated) or a name the user typed
/// (shown exactly as written).
@immutable
class Zone {
  const Zone({required this.id, this.presetKey, this.customName = ''});

  final String id;
  final String? presetKey;
  final String customName;

  String label(AppLocalizations l10n) =>
      presetKey == null ? customName : l10n.room(presetKey!);

  /// Whether a provider room string refers to this zone.
  bool matchesRoom(String room) =>
      room.isNotEmpty && (room == presetKey || room == customName);
}

@immutable
class Member {
  const Member({
    required this.id,
    required this.phone,
    required this.role,
    this.name,
    this.pending = false,
    this.canUnlock = false,
    this.isYou = false,
  });

  /// The user id, or the invitation id while [pending].
  final String id;

  /// Shown only while [pending]. Joined members' numbers stay private.
  final String phone;
  final HomeRole role;
  final String? name;
  final bool pending;
  final bool canUnlock;
  final bool isYou;

  Member copyWith({HomeRole? role, bool? canUnlock}) => Member(
    id: id,
    phone: phone,
    role: role ?? this.role,
    name: name,
    pending: pending,
    canUnlock: canUnlock ?? this.canUnlock,
    isYou: isYou,
  );
}

/// A device registered to a home. Live state stays with the provider.
@immutable
class HomeDevice {
  const HomeDevice({
    required this.id,
    required this.externalRef,
    this.name,
    this.zoneId,
  });

  final String id;

  /// The provider's device id, `LightDevice.id`.
  final String externalRef;
  final String? name;
  final String? zoneId;
}

@immutable
class Home {
  const Home({
    required this.id,
    required this.name,
    required this.role,
    required this.zones,
    required this.members,
    this.canUnlock = false,
    this.connected = false,
    this.devices = const [],
    this.previewDeviceCount = 0,
    this.invitedBy,
  });

  final String id;
  final String name;
  final HomeRole role;
  final List<Zone> zones;
  final List<Member> members;

  /// Whether the signed-in person may unlock this home's door.
  final bool canUnlock;

  /// Whether this home shows real lights and the lock. Every API home does;
  /// in the demo only the first one does and the others are sample data.
  final bool connected;
  final List<HomeDevice> devices;
  final int previewDeviceCount;
  final String? invitedBy;

  bool get canManage => role != HomeRole.member;
  bool get isOwner => role == HomeRole.owner;

  Home copyWith({
    String? name,
    List<Zone>? zones,
    List<Member>? members,
    List<HomeDevice>? devices,
  }) => Home(
    id: id,
    name: name ?? this.name,
    role: role,
    zones: zones ?? this.zones,
    members: members ?? this.members,
    canUnlock: canUnlock,
    connected: connected,
    devices: devices ?? this.devices,
    previewDeviceCount: previewDeviceCount,
    invitedBy: invitedBy,
  );
}

@immutable
class HomeInvite {
  const HomeInvite({
    required this.id,
    required this.homeName,
    required this.invitedBy,
    required this.role,
    required this.zoneCount,
    required this.expiresInDays,
    this.zoneKeys = const [],
    this.deviceCount,
  });

  final String id;
  final String homeName;
  final String? invitedBy;
  final HomeRole role;
  final int zoneCount;
  final int expiresInDays;

  /// Demo only: the API does not reveal a home before joining it.
  final List<String> zoneKeys;
  final int? deviceCount;
}

/// Preset zone keys offered when setting up a home, in display order.
const zonePresetKeys = [
  'Living room',
  'Bedroom',
  'Kitchen',
  'Front yard',
  'Office',
  'Bathroom',
  'Kids room',
];
