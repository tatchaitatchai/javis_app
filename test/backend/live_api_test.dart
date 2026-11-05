import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/backend/api_backend.dart';
import 'package:javis_app/backend/api_client.dart';
import 'package:javis_app/backend/backend_failure.dart';
import 'package:javis_app/backend/session_vault.dart';
import 'package:javis_app/features/home/home_models.dart';
import 'package:javis_app/features/scenes/scene_models.dart';

/// Runs the app's real backend code against a running API in OTP debug mode.
/// It writes data, so point it at a throwaway database:
///
/// flutter test test/backend/live_api_test.dart
///   --dart-define=JAVIS_LIVE_API_URL=http://127.0.0.1:8082
const _url = String.fromEnvironment('JAVIS_LIVE_API_URL');

class _MemoryVault implements SessionVault {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

ApiBackend _client([SessionVault? vault]) =>
    ApiBackend(ApiClient(Uri.parse(_url)), vault ?? _MemoryVault());

String _randomPhone() =>
    '08${Random().nextInt(100000000).toString().padLeft(8, '0')}';

Future<ApiBackend> _signIn(String phone, String name, [SessionVault? vault]) =>
    () async {
      final backend = _client(vault);
      final challenge = await backend.requestCode(phone);
      expect(challenge.debugCode, hasLength(6));
      final user = await backend.verifyCode(phone, challenge.debugCode!);
      expect(user.phone, phone);
      await backend.updateName(name);
      return backend;
    }();

Matcher _fails(String code) => throwsA(
  isA<BackendFailure>().having((failure) => failure.code, 'code', code),
);

void main() {
  test(
    'the whole household flow works against the real API',
    skip: _url.isEmpty ? 'Needs --dart-define=JAVIS_LIVE_API_URL' : null,
    () async {
      final ownerVault = _MemoryVault();
      final ownerPhone = _randomPhone();
      final memberPhone = _randomPhone();
      final owner = await _signIn(ownerPhone, 'Owner', ownerVault);

      // Home and zones.
      final home = await owner.createHome(
        name: 'บ้านทดสอบ',
        presetKeys: ['Bedroom', 'Living room'],
        customZones: ['ห้องหนังสือ'],
      );
      expect(home.role, HomeRole.owner);
      expect(home.canUnlock, isTrue);
      expect(home.connected, isTrue);
      expect(home.zones.first.presetKey, 'Bedroom');
      expect(home.zones.last.customName, 'ห้องหนังสือ');
      expect(home.members.single.isYou, isTrue);
      await owner.renameHome(home.id, 'บ้านใหม่');
      final zone = await owner.addZone(home.id, 'ห้องเก็บของ');
      expect(zone.customName, 'ห้องเก็บของ');
      final loaded = await owner.loadHomes();
      expect(loaded.homes.single.name, 'บ้านใหม่');
      expect(loaded.homes.single.zones, hasLength(4));

      // Default scenes round-trip through the app's model.
      final scenes = await owner.loadScenes(home.id);
      expect(scenes.map((scene) => scene.presetKey), [
        'Sleep',
        'Welcome home',
        'Leave home',
        'Wake up',
      ]);
      expect(scenes.first.actions.last, isA<LockCheckAction>());
      final updated = await owner.updateScene(home.id, scenes.first);
      expect(updated.actions, hasLength(scenes.first.actions.length));

      // Invitation.
      final pending = await owner.inviteMember(
        home.id,
        phone: memberPhone,
        role: HomeRole.admin,
        canUnlock: true,
      );
      expect(pending.pending, isTrue);
      expect(pending.phone, contains('xxx'));
      await expectLater(
        owner.inviteMember(
          home.id,
          phone: memberPhone,
          role: HomeRole.member,
          canUnlock: false,
        ),
        _fails('already_invited'),
      );

      final member = await _signIn(memberPhone, 'Member');
      final invites = (await member.loadHomes()).invites;
      expect(invites.single.homeName, 'บ้านใหม่');
      expect(invites.single.invitedBy, 'Owner');
      expect(invites.single.zoneCount, 4);
      expect(invites.single.expiresInDays, inInclusiveRange(1, 7));
      final joined = await member.acceptInvite(invites.single);
      expect(joined.role, HomeRole.admin);
      expect(joined.canUnlock, isTrue);
      final you = joined.members.singleWhere((item) => item.isYou);
      expect(you.name, 'Member');

      // The owner sets rights; the member sees them.
      await owner.updateMember(
        home.id,
        you.id,
        role: HomeRole.member,
        canUnlock: false,
      );
      final after = (await member.loadHomes()).homes.single;
      expect(after.role, HomeRole.member);
      expect(after.canUnlock, isFalse);

      // A member uses scenes but cannot change them or add devices.
      await expectLater(
        member.createScene(home.id, scenes.first.copyWith()),
        _fails('forbidden'),
      );
      await expectLater(member.claimDevice(home.id, 'x'), _fails('forbidden'));
      await expectLater(member.renameHome(home.id, 'x'), _fails('forbidden'));
      final ranAt = await member.recordSceneRun(home.id, scenes.first.id);
      expect(DateTime.now().difference(ranAt).inMinutes, 0);
      final seen = await owner.loadScenes(home.id);
      expect(seen.first.lastRun, isNotNull);

      // A custom scene.
      const draft = Scene(
        id: 'scene-new-0',
        icon: SceneIcon.sparkle,
        customName: 'Movie night',
        actions: [
          LightAction(
            target: LightTarget.zone('Living room'),
            isOn: true,
            brightness: .3,
            temperature: 2700,
          ),
          LightAction(target: LightTarget.device('bulb-1'), isOn: false),
          LightAction(target: LightTarget.others(), isOn: false),
          LightAction(target: LightTarget.all(), isOn: false),
          LockCheckAction(),
        ],
      );
      final created = await owner.createScene(home.id, draft);
      expect(created.customName, 'Movie night');
      expect(created.presetKey, isNull);
      final first = created.actions.first as LightAction;
      expect(first.target.key, 'Living room');
      expect(first.brightness, .3);
      expect(first.temperature, 2700);
      expect(
        (created.actions[1] as LightAction).target.kind,
        LightTargetKind.device,
      );
      final renamed = await owner.updateScene(
        home.id,
        created.copyWith(customName: 'Late'),
      );
      expect(renamed.customName, 'Late');
      await owner.deleteScene(home.id, created.id);
      await expectLater(
        owner.deleteScene(home.id, created.id),
        _fails('scene_not_found'),
      );

      // A device blocks deleting its home, and belongs to one home only.
      final ref = 'bulb-${Random().nextInt(1 << 32)}';
      final device = await owner.claimDevice(home.id, ref);
      final again = await owner.claimDevice(home.id, ref);
      expect(again.id, device.id);
      final labelled = await owner.updateDevice(
        home.id,
        device.id,
        name: 'Lamp',
        zoneId: zone.id,
      );
      expect(labelled.name, 'Lamp');
      expect(labelled.zoneId, zone.id);
      final second = await owner.createHome(
        name: 'บ้านสอง',
        presetKeys: ['Office'],
        customZones: [],
      );
      await expectLater(
        owner.claimDevice(second.id, ref),
        _fails('device_claimed'),
      );
      await expectLater(owner.deleteHome(home.id), _fails('home_has_devices'));
      await owner.removeDevice(home.id, device.id);

      // Decline, revoke, leave, remove.
      final thirdPhone = _randomPhone();
      await owner.inviteMember(
        second.id,
        phone: memberPhone,
        role: HomeRole.member,
        canUnlock: false,
      );
      final declined = (await member.loadHomes()).invites.single;
      await member.declineInvite(declined.id);
      expect((await member.loadHomes()).invites, isEmpty);
      final revoked = await owner.inviteMember(
        second.id,
        phone: thirdPhone,
        role: HomeRole.member,
        canUnlock: false,
      );
      await owner.revokeInvite(second.id, revoked.id);
      await member.removeMember(home.id, you.id);
      expect((await member.loadHomes()).homes, isEmpty);

      // A stored session reopens, and sign-out ends it on the server.
      final reopened = _client(ownerVault);
      final user = await reopened.restoreSession();
      expect(user?.name, 'Owner');
      expect(
        (await reopened.loadHomes()).homes.first.members.first.isYou,
        true,
      );
      final copy = _MemoryVault()..token = ownerVault.token;
      await reopened.signOut();
      expect(ownerVault.token, isNull);
      expect(await _client(copy).restoreSession(), isNull);
      expect(copy.token, isNull);

      await expectLater(
        _client().verifyCode(ownerPhone, '000000'),
        _fails('invalid_code'),
      );
    },
  );
}
