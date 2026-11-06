part of '../app_localizations.dart';

/// Bluetooth nearby-device pairing (spec 013).
extension NearbyStrings on AppLocalizations {
  String get nearbyTitle => _t('Find devices nearby.', 'ค้นหาอุปกรณ์ใกล้ตัว');
  String get nearbyIntro => _t(
    'Put your device in pairing mode and keep your phone close.',
    'ให้อุปกรณ์เข้าโหมดจับคู่ แล้ววางมือถือไว้ใกล้ ๆ',
  );
  String get nearbySearching =>
      _t('Looking for devices nearby…', 'กำลังค้นหาอุปกรณ์ใกล้ตัว…');
  String get nearbySearchingHint => _t(
    'Not showing up? Reset the device until its light blinks, or check its manual.',
    'ยังไม่ขึ้นใช่ไหม รีเซ็ตอุปกรณ์จนไฟกะพริบ หรือดูวิธีในคู่มือ',
  );
  String nearbyFoundCount(int count) => _t(
    count == 1
        ? '1 device found · still looking'
        : '$count devices found · still looking',
    'พบ $count อุปกรณ์ · ยังค้นหาต่อ',
  );
  String nearbyDeviceNumbered(int number) =>
      _t('New device $number', 'อุปกรณ์ใหม่ $number');
  String get nearbyAdd => _t('Add', 'เพิ่ม');
  String get nearbyReady => _t('Ready to connect', 'พร้อมเชื่อมต่อ');
  String get nearbySelected => _t(
    'Device selected. Enter your home Wi-Fi so it can join.',
    'เลือกอุปกรณ์แล้ว กรอก Wi-Fi บ้านเพื่อให้อุปกรณ์เชื่อมต่อ',
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
  String get chooseAnotherDevice =>
      _t('Choose another device', 'เลือกอุปกรณ์อื่น');
  String get connectDevice => _t('Connect device', 'เชื่อมต่ออุปกรณ์');
  String get nearbyRetryTip => _t(
    'Keep the device in pairing mode and close to your phone, and check the 2.4 GHz Wi-Fi password. Then search again.',
    'ให้อุปกรณ์อยู่ในโหมดจับคู่และอยู่ใกล้มือถือ ตรวจสอบรหัส Wi-Fi 2.4 GHz แล้วค้นหาอีกครั้ง',
  );
  String get deviceNotReady => _t(
    'The device is no longer in pairing mode. Reset it, then search again.',
    'อุปกรณ์ไม่ได้อยู่ในโหมดจับคู่แล้ว รีเซ็ตอุปกรณ์ แล้วค้นหาอีกครั้ง',
  );
}
