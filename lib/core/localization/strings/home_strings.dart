part of '../app_localizations.dart';

/// Dashboard, zones, home switcher, home settings and member invites.
extension HomeStrings on AppLocalizations {
  String switchHomeLabel(String home) =>
      _t('$home, switch home', '$home, สลับบ้าน');
  String get voiceControl => _t('Voice control', 'สั่งด้วยเสียง');
  String lightsOn(int count) => count == 0
      ? _t('All lights off', 'ปิดไฟทุกดวง')
      : _t(
          '$count ${count == 1 ? 'light' : 'lights'} on',
          'เปิดไฟอยู่ $count ดวง',
        );
  String get doorLocked => _t('Front door locked', 'ประตูหน้าล็อกอยู่');
  String get doorUnlocked => _t('Front door unlocked', 'ประตูหน้าไม่ได้ล็อก');
  String openZone(String zone) => _t('Open $zone', 'เปิด $zone');
  String get noLightsYet => _t(
    'No lights in this home yet. Add one to get started.',
    'บ้านนี้ยังไม่มีหลอดไฟ เพิ่มหลอดแรกได้เลย',
  );
  String get noLightsInZone =>
      _t('No lights in this zone yet.', 'โซนนี้ยังไม่มีหลอดไฟ');
  String get previewHomeTitle => _t('Preview home', 'บ้านตัวอย่าง');
  String previewHomeBody(int count) => _t(
    'This home is sample data with $count ${count == 1 ? 'device' : 'devices'}. '
        'Lights you pair appear in your first home only.',
    'บ้านนี้เป็นข้อมูลตัวอย่าง ($count อุปกรณ์) '
        'หลอดไฟที่เชื่อมต่อจะแสดงในบ้านหลังแรกเท่านั้น',
  );
  String get demoLightsNote => _t(
    'These are sample lights. Changes stay in the app and do not control a real device.',
    'นี่คือหลอดไฟตัวอย่าง การเปลี่ยนแปลงอยู่ในแอปเท่านั้น ไม่ได้สั่งอุปกรณ์จริง',
  );
  String get myHomes => _t('My homes', 'บ้านของฉัน');
  String inviteFrom(String name, String home) =>
      _t('$name invited you to $home', '$name ชวนคุณเข้า $home');
  String get addHome => _t('Add a home', 'เพิ่มบ้าน');
  String settingsFor(String home) => _t('Settings for $home', 'ตั้งค่า $home');
  String memberInvitedBy(String role, String name) =>
      _t('$role · invited by $name', '$role · $name เชิญ');
  String get editZones => _t('Edit zones', 'แก้ไขโซน');
  String onOfLights(int on, int total) =>
      _t('$on of $total on', 'เปิด $on จาก $total ดวง');
  String get turnAllOff => _t('All off', 'ปิดทั้งหมด');
  String get scenesUsingZone => _t('Scenes in this zone', 'ฉากที่ใช้โซนนี้');
  String addDeviceTo(String zone) =>
      _t('Add a device to $zone', 'เพิ่มอุปกรณ์ใน $zone');

  String get homeSettings => _t('Home settings', 'ตั้งค่าบ้าน');
  String get renameHome => _t('Rename home', 'เปลี่ยนชื่อบ้าน');
  String zonesCount(int count) => _t('Zones · $count', 'โซน · $count');
  String get addZone => _t('Add zone', 'เพิ่มโซน');
  String deviceCount(int count) =>
      _t('$count ${count == 1 ? 'device' : 'devices'}', '$count อุปกรณ์');
  String membersCount(int count) => _t('Members · $count', 'สมาชิก · $count');
  String get inviteMember => _t('Invite', 'เชิญสมาชิก');
  String youSuffix(String name) => _t('$name (you)', '$name (คุณ)');
  String get invitePending => _t('Invitation pending', 'รอตอบรับคำเชิญ');
  String get deleteHome => _t('Delete this home', 'ลบบ้านนี้');
  String deleteHomeQuestion(String home) => _t('Delete $home?', 'ลบ $home?');
  String get deleteHomeBody => _t(
    'Its zones, members and scenes are removed for everyone.',
    'โซน สมาชิก และฉากของบ้านนี้จะถูกลบสำหรับทุกคน',
  );

  String get inviteTitle => _t('Invite someone home', 'ชวนคนในบ้าน');
  String inviteSubtitle(String home) => _t(
    'Add them to $home with their mobile number.',
    'เชิญเข้า $home ด้วยเบอร์มือถือ',
  );
  String get yourRoleLabel => _t('Role', 'บทบาท');
  String roleDescription(String key) => switch (key) {
    'admin' => _t(
      'Can add devices, edit zones and scenes, and invite others.',
      'เพิ่มอุปกรณ์ จัดโซน ฉาก และเชิญคนอื่นได้',
    ),
    _ => _t(
      'Uses lights and scenes and sees the door status.',
      'ใช้ไฟ ฉาก และดูสถานะประตู',
    ),
  };
  String get allowUnlock =>
      _t('Allow unlocking the door', 'อนุญาตให้ปลดล็อกประตู');
  String get allowUnlockHint =>
      _t('You can turn this on later.', 'ปิดไว้ก่อนได้ เปิดทีหลังได้');
  String get inviteSeenOnSignIn => _t(
    'They see the invitation as soon as they sign in with this number.',
    'เมื่อเขาเข้าสู่ระบบด้วยเบอร์นี้ จะเห็นคำเชิญทันที',
  );
  String get sendInvite => _t('Send invitation', 'ส่งคำเชิญ');
  String get alreadyMember =>
      _t('This number is already in this home.', 'เบอร์นี้อยู่ในบ้านนี้แล้ว');
  String get inviteSaved => _t(
    'Invitation added. They’ll see it when they sign in.',
    'เพิ่มคำเชิญแล้ว เขาจะเห็นเมื่อเข้าสู่ระบบ',
  );

  String get voiceTryExamples => _t(
    'Try: “Turn off every light” · “Sleep mode”',
    'ลองพูด: “ปิดไฟทั้งบ้าน” · “โหมดนอน”',
  );
  String get voiceNoUnlock => _t(
    'For safety, the door can’t be unlocked by voice.',
    'ปลดล็อกประตูด้วยเสียงไม่ได้ เพื่อความปลอดภัย',
  );
  String get voiceExamplePhrase => _t(
    '“Turn on the bedroom lights, half brightness”',
    '“เปิดไฟห้องนอน หรี่ลงครึ่งหนึ่ง”',
  );
  String get voiceExampleTarget => _t('Bedroom · 2 lights', 'ห้องนอน · 2 ดวง');
  String get voiceExampleResult =>
      _t('On · 50% brightness', 'เปิด · ความสว่าง 50%');
  String get voiceNotInPreview => _t(
    'Voice control is not in this preview. Nothing is listening and the example above does not change any light.',
    'ยังไม่มีการสั่งด้วยเสียงในเวอร์ชันตัวอย่างนี้ แอปไม่ได้ฟังเสียง และตัวอย่างด้านบนไม่ได้เปลี่ยนไฟดวงใด',
  );
}
