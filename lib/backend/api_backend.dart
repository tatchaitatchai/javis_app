import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../features/home/home_models.dart';
import '../features/scenes/scene_models.dart';
import 'api_client.dart';
import 'backend_failure.dart';
import 'javis_backend.dart';
import 'session_vault.dart';

/// [JavisBackend] on the Go API. See `javis_api/api/openapi.yaml`.
class ApiBackend implements JavisBackend {
  ApiBackend(this._api, this._vault) {
    _api.onUnauthorized = _expire;
  }

  final ApiClient _api;
  final SessionVault _vault;
  VoidCallback? _onSessionExpired;
  String? _userId;

  @override
  bool get isDemo => false;

  @override
  set onSessionExpired(VoidCallback? callback) => _onSessionExpired = callback;

  void _expire() {
    if (_api.token == null) return;
    _api.token = null;
    _userId = null;
    _forgetToken();
    _onSessionExpired?.call();
  }

  /// A Keychain error must not hide the outcome the user is waiting for: the
  /// token is already gone from memory and the server has rejected it.
  Future<void> _forgetToken() async {
    try {
      await _vault.clear();
    } on PlatformException catch (error) {
      debugPrint('Session vault clear failed: ${error.code}');
    }
  }

  @override
  Future<OtpChallenge> requestCode(String phone) async {
    final json = await _api.post('/v1/auth/otp/request', {
      'phone': _e164(phone),
    });
    return OtpChallenge(
      resendAfter: Duration(seconds: json['resend_after_seconds'] as int),
      debugCode: json['debug_code'] as String?,
    );
  }

  @override
  Future<AccountUser> verifyCode(String phone, String code) async {
    final json = await _api.post('/v1/auth/otp/verify', {
      'phone': _e164(phone),
      'code': code,
    });
    final token = json['token'] as String;
    _api.token = token;
    try {
      await _vault.write(token);
    } on PlatformException {
      // Signed in for this launch; the next launch asks for a code again.
      debugPrint('Session vault write failed');
    }
    return _user(json['user'] as Json);
  }

  @override
  Future<AccountUser?> restoreSession() async {
    final String? token;
    try {
      token = await _vault.read();
    } on PlatformException {
      return null;
    }
    if (token == null) return null;
    _api.token = token;
    try {
      return _user(await _api.get('/v1/me'));
    } on BackendFailure catch (failure) {
      if (failure.code == 'unauthorized') return null;
      rethrow;
    }
  }

  @override
  Future<AccountUser> updateName(String name) async =>
      _user(await _api.patch('/v1/me', {'name': name}));

  /// Sign-out always succeeds on this device. If the request fails, the
  /// session ends on the server when it expires.
  @override
  Future<void> signOut() async {
    final hadSession = _api.token != null;
    try {
      if (hadSession) await _api.post('/v1/auth/logout');
    } on BackendFailure catch (failure) {
      debugPrint('Sign-out request failed: ${failure.code}');
    }
    _api.token = null;
    _userId = null;
    await _forgetToken();
  }

  @override
  Future<AccountHomes> loadHomes() async {
    final results = await Future.wait([
      _api.get('/v1/homes'),
      _api.get('/v1/me/invites'),
    ]);
    final summaries = _items(results[0]);
    final homes = await Future.wait([
      for (final summary in summaries) _home(summary['id'] as String),
    ]);
    return AccountHomes(
      homes: homes,
      invites: [for (final json in _items(results[1])) _receivedInvite(json)],
    );
  }

  Future<Home> _home(String id) async {
    final results = await Future.wait([
      _api.get('/v1/homes/$id'),
      _api.get('/v1/homes/$id/members'),
      _api.get('/v1/homes/$id/devices'),
    ]);
    return _homeFrom(results[0], results[1], results[2]);
  }

  Home _homeFrom(Json home, Json members, Json devices) => Home(
    id: home['id'] as String,
    name: home['name'] as String,
    role: HomeRole.values.byName(home['role'] as String),
    canUnlock: home['can_unlock'] as bool,
    connected: true,
    zones: [
      for (final zone in (home['zones'] as List).cast<Json>()) _zone(zone),
    ],
    members: [
      for (final json in (members['members'] as List).cast<Json>())
        Member(
          id: json['user_id'] as String,
          phone: '',
          name: json['name'] as String?,
          role: HomeRole.values.byName(json['role'] as String),
          canUnlock: json['can_unlock'] as bool,
          isYou: json['user_id'] == _userId,
        ),
      for (final json in (members['invites'] as List).cast<Json>())
        _pendingMember(json),
    ],
    devices: [for (final json in _items(devices)) _device(json)],
  );

  @override
  Future<Home> createHome({
    required String name,
    required List<String> presetKeys,
    required List<String> customZones,
  }) async {
    final json = await _api.post('/v1/homes', {
      'name': name,
      'zones': [
        for (final key in presetKeys) {'preset_key': key},
        for (final custom in customZones) {'name': custom},
      ],
    });
    return _home(json['id'] as String);
  }

  @override
  Future<void> renameHome(String homeId, String name) =>
      _api.patch('/v1/homes/$homeId', {'name': name});

  @override
  Future<void> deleteHome(String homeId) => _api.delete('/v1/homes/$homeId');

  @override
  Future<Zone> addZone(String homeId, String name) async =>
      _zone(await _api.post('/v1/homes/$homeId/zones', {'name': name}));

  @override
  Future<Member> inviteMember(
    String homeId, {
    required String phone,
    required HomeRole role,
    required bool canUnlock,
  }) async => _pendingMember(
    await _api.post('/v1/homes/$homeId/invites', {
      'phone': _e164(phone),
      'role': role.name,
      'can_unlock': canUnlock,
    }),
  );

  @override
  Future<void> revokeInvite(String homeId, String inviteId) =>
      _api.delete('/v1/homes/$homeId/invites/$inviteId');

  @override
  Future<void> updateMember(
    String homeId,
    String userId, {
    HomeRole? role,
    bool? canUnlock,
  }) => _api.patch('/v1/homes/$homeId/members/$userId', {
    'role': ?role?.name,
    'can_unlock': ?canUnlock,
  });

  @override
  Future<void> removeMember(String homeId, String userId) =>
      _api.delete('/v1/homes/$homeId/members/$userId');

  @override
  Future<Home> acceptInvite(HomeInvite invite) async {
    final json = await _api.post('/v1/me/invites/${invite.id}/accept');
    return _home(json['id'] as String);
  }

  @override
  Future<void> declineInvite(String inviteId) =>
      _api.post('/v1/me/invites/$inviteId/decline');

  @override
  Future<HomeDevice> claimDevice(String homeId, String externalRef) async =>
      _device(
        await _api.post('/v1/homes/$homeId/devices', {
          'provider': 'tuya',
          'external_ref': externalRef,
          'kind': 'light',
        }),
      );

  @override
  Future<HomeDevice> updateDevice(
    String homeId,
    String deviceId, {
    String? name,
    String? zoneId,
  }) async => _device(
    await _api.patch('/v1/homes/$homeId/devices/$deviceId', {
      'name': ?name,
      'zone_id': ?zoneId,
    }),
  );

  @override
  Future<void> removeDevice(String homeId, String deviceId) =>
      _api.delete('/v1/homes/$homeId/devices/$deviceId');

  @override
  Future<List<Scene>> loadScenes(String homeId) async => [
    for (final json in _items(await _api.get('/v1/homes/$homeId/scenes')))
      _scene(json),
  ];

  @override
  Future<Scene> createScene(String homeId, Scene scene) async =>
      _scene(await _api.post('/v1/homes/$homeId/scenes', _sceneInput(scene)));

  @override
  Future<Scene> updateScene(String homeId, Scene scene) async => _scene(
    await _api.put('/v1/homes/$homeId/scenes/${scene.id}', _sceneInput(scene)),
  );

  @override
  Future<void> deleteScene(String homeId, String sceneId) =>
      _api.delete('/v1/homes/$homeId/scenes/$sceneId');

  @override
  Future<DateTime> recordSceneRun(String homeId, String sceneId) async {
    final json = await _api.post('/v1/homes/$homeId/scenes/$sceneId/runs');
    return DateTime.parse(json['last_run_at'] as String).toLocal();
  }

  AccountUser _user(Json json) {
    final id = json['id'] as String;
    _userId = id;
    final phone = json['phone'] as String;
    return AccountUser(
      id: id,
      phone: '0${phone.substring(3)}',
      name: json['name'] as String?,
    );
  }

  Member _pendingMember(Json json) => Member(
    id: json['id'] as String,
    phone: json['phone_masked'] as String,
    role: HomeRole.values.byName(json['role'] as String),
    canUnlock: json['can_unlock'] as bool,
    pending: true,
  );
}

List<Json> _items(Json json) => (json['items'] as List).cast<Json>();

/// `0812345678` → `+66812345678`.
String _e164(String phone) => '+66${phone.substring(1)}';

Zone _zone(Json json) => Zone(
  id: json['id'] as String,
  presetKey: json['preset_key'] as String?,
  customName: json['name'] as String? ?? '',
);

HomeDevice _device(Json json) => HomeDevice(
  id: json['id'] as String,
  externalRef: json['external_ref'] as String,
  name: json['name'] as String?,
  zoneId: json['zone_id'] as String?,
);

HomeInvite _receivedInvite(Json json) {
  final left = DateTime.parse(json['expires_at'] as String)
      .difference(DateTime.now());
  return HomeInvite(
    id: json['id'] as String,
    homeName: json['home_name'] as String,
    invitedBy: json['invited_by_name'] as String?,
    role: HomeRole.values.byName(json['role'] as String),
    zoneCount: json['zone_count'] as int,
    expiresInDays: math.max(1, (left.inHours / 24).ceil()),
  );
}

Scene _scene(Json json) => Scene(
  id: json['id'] as String,
  icon: SceneIcon.values.asNameMap()[json['icon']] ?? SceneIcon.sparkle,
  presetKey: json['preset_key'] as String?,
  customName: json['name'] as String? ?? '',
  lastRun: switch (json['last_run_at']) {
    final String time => DateTime.parse(time).toLocal(),
    _ => null,
  },
  actions: [
    for (final action in (json['actions'] as List).cast<Json>())
      _action(action),
  ],
);

SceneAction _action(Json json) {
  if (json['type'] == 'lock_check') return const LockCheckAction();
  final target = json['target'] as Json;
  final key = target['key'] as String? ?? '';
  return LightAction(
    target: switch (target['kind']) {
      'device' => LightTarget.device(key),
      'zone' => LightTarget.zone(key),
      'others' => const LightTarget.others(),
      _ => const LightTarget.all(),
    },
    isOn: json['is_on'] as bool,
    brightness: (json['brightness'] as num?)?.toDouble(),
    temperature: json['temperature'] as int?,
  );
}

Json _sceneInput(Scene scene) => {
  'icon': scene.icon.name,
  if (scene.presetKey case final key?)
    'preset_key': key
  else
    'name': scene.customName,
  'actions': [
    for (final action in scene.actions)
      switch (action) {
        LockCheckAction() => {'type': 'lock_check'},
        LightAction() => {
          'type': 'light',
          'target': {
            'kind': action.target.kind.name,
            if (action.target.key.isNotEmpty) 'key': action.target.key,
          },
          'is_on': action.isOn,
          'brightness': ?action.brightness,
          'temperature': ?action.temperature,
        },
      },
  ],
};
