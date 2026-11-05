part of '../app_localizations.dart';

/// The Me tab.
extension AccountStrings on AppLocalizations {
  String get editName => _t('Edit name', 'แก้ไขชื่อ');
  String get homesSection => _t('Homes', 'บ้าน');
  String homeCount(int count) =>
      _t('$count ${count == 1 ? 'home' : 'homes'}', '$count หลัง');
  String get homeInvites => _t('Home invitations', 'คำเชิญเข้าบ้าน');
  String get usageSection => _t('Using the app', 'การใช้งาน');
  String get theme => _t('Theme', 'ธีม');
  String get followSystem => _t('Match system', 'ตามระบบ');
  String get doorAlerts => _t('Door notifications', 'การแจ้งเตือนประตู');
  String get doorAlertsPreview => _t(
    'Preview — no notifications are sent yet',
    'ตัวอย่าง ยังไม่มีการส่งแจ้งเตือนจริง',
  );
  String get signOut => _t('Sign out', 'ออกจากระบบ');
  String get signOutQuestion => _t('Sign out of JAVIS?', 'ออกจากระบบ JAVIS?');
  String get appVersion => 'JAVIS 1.0 (MVP)';
}
