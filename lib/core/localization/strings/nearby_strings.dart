part of '../app_localizations.dart';

/// Bluetooth nearby-device pairing (spec 013).
extension NearbyStrings on AppLocalizations {
  String get nearbyTitle => _t('Lights nearby.', 'หลอดไฟใกล้ตัว');
  String get nearbyIntro => _t(
    'Put the bulb in pairing mode so it blinks. JAVIS finds it over Bluetooth, and your iPhone stays on home Wi-Fi.',
    'ให้หลอดไฟเข้าโหมดจับคู่จนกะพริบ JAVIS จะค้นหาผ่าน Bluetooth โดย iPhone ยังต่อ Wi-Fi บ้านตามเดิม',
  );
  String get nearbySearching =>
      _t('Looking for lights nearby…', 'กำลังค้นหาหลอดไฟใกล้ตัว…');
  String get nearbySearchingHint => _t(
    'Keep the bulb blinking and your phone close to it.',
    'ให้หลอดกะพริบไว้ และถือมือถือไว้ใกล้หลอด',
  );
  String get nearbyFoundTitle =>
      _t('A new light is nearby.', 'พบหลอดไฟใหม่ใกล้ตัว');
  String get nearbyFoundBody => _t(
    'Choose it to connect it to your home Wi-Fi.',
    'เลือกหลอดไฟเพื่อเชื่อมต่อกับ Wi-Fi บ้าน',
  );
  String nearbyLight(int number) =>
      _t('New light $number', 'หลอดไฟใหม่ $number');
  String get nearbyReady => _t('Ready to connect', 'พร้อมเชื่อมต่อ');
  String get nearbySelected => _t(
    'Light selected. Enter your home Wi-Fi so it can join.',
    'เลือกหลอดไฟแล้ว กรอก Wi-Fi บ้านเพื่อให้หลอดเข้าร่วม',
  );
  String get bluetoothOff => _t(
    'Bluetooth is off. Turn it on in Control Center or Settings, and JAVIS will keep looking.',
    'Bluetooth ปิดอยู่ เปิด Bluetooth จากศูนย์ควบคุมหรือการตั้งค่า แล้ว JAVIS จะค้นหาต่อให้',
  );
  String get bluetoothDenied => _t(
    'JAVIS is not allowed to use Bluetooth. Turn it on in Settings → JAVIS Home → Bluetooth.',
    'JAVIS ยังไม่ได้รับอนุญาตให้ใช้ Bluetooth เปิดได้ที่การตั้งค่า → JAVIS Home → Bluetooth',
  );
  String get bluetoothUnsupported => _t(
    'Bluetooth is not available on this device. Set up with Wi-Fi instead.',
    'อุปกรณ์นี้ใช้ Bluetooth ไม่ได้ ให้ตั้งค่าผ่าน Wi-Fi แทน',
  );
  String get useWifiSetup =>
      _t('Can’t find it? Set up with Wi-Fi', 'หาไม่เจอ? ตั้งค่าผ่าน Wi-Fi');
  String get useNearbySetup =>
      _t('Find nearby with Bluetooth', 'ค้นหาใกล้ตัวด้วย Bluetooth');
  String get chooseAnotherLight =>
      _t('Choose another light', 'เลือกหลอดไฟดวงอื่น');
  String get nearbyRetryTip => _t(
    'Keep the bulb blinking and close to your phone, and check the 2.4 GHz Wi-Fi password. Then search again.',
    'ให้หลอดกะพริบและอยู่ใกล้มือถือ ตรวจรหัสผ่าน Wi-Fi 2.4 GHz แล้วค้นหาอีกครั้ง',
  );
  String get deviceNotReady => _t(
    'The light is no longer in pairing mode. Reset it until it blinks, then search again.',
    'หลอดไฟไม่ได้อยู่ในโหมดจับคู่แล้ว รีเซ็ตจนหลอดกะพริบ แล้วค้นหาอีกครั้ง',
  );
}
