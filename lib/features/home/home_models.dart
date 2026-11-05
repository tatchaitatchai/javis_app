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

  final String id;
  final String phone;
  final HomeRole role;
  final String? name;
  final bool pending;
  final bool canUnlock;
  final bool isYou;
}

@immutable
class Home {
  const Home({
    required this.id,
    required this.name,
    required this.role,
    required this.zones,
    required this.members,
    this.connected = false,
    this.previewDeviceCount = 0,
    this.invitedBy,
  });

  final String id;
  final String name;
  final HomeRole role;
  final List<Zone> zones;
  final List<Member> members;

  /// Only the connected home shows the lighting provider's bulbs and the lock
  /// in this UI-only phase (spec 012). Other homes are preview data.
  final bool connected;
  final int previewDeviceCount;
  final String? invitedBy;

  bool get canManage => role != HomeRole.member;

  Home copyWith({
    String? name,
    List<Zone>? zones,
    List<Member>? members,
    bool? connected,
  }) => Home(
    id: id,
    name: name ?? this.name,
    role: role,
    zones: zones ?? this.zones,
    members: members ?? this.members,
    connected: connected ?? this.connected,
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
    required this.zoneKeys,
    required this.deviceCount,
    required this.expiresInDays,
  });

  final String id;
  final String homeName;
  final String invitedBy;
  final HomeRole role;
  final List<String> zoneKeys;
  final int deviceCount;
  final int expiresInDays;
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
