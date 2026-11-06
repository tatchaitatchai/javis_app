part of '../app_localizations.dart';

/// Light cards and controls, the lock, and adding a device.
extension DeviceStrings on AppLocalizations {
  String get online => _t('Online', 'ออนไลน์');
  String get notResponding => _t('Not responding', 'ไม่ตอบสนอง');
  String powerOf(String name) => _t('$name power', 'เปิดปิด $name');
  String get hue => _t('Color', 'สี');
  String get saturation => _t('Saturation', 'ความเข้มสี');
  String temperatureFeel(int kelvin) => kelvin < 3500
      ? _t('Warm', 'โทนอุ่น')
      : kelvin < 5000
      ? _t('Neutral', 'โทนกลาง')
      : _t('Cool', 'โทนขาว');
  String lightPreset(String key) => switch (key) {
    'Reading' => _t('Reading', 'อ่านหนังสือ'),
    'Relax' => _t('Relax', 'ผ่อนคลาย'),
    'Bright' => _t('Bright', 'สว่าง'),
    'Night' => _t('Night', 'กลางคืน'),
    _ => key,
  };

  String get frontDoor => _t('Front door', 'ประตูหน้าบ้าน');
  String lockStatus(String key) => switch (key) {
    'unlocking' => _t('Unlocking…', 'กำลังปลดล็อก…'),
    'unlocked' => _t('Unlocked', 'ปลดล็อกอยู่'),
    _ => _t('Locked', 'ล็อกอยู่'),
  };
  String battery(int percent) => _t('Battery $percent%', 'แบตเตอรี่ $percent%');
  String get unlock => _t('Unlock', 'ปลดล็อก');
  String unlockQuestion(String door) =>
      _t('Unlock the $door?', 'ปลดล็อก$door?');
  String get unlockRelocks => _t(
    'It locks again by itself after 10 seconds.',
    'กลอนจะล็อกเองอีกครั้งหลัง 10 วินาที',
  );
  String get slideToUnlock => _t('Slide to unlock', 'เลื่อนเพื่อปลดล็อก');
  String get faceIdNotInPreview => _t(
    'Face ID confirmation is not in this preview.',
    'การยืนยันด้วย Face ID ยังไม่มีในเวอร์ชันตัวอย่างนี้',
  );
  String get unlockReportedOnly => _t(
    'The door shows “Unlocked” only after the lock reports back. This preview uses a simulated lock.',
    'แอปจะแสดง “ปลดล็อกอยู่” เมื่อกลอนตอบกลับแล้วเท่านั้น เวอร์ชันนี้ใช้กลอนจำลอง',
  );
  String get lockPreviewNote => _t(
    'Preview lock — this does not open a real door.',
    'กลอนตัวอย่าง ไม่ได้เปิดประตูจริง',
  );
  String get relocksAutomatically =>
      _t('Locks again automatically', 'จะล็อกเองอัตโนมัติ');
  String get unlockDoor => _t('Unlock door', 'ปลดล็อกประตู');
  String updatedAgo(Duration age) => age.inMinutes < 1
      ? _t('Updated just now', 'อัปเดตเมื่อสักครู่')
      : age.inHours < 1
      ? _t(
          'Updated ${age.inMinutes} min ago',
          'อัปเดต ${age.inMinutes} นาทีก่อน',
        )
      : _t('Updated ${age.inHours} h ago', 'อัปเดต ${age.inHours} ชม. ก่อน');
  String get door => _t('Door', 'ประตู');
  String get doorClosed => _t('Closed', 'ปิดอยู่');
  String get doorOpen => _t('Open', 'เปิดอยู่');
  String get batteryLabel => _t('Battery', 'แบตเตอรี่');
  String get autoLock => _t('Auto-lock', 'ล็อกอัตโนมัติ');
  String get autoLockHint =>
      _t('Locks 10 seconds after unlocking', 'ล็อกเองหลังปลดล็อก 10 วินาที');
  String get recentActivity => _t('Recent activity', 'กิจกรรมล่าสุด');
  String lockEvent(String event, String actor) => switch (event) {
    'unlockedInApp' => _t(
      '$actor unlocked in the app',
      '$actor ปลดล็อกผ่านแอป',
    ),
    'unlockedFingerprint' => _t(
      '$actor unlocked with fingerprint',
      '$actor ปลดล็อกด้วยลายนิ้วมือ',
    ),
    _ => _t('Locked automatically', 'ล็อกอัตโนมัติ'),
  };

  String get stepSendWifi =>
      _t('Send home Wi-Fi to the device', 'ส่ง Wi-Fi บ้านให้อุปกรณ์');
  String get stepWaitOnline =>
      _t('Wait for the device to come online', 'รออุปกรณ์ออนไลน์');
  String stepAddToHome(String home) => _t('Add to $home', 'เพิ่มเข้า $home');
  String get band24 => _t('2.4 GHz', '2.4 GHz');
  String get wifi24Only => _t(
    'Bulbs only join 2.4 GHz Wi-Fi. A 5 GHz-only network won’t work.',
    'หลอดไฟใช้ได้เฉพาะ Wi-Fi 2.4 GHz เครือข่าย 5 GHz อย่างเดียวจะเชื่อมต่อไม่ได้',
  );
  String get deviceName => _t('Device name', 'ชื่ออุปกรณ์');
  String get whichZone => _t('Which zone?', 'อยู่โซนไหน');
  String get nameStaysLocal => _t(
    'The name and zone are saved in this app.',
    'ชื่อและโซนจะบันทึกไว้ในแอปนี้',
  );
  String get addNextLight => _t('Add another light', 'เพิ่มหลอดถัดไป');
}
