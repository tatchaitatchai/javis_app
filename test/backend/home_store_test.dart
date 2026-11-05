import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/backend/backend_failure.dart';
import 'package:javis_app/backend/demo_backend.dart';
import 'package:javis_app/backend/javis_backend.dart';
import 'package:javis_app/features/home/home_models.dart';
import 'package:javis_app/features/home/home_store.dart';
import 'package:javis_app/features/lighting/lighting_service.dart';

/// The API's behaviour where the store depends on it, on top of the demo.
class _ServerBackend extends DemoBackend {
  _ServerBackend() : super(networkDelay: Duration.zero);

  final foreign = <String>{};
  final claimed = <String>[];
  final updates = <(String?, String?)>[];
  final removed = <String>[];
  BackendFailure? failNext;

  void _maybeFail() {
    final failure = failNext;
    failNext = null;
    if (failure != null) throw failure;
  }

  @override
  bool get isDemo => false;

  @override
  Future<void> renameHome(String homeId, String name) async => _maybeFail();

  @override
  Future<void> updateMember(
    String homeId,
    String userId, {
    HomeRole? role,
    bool? canUnlock,
  }) async => _maybeFail();

  @override
  Future<HomeDevice> claimDevice(String homeId, String externalRef) async {
    _maybeFail();
    if (foreign.contains(externalRef)) {
      throw const BackendFailure('device_claimed');
    }
    claimed.add(externalRef);
    return HomeDevice(id: 'id-$externalRef', externalRef: externalRef);
  }

  @override
  Future<HomeDevice> updateDevice(
    String homeId,
    String deviceId, {
    String? name,
    String? zoneId,
  }) async {
    updates.add((name, zoneId));
    return HomeDevice(
      id: deviceId,
      externalRef: deviceId.replaceFirst('id-', ''),
      name: name,
      zoneId: zoneId,
    );
  }

  @override
  Future<void> removeDevice(String homeId, String deviceId) async =>
      removed.add(deviceId);
}

class _Lights extends ChangeNotifier implements LightingService {
  _Lights(List<String> ids, {this.demo = false})
    : devices = [for (final id in ids) _light(id)];

  final bool demo;

  @override
  final List<LightDevice> devices;

  @override
  bool get isDemo => demo;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LightDevice _light(String id) => LightDevice(
  id: id,
  name: id,
  room: '',
  isOn: true,
  brightness: 1,
  temperature: 3000,
  online: true,
  capabilities: const LightCapabilities(power: true),
);

Member _you(HomeRole role) => Member(
  id: 'you',
  phone: '',
  role: role,
  canUnlock: role == HomeRole.owner,
  isYou: true,
);

Home _home(
  String id, {
  HomeRole role = HomeRole.owner,
  List<HomeDevice> devices = const [],
  List<Member>? members,
}) => Home(
  id: id,
  name: id,
  role: role,
  zones: const [Zone(id: 'zone-1', presetKey: 'Bedroom')],
  members: members ?? [_you(role)],
  connected: true,
  devices: devices,
);

HomeStore _store(_ServerBackend backend, List<Home> homes) =>
    HomeStore(backend)..adopt(AccountHomes(homes: homes, invites: const []));

void main() {
  late _ServerBackend backend;

  setUp(() => backend = _ServerBackend());

  test('a home shows only the lights in its registry', () {
    final store = _store(backend, [
      _home(
        'a',
        devices: const [HomeDevice(id: 'id-1', externalRef: 'bulb-1')],
      ),
    ]);
    final lights = store.lightsIn(_Lights(['bulb-1', 'bulb-2']));
    expect(lights.map((light) => light.id), ['bulb-1']);
  });

  test('demo lights are not registered and show in every home', () async {
    final store = _store(backend, [_home('a')]);
    final lights = _Lights(['bedside'], demo: true);
    expect(store.lightsIn(lights), hasLength(1));
    await store.claimNewLights(lights);
    expect(backend.claimed, isEmpty);
  });

  test('new lights are claimed, known and foreign ones are not', () async {
    backend.foreign.add('theirs');
    final store = _store(backend, [
      _home(
        'a',
        devices: const [HomeDevice(id: 'id-1', externalRef: 'known')],
      ),
    ]);
    final lights = _Lights(['known', 'new', 'theirs']);
    await store.claimNewLights(lights);
    expect(backend.claimed, ['new']);
    expect(
      store.lightsIn(lights).map((light) => light.id),
      unorderedEquals(['known', 'new']),
    );

    backend.claimed.clear();
    await store.claimNewLights(lights);
    expect(backend.claimed, isEmpty, reason: 'foreign is remembered');
  });

  test('a light in another of my homes is not claimed again', () async {
    final store = _store(backend, [
      _home('a'),
      _home(
        'b',
        devices: const [HomeDevice(id: 'id-1', externalRef: 'bulb')],
      ),
    ]);
    await store.claimNewLights(_Lights(['bulb']));
    expect(backend.claimed, isEmpty);
  });

  test('a member never claims', () async {
    final store = _store(backend, [_home('a', role: HomeRole.member)]);
    await store.claimNewLights(_Lights(['bulb']));
    expect(backend.claimed, isEmpty);
  });

  test('an outage stops the sweep and it retries next time', () async {
    final store = _store(backend, [_home('a')]);
    final lights = _Lights(['one', 'two']);
    backend.failNext = const BackendFailure(BackendFailure.offline);
    await store.claimNewLights(lights);
    expect(backend.claimed, isEmpty);
    await store.claimNewLights(lights);
    expect(backend.claimed, ['one', 'two']);
  });

  test('labelling claims first, then saves name and zone', () async {
    final store = _store(backend, [_home('a')]);
    final lights = _Lights(['bulb']);
    await store.labelDevice(lights, 'bulb', name: 'Lamp', zoneId: 'zone-1');
    expect(backend.claimed, ['bulb']);
    expect(backend.updates, [('Lamp', 'zone-1')]);
    expect(store.customDeviceName('bulb'), 'Lamp');
    expect(store.zoneIdFor(_light('bulb')), 'zone-1');
  });

  test('forgetting a light removes it from the registry', () async {
    final store = _store(backend, [
      _home(
        'a',
        devices: const [HomeDevice(id: 'id-1', externalRef: 'bulb')],
      ),
    ]);
    await store.forgetDevice(_Lights(['bulb']), 'bulb');
    expect(backend.removed, ['id-1']);
    expect(store.activeHome!.devices, isEmpty);
  });

  test('a home with devices cannot be deleted', () {
    final device = const HomeDevice(id: 'id-1', externalRef: 'bulb');
    final full = _store(backend, [
      _home('a', devices: [device]),
      _home('b'),
    ]);
    expect(full.canDeleteActive(), isFalse);
    expect(_store(backend, [_home('a'), _home('b')]).canDeleteActive(), isTrue);
    expect(_store(backend, [_home('a')]).canDeleteActive(), isFalse);
  });

  test('a refused rename goes back to the old name', () async {
    final store = _store(backend, [_home('a')]);
    backend.failNext = const BackendFailure('forbidden');
    final rename = store.renameActiveHome('New name');
    expect(store.activeHome!.name, 'New name', reason: 'shows at once');
    await expectLater(rename, throwsA(isA<BackendFailure>()));
    expect(store.activeHome!.name, 'a');
  });

  test('a refused unlock right goes back', () async {
    const friend = Member(id: 'm', phone: '', role: HomeRole.member);
    final store = _store(backend, [
      _home('a', members: [_you(HomeRole.owner), friend]),
    ]);
    backend.failNext = const BackendFailure('forbidden');
    await expectLater(
      store.updateMember(friend, canUnlock: true),
      throwsA(isA<BackendFailure>()),
    );
    expect(store.activeHome!.members.last.canUnlock, isFalse);
  });

  group('who can be removed', () {
    const admin = Member(id: 'a', phone: '', role: HomeRole.admin);
    const member = Member(id: 'm', phone: '', role: HomeRole.member);
    const invite = Member(
      id: 'i',
      phone: '',
      role: HomeRole.member,
      pending: true,
    );

    test('owner removes anyone but themselves', () {
      final you = _you(HomeRole.owner);
      final store = _store(backend, [
        _home('a', members: [you, admin, member]),
      ]);
      expect(store.canRemove(admin), isTrue);
      expect(store.canRemove(member), isTrue);
      expect(store.canRemove(you), isFalse);
      expect(store.canLeaveActive, isFalse);
    });

    test('admin removes members and invites, not admins', () {
      final store = _store(backend, [_home('a', role: HomeRole.admin)]);
      expect(store.canRemove(member), isTrue);
      expect(store.canRemove(invite), isTrue);
      expect(store.canRemove(admin), isFalse);
      expect(store.canLeaveActive, isTrue);
    });

    test('member removes nobody and can leave', () {
      final store = _store(backend, [_home('a', role: HomeRole.member)]);
      expect(store.canRemove(member), isFalse);
      expect(store.canRemove(invite), isFalse);
      expect(store.canLeaveActive, isTrue);
    });
  });

  test('leaving moves to another home', () async {
    final store = _store(backend, [
      _home('a', role: HomeRole.member),
      _home('b'),
    ]);
    await store.leaveActiveHome();
    expect(store.homes.map((home) => home.id), ['b']);
    expect(store.activeHome!.id, 'b');
  });
}
