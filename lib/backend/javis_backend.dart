import 'package:flutter/foundation.dart';

import '../features/home/home_models.dart';
import '../features/scenes/scene_models.dart';

@immutable
class AccountUser {
  const AccountUser({required this.id, required this.phone, this.name});

  final String id;

  /// Local form, `0XXXXXXXXX`.
  final String phone;
  final String? name;
}

@immutable
class OtpChallenge {
  const OtpChallenge({required this.resendAfter, this.debugCode});

  final Duration resendAfter;

  /// The code itself, only while no SMS provider is connected.
  final String? debugCode;
}

@immutable
class AccountHomes {
  const AccountHomes({required this.homes, required this.invites});

  final List<Home> homes;
  final List<HomeInvite> invites;
}

/// Everything the app needs from its server. Calls throw `BackendFailure`.
abstract interface class JavisBackend {
  bool get isDemo;

  /// Called when the server no longer accepts this session.
  set onSessionExpired(VoidCallback? callback);

  Future<OtpChallenge> requestCode(String phone);
  Future<AccountUser> verifyCode(String phone, String code);

  /// The signed-in user of a stored session, or null when there is none.
  Future<AccountUser?> restoreSession();
  Future<AccountUser> updateName(String name);
  Future<void> signOut();

  Future<AccountHomes> loadHomes();
  Future<Home> createHome({
    required String name,
    required List<String> presetKeys,
    required List<String> customZones,
  });
  Future<void> renameHome(String homeId, String name);
  Future<void> deleteHome(String homeId);
  Future<Zone> addZone(String homeId, String name);

  /// Returns the pending [Member] shown until the invitation is answered.
  Future<Member> inviteMember(
    String homeId, {
    required String phone,
    required HomeRole role,
    required bool canUnlock,
  });
  Future<void> revokeInvite(String homeId, String inviteId);
  Future<void> updateMember(
    String homeId,
    String userId, {
    HomeRole? role,
    bool? canUnlock,
  });

  /// Removes someone, or the caller when leaving the home.
  Future<void> removeMember(String homeId, String userId);
  Future<Home> acceptInvite(HomeInvite invite);
  Future<void> declineInvite(String inviteId);

  Future<HomeDevice> claimDevice(String homeId, String externalRef);
  Future<HomeDevice> updateDevice(
    String homeId,
    String deviceId, {
    String? name,
    String? zoneId,
  });
  Future<void> removeDevice(String homeId, String deviceId);

  Future<List<Scene>> loadScenes(String homeId);
  Future<Scene> createScene(String homeId, Scene scene);
  Future<Scene> updateScene(String homeId, Scene scene);
  Future<void> deleteScene(String homeId, String sceneId);

  /// Records that a scene ran and returns the recorded time.
  Future<DateTime> recordSceneRun(String homeId, String sceneId);
}
