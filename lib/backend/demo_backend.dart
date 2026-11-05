import '../features/home/home_models.dart';
import '../features/scenes/scene_models.dart';
import 'backend_failure.dart';
import 'javis_backend.dart';

/// The offline demo: sample data on this device and no network. No SMS is sent;
/// any six digits other than `000000` are accepted so the error state can still
/// be previewed.
class DemoBackend implements JavisBackend {
  DemoBackend({this.networkDelay = const Duration(milliseconds: 700)});

  /// The demo number that already has an account and homes.
  static const demoPhone = '0812345678';
  static const demoName = 'มายด์';

  final Duration networkDelay;
  final Set<String> _knownPhones = {demoPhone, '0861112233', '0891234521'};
  late final List<Scene> _scenes = _seedScenes(DateTime.now());
  String? _phone;
  String? _name;
  bool _hasConnectedHome = false;
  int _nextId = 0;

  String _id(String prefix) => '$prefix-${_nextId++}';

  @override
  bool get isDemo => true;

  @override
  set onSessionExpired(void Function()? callback) {}

  @override
  Future<OtpChallenge> requestCode(String phone) async {
    await Future<void>.delayed(networkDelay);
    return const OtpChallenge(resendAfter: Duration(seconds: 45));
  }

  @override
  Future<AccountUser> verifyCode(String phone, String code) async {
    await Future<void>.delayed(networkDelay);
    if (code.length != 6 || code == '000000') {
      throw const BackendFailure('invalid_code');
    }
    _phone = phone;
    _name = phone == demoPhone ? demoName : null;
    return AccountUser(id: 'you', phone: phone, name: _name);
  }

  @override
  Future<AccountUser?> restoreSession() async => null;

  @override
  Future<AccountUser> updateName(String name) async {
    _name = name;
    return AccountUser(id: 'you', phone: _phone ?? demoPhone, name: name);
  }

  @override
  Future<void> signOut() async {}

  /// The signed-in demo account, ready without waiting.
  AccountHomes demoAccount() {
    _phone = demoPhone;
    _name = demoName;
    _hasConnectedHome = true;
    final you = _you(HomeRole.owner);
    return AccountHomes(
      invites: const [_parentsInvite],
      homes: [
        Home(
          id: 'home-ladprao',
          name: 'บ้านลาดพร้าว',
          role: HomeRole.owner,
          canUnlock: true,
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
              phone: '',
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
          canUnlock: true,
          previewDeviceCount: 3,
          zones: const [
            Zone(id: 'condo-living', presetKey: 'Living room'),
            Zone(id: 'condo-bedroom', presetKey: 'Bedroom'),
          ],
          members: [you],
        ),
      ],
    );
  }

  Member _you(HomeRole role) => Member(
    id: 'you',
    name: _name,
    phone: '',
    role: role,
    canUnlock: role == HomeRole.owner,
    isYou: true,
  );

  @override
  Future<AccountHomes> loadHomes() async => _phone == demoPhone
      ? demoAccount()
      : const AccountHomes(homes: [], invites: [_parentsInvite]);

  /// The first home created is the one the lighting provider is connected to.
  @override
  Future<Home> createHome({
    required String name,
    required List<String> presetKeys,
    required List<String> customZones,
  }) async {
    final connected = !_hasConnectedHome;
    _hasConnectedHome = true;
    return Home(
      id: _id('home'),
      name: name,
      role: HomeRole.owner,
      canUnlock: true,
      connected: connected,
      zones: [
        for (final key in presetKeys) Zone(id: _id('zone'), presetKey: key),
        for (final custom in customZones)
          Zone(id: _id('zone'), customName: custom),
      ],
      members: [_you(HomeRole.owner)],
    );
  }

  @override
  Future<void> renameHome(String homeId, String name) async {}

  @override
  Future<void> deleteHome(String homeId) async {}

  @override
  Future<Zone> addZone(String homeId, String name) async =>
      Zone(id: _id('zone'), customName: name);

  @override
  Future<Member> inviteMember(
    String homeId, {
    required String phone,
    required HomeRole role,
    required bool canUnlock,
  }) async {
    if (!_knownPhones.add(phone)) throw const BackendFailure('already_member');
    return Member(
      id: _id('member'),
      phone: phone,
      role: role,
      canUnlock: canUnlock,
      pending: true,
    );
  }

  @override
  Future<void> revokeInvite(String homeId, String inviteId) async {}

  @override
  Future<void> updateMember(
    String homeId,
    String userId, {
    HomeRole? role,
    bool? canUnlock,
  }) async {}

  @override
  Future<void> removeMember(String homeId, String userId) async {}

  @override
  Future<Home> acceptInvite(HomeInvite invite) async => Home(
    id: _id('home'),
    name: invite.homeName,
    role: invite.role,
    previewDeviceCount: invite.deviceCount ?? 0,
    invitedBy: invite.invitedBy,
    zones: [
      for (final key in invite.zoneKeys) Zone(id: _id('zone'), presetKey: key),
    ],
    members: [
      Member(
        id: _id('member'),
        name: invite.invitedBy,
        phone: '',
        role: HomeRole.owner,
        canUnlock: true,
      ),
      _you(invite.role),
    ],
  );

  @override
  Future<void> declineInvite(String inviteId) async {}

  @override
  Future<HomeDevice> claimDevice(String homeId, String externalRef) async =>
      HomeDevice(id: _id('device'), externalRef: externalRef);

  @override
  Future<HomeDevice> updateDevice(
    String homeId,
    String deviceId, {
    String? name,
    String? zoneId,
  }) async => HomeDevice(
    id: deviceId,
    externalRef: deviceId,
    name: name,
    zoneId: zoneId,
  );

  @override
  Future<void> removeDevice(String homeId, String deviceId) async {}

  /// The demo has one list of scenes shared by its homes.
  List<Scene> get scenes => List.unmodifiable(_scenes);

  @override
  Future<List<Scene>> loadScenes(String homeId) async => scenes;

  @override
  Future<Scene> createScene(String homeId, Scene scene) async {
    final saved = scene.withId(_id('scene'));
    _scenes.add(saved);
    return saved;
  }

  @override
  Future<Scene> updateScene(String homeId, Scene scene) async {
    final index = _scenes.indexWhere((item) => item.id == scene.id);
    if (index >= 0) _scenes[index] = scene;
    return scene;
  }

  @override
  Future<void> deleteScene(String homeId, String sceneId) async =>
      _scenes.removeWhere((scene) => scene.id == sceneId);

  @override
  Future<DateTime> recordSceneRun(String homeId, String sceneId) async {
    final now = DateTime.now();
    final index = _scenes.indexWhere((item) => item.id == sceneId);
    if (index >= 0) _scenes[index] = _scenes[index].copyWith(lastRun: now);
    return now;
  }

  static const _parentsInvite = HomeInvite(
    id: 'invite-parents',
    homeName: 'บ้านพ่อแม่',
    invitedBy: 'คุณแม่',
    role: HomeRole.member,
    zoneCount: 3,
    zoneKeys: ['Living room', 'Bedroom', 'Kitchen'],
    deviceCount: 4,
    expiresInDays: 6,
  );
}

List<Scene> _seedScenes(DateTime now) => [
  Scene(
    id: 'scene-sleep',
    presetKey: 'Sleep',
    icon: SceneIcon.moon,
    lastRun: DateTime(now.year, now.month, now.day - 1, 23, 10),
    actions: const [
      LightAction(
        target: LightTarget.device('bedside-lamp'),
        isOn: true,
        brightness: .1,
        temperature: 2700,
      ),
      LightAction(target: LightTarget.others(), isOn: false),
      LockCheckAction(),
    ],
  ),
  const Scene(
    id: 'scene-home',
    presetKey: 'Welcome home',
    icon: SceneIcon.home,
    actions: [
      LightAction(
        target: LightTarget.zone('Living room'),
        isOn: true,
        brightness: .8,
        temperature: 3000,
      ),
      LightAction(target: LightTarget.zone('Front yard'), isOn: true),
    ],
  ),
  const Scene(
    id: 'scene-leave',
    presetKey: 'Leave home',
    icon: SceneIcon.leave,
    actions: [
      LightAction(target: LightTarget.all(), isOn: false),
      LockCheckAction(),
    ],
  ),
  const Scene(
    id: 'scene-wake',
    presetKey: 'Wake up',
    icon: SceneIcon.sunrise,
    actions: [
      LightAction(
        target: LightTarget.zone('Bedroom'),
        isOn: true,
        brightness: .6,
        temperature: 4500,
      ),
    ],
  ),
];
