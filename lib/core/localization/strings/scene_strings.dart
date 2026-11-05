part of '../app_localizations.dart';

/// Scenes list and editor.
extension SceneStrings on AppLocalizations {
  String scenePreset(String key) => switch (key) {
    'Sleep' => _t('Sleep', 'โหมดนอน'),
    'Welcome home' => _t('Welcome home', 'กลับถึงบ้าน'),
    'Leave home' => _t('Leave home', 'ออกจากบ้าน'),
    'Wake up' => _t('Wake up', 'ตื่นนอน'),
    _ => key,
  };
  String sceneRan(String name) => _t('$name is on', 'เริ่ม $name แล้ว');
  String get scenesSubtitle => _t(
    'One tap sets several devices at once.',
    'แตะครั้งเดียว สั่งหลายอุปกรณ์พร้อมกัน',
  );
  String get newScene => _t('New scene', 'ฉากใหม่');
  String get editScene => _t('Edit scene', 'แก้ไขฉาก');
  String editSceneNamed(String name) =>
      _t('Edit scene: $name', 'แก้ไขฉาก: $name');
  String get startSceneShort => _t('Start', 'เริ่ม');
  String startScene(String name) => _t('Start $name', 'เริ่ม $name');
  String actionCount(int count) =>
      _t('$count ${count == 1 ? 'action' : 'actions'}', '$count การทำงาน');
  String lastUsed(DateTime at, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final days = today.difference(day).inDays;
    final time = clock(at);
    if (days == 0) return _t('Last used today $time', 'ใช้ล่าสุดวันนี้ $time');
    if (days == 1) {
      return at.hour >= 18
          ? _t('Last used last night $time', 'ใช้ล่าสุดเมื่อคืน $time')
          : _t('Last used yesterday $time', 'ใช้ล่าสุดเมื่อวาน $time');
    }
    return _t('Last used $days days ago', 'ใช้ล่าสุด $days วันก่อน');
  }

  String get noActionsYet => _t('No actions yet', 'ยังไม่มีการทำงาน');
  String get sceneName => _t('Scene name', 'ชื่อฉาก');
  String get sceneNameHint => _t('e.g. Movie night', 'เช่น ดูหนัง');
  String get whenSceneStarts =>
      _t('When this scene starts', 'เมื่อเริ่มฉากนี้');
  String get addAction => _t('Add action', 'เพิ่มการทำงาน');
  String removeAction(String target) => _t('Remove $target', 'ลบ $target');
  String get startSceneFrom => _t('Start this scene from', 'เริ่มฉากได้จาก');
  String get tapInApp => _t('Tap in the app', 'แตะในแอป');
  String sayPhrase(String name) => _t('Say “$name”', 'พูดว่า “$name”');
  String get voicePreviewOnly => _t(
    'Voice start is a preview and is not active yet.',
    'การเริ่มด้วยเสียงเป็นตัวอย่าง ยังใช้งานไม่ได้',
  );
  String get deleteScene => _t('Delete this scene', 'ลบฉากนี้');
  String deleteSceneQuestion(String name) => _t('Delete $name?', 'ลบ $name?');
  String get lightsSection => _t('Lights', 'ไฟ');
  String get allLights => _t('All lights', 'ไฟทุกดวง');
  String get otherLights => _t('All other lights', 'ไฟอื่นทั้งหมด');
  String get otherLightsHint =>
      _t('Lights this scene has not set yet', 'ไฟที่ฉากนี้ยังไม่ได้ตั้งค่า');
  String targetOff(String target) => _t('$target off', 'ปิด $target');
  String get lockCheckShort =>
      _t('Check the door is locked', 'เช็กว่าประตูล็อก');
  String get lockCheckDetail => _t(
    'Check status · alert if not locked',
    'เช็กสถานะ · แจ้งเตือนถ้ายังไม่ล็อก',
  );
}
