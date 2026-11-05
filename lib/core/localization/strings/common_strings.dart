part of '../app_localizations.dart';

/// Words shared by many screens and the app shell.
extension CommonStrings on AppLocalizations {
  String get back => _t('Back', 'ย้อนกลับ');
  String get close => _t('Close', 'ปิด');
  String get next => _t('Next', 'ต่อไป');
  String get confirm => _t('Confirm', 'ยืนยัน');
  String get save => _t('Save', 'บันทึก');
  String get done => _t('Done', 'เสร็จสิ้น');
  String get edit => _t('Edit', 'แก้ไข');
  String get decline => _t('Decline', 'ปฏิเสธ');
  String get all => _t('All', 'ทั้งหมด');
  String get preview => _t('Preview', 'ตัวอย่าง');
  String get delete => _t('Delete', 'ลบ');
  String get none => _t('None', 'ไม่มี');
  String stepOf(int current, int total) =>
      _t('Step $current of $total', 'ขั้นที่ $current จาก $total');
  String get homeTab => _t('Home', 'หน้าแรก');
  String get scenesTab => _t('Scenes', 'ฉาก');
  String get meTab => _t('Me', 'ฉัน');
  String get mainMenu => _t('Main menu', 'เมนูหลัก');
  String role(String key) => switch (key) {
    'owner' => _t('Owner', 'เจ้าของ'),
    'admin' => _t('Admin', 'ผู้ดูแล'),
    _ => _t('Member', 'สมาชิก'),
  };
  String zonesAndDevices(int zones, int devices) => _t(
    '$zones ${zones == 1 ? 'zone' : 'zones'} · $devices ${devices == 1 ? 'device' : 'devices'}',
    '$zones โซน · $devices อุปกรณ์',
  );
  String inDays(int days) =>
      _t('In $days ${days == 1 ? 'day' : 'days'}', 'อีก $days วัน');
  String clock(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
