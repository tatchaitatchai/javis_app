import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

part 'strings/common_strings.dart';
part 'strings/onboarding_strings.dart';
part 'strings/home_strings.dart';
part 'strings/device_strings.dart';
part 'strings/nearby_strings.dart';
part 'strings/scene_strings.dart';
part 'strings/account_strings.dart';

/// Small typed catalog: every message has both languages at the same call site.
/// Demo identifiers stay in the service; only presentation is translated.
class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  bool get isThai => locale.languageCode == 'th';
  String _t(String english, String thai) => isThai ? thai : english;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = [Locale('en'), Locale('th')];

  String get home => _t('Home', 'บ้าน');
  String get rooms => _t('Rooms', 'ห้อง');
  String get scenes => _t('Scenes', 'บรรยากาศ');
  String get language => _t('Language', 'ภาษา');
  String get chooseLanguage =>
      _t('Make yourself at home.', 'เลือกภาษาที่คุ้นเคย');
  String get harmony => _t('Your home, in harmony', 'บ้านที่ลงตัว ในแบบคุณ');
  String get addDevice => _t('Add device', 'เพิ่มอุปกรณ์');
  String get greeting => _t(
    'A little softer.\nA little more home.',
    'ผ่อนคลายอีกนิด\nให้บ้านเป็นบ้านยิ่งขึ้น',
  );
  String get calmerMoment =>
      _t('Make room for a calmer moment.', 'เติมช่วงเวลาสบาย ๆ ให้บ้านของคุณ');
  String get atmosphere => _t('Just the right atmosphere', 'บรรยากาศที่พอดี');
  String homeSummary(int active) => _t(
    '$active lights on · 3 rooms · Demo home',
    'เปิดไฟ $active ดวง · 3 ห้อง · บ้านตัวอย่าง',
  );
  String get yourSpaces => _t('Your spaces', 'พื้นที่ของคุณ');
  String get viewAll => _t('View all', 'ดูทั้งหมด');
  String get warmEvenings =>
      _t('Warm light. Quiet evenings.', 'แสงอบอุ่น ในค่ำคืนที่เงียบสงบ');
  String get changeMood => _t('A change of mood', 'เปลี่ยนอารมณ์ให้บ้าน');
  String get yourLighting => _t('Your lighting', 'แสงไฟของคุณ');
  String get understandsYou =>
      _t('A home that understands you.', 'บ้านที่เข้าใจคุณ');
  String get aiDescription => _t(
    'Voice and AI assistance are part of the JAVIS vision. For this prototype, explore rooms, scenes, and manual lighting controls.',
    'เสียงและผู้ช่วย AI เป็นส่วนหนึ่งของอนาคต JAVIS ในแอปต้นแบบนี้ คุณสามารถสำรวจห้อง เลือกบรรยากาศ และควบคุมไฟตัวอย่างได้',
  );
  String get exploreHome => _t('Explore my home', 'สำรวจบ้านของฉัน');
  String get littleHelp =>
      _t('A little help from JAVIS', 'ให้ JAVIS ช่วยคุณสักนิด');
  String get prototypeNote => _t(
    'Prototype · your real devices are not connected',
    'แอปต้นแบบ · ยังไม่ได้เชื่อมต่ออุปกรณ์จริง',
  );
  String get smallRituals =>
      _t('Small rituals, better days', 'กิจวัตรเล็ก ๆ เพื่อวันที่ดีขึ้น');
  String get setMood => _t('Set the mood.', 'สร้างบรรยากาศที่ใช่');
  String get moveWithDay => _t(
    'Let your home move with your day.',
    'ให้บ้านปรับไปตามจังหวะวันของคุณ',
  );
  String get everydayMoments => _t('Everyday moments', 'ช่วงเวลาในทุกวัน');
  String get unwindDescription => _t(
    'Warm white · 45% brightness\nA softer landing at the end of the day.',
    'แสงขาวอุ่น · ความสว่าง 45%\nค่อย ๆ ผ่อนคลายเมื่อสิ้นสุดวัน',
  );
  String get focusDescription => _t(
    'Neutral white · 95% brightness\nA little clarity for the things that matter.',
    'แสงขาวธรรมชาติ · ความสว่าง 95%\nเติมสมาธิให้สิ่งที่สำคัญ',
  );
  String get nightDescription => _t(
    'All available demo lights off. Rest easy.',
    'ปิดไฟตัวอย่างทุกดวงที่พร้อมใช้งาน พักผ่อนให้สบาย',
  );
  String get placeEverything =>
      _t('A place for everything', 'ทุกพื้นที่มีความหมาย');
  String get spacesTitle => _t('Your spaces.', 'พื้นที่ของคุณ');
  String get roomCalm => _t(
    'Every room, a different kind of calm.',
    'ทุกห้อง มีความสบายในแบบของตัวเอง',
  );
  String get newBeginning =>
      _t('Ready for a new beginning', 'พร้อมเติมสิ่งใหม่ ๆ');
  String roomSummary(int count, int active) =>
      _t('$count lights · $active on', 'ไฟ $count ดวง · เปิด $active ดวง');
  String get atHome => _t('Make yourself\nat home.', 'สบายใจ\nเหมือนอยู่บ้าน');
  String get lighting => _t('Lighting', 'แสงไฟ');
  String get littleLight =>
      _t('A little light goes a long way.', 'แสงเล็ก ๆ เติมความสุขได้มากมาย');
  String get emptyRoom => _t(
    'This demo room has no devices yet. The prototype adds new lights to the living room.',
    'ห้องตัวอย่างนี้ยังไม่มีอุปกรณ์ แอปต้นแบบจะเพิ่มไฟใหม่ไว้ในห้องนั่งเล่น',
  );
  String get roomAtmosphere => _t('Room atmosphere', 'บรรยากาศในห้อง');
  String get sceneDemoNote => _t(
    'Prototype · scene presets affect all available demo lights',
    'แอปต้นแบบ · บรรยากาศจะปรับไฟตัวอย่างทุกดวงที่พร้อมใช้งาน',
  );
  String get changeLightError => _t(
    'Could not change this light. Please try again.',
    'ปรับไฟดวงนี้ไม่ได้ โปรดลองอีกครั้ง',
  );
  String get offlineDemo =>
      _t('Offline · demo state', 'ออฟไลน์ · สถานะตัวอย่าง');
  String get off => _t('Off', 'ปิด');
  String get on => _t('On', 'เปิด');
  String get turnOff => _t('Turn off', 'ปิดไฟ');
  String get turnOn => _t('Turn on', 'เปิดไฟ');
  String sceneApplied(String name) => _t(
    '${scene(name)} applied to demo lights',
    'ปรับไฟตัวอย่างเป็น${scene(name)}แล้ว',
  );
  String get sceneError => _t(
    'Some lights could not be updated. Try the scene again.',
    'ปรับไฟบางดวงไม่ได้ โปรดลองเลือกบรรยากาศอีกครั้ง',
  );
  String get applying => _t('Applying…', 'กำลังปรับ…');
  String get updateLightError => _t(
    'Could not update this light. Please try again.',
    'อัปเดตไฟดวงนี้ไม่ได้ โปรดลองอีกครั้ง',
  );
  String get unavailable => _t('Light unavailable', 'ไฟไม่พร้อมใช้งาน');
  String get lightRemoved => _t(
    'This light is no longer in your home.',
    'ไม่มีไฟดวงนี้ในบ้านของคุณแล้ว',
  );
  String get removeLight => _t('Remove light', 'นำหลอดไฟออก');
  String get removingLight => _t('Removing light…', 'กำลังนำหลอดไฟออก…');
  String get removeLightTitle =>
      _t('Let this light go?', 'นำหลอดไฟนี้ออกจากบ้าน?');
  String removeLightDescription(String name) => _t(
    '“$name” will be unpaired from JAVIS and stop responding here. To reconnect, put the bulb in pairing mode and add it again—JAVIS finds it nearby over Bluetooth. If it does not appear, use Wi-Fi setup.',
    '“$name” จะถูกยกเลิกการเชื่อมต่อกับ JAVIS และจะควบคุมจากที่นี่ไม่ได้ หากจะเชื่อมต่อใหม่ ให้หลอดเข้าโหมดจับคู่แล้วเพิ่มอีกครั้ง JAVIS จะค้นหาใกล้ตัวผ่าน Bluetooth หากไม่พบ ให้ตั้งค่าผ่าน Wi-Fi',
  );
  String get removeLightError => _t(
    'Could not remove the light. It is still in your home. Check your connection and try again.',
    'นำหลอดไฟออกไม่สำเร็จ หลอดไฟยังอยู่ในบ้านของคุณ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง',
  );
  String get softerLight =>
      _t('A softer kind of light', 'แสงที่อ่อนโยนกว่าเดิม');
  String lightOn(int brightness) => _t(
    'Light on, $brightness percent brightness',
    'เปิดไฟ ความสว่าง $brightness เปอร์เซ็นต์',
  );
  String get lightOff => _t('Light off', 'ไฟปิดอยู่');
  String get offline => _t('Light offline', 'ไฟออฟไลน์');
  String get offlineDescription => _t(
    'This light is offline. Controls are unavailable until the device reconnects.',
    'ไฟดวงนี้ออฟไลน์ จะควบคุมได้เมื่ออุปกรณ์เชื่อมต่ออีกครั้ง',
  );
  String get brightness => _t('Brightness', 'ความสว่าง');
  String percent(int value) => _t('$value percent', '$value เปอร์เซ็นต์');
  String get white => _t('White', 'แสงขาว');
  String get color => _t('Color', 'แสงสี');
  String get temperature => _t('White temperature', 'อุณหภูมิแสงขาว');
  String kelvin(int value) => _t('$value kelvin', '$value เคลวิน');
  String get warm => _t('Warm', 'อุ่น');
  String get cool => _t('Cool', 'เย็น');
  String get chooseFeeling => _t('Choose a feeling', 'เลือกสีที่ใช่');
  String get localControlNote => _t(
    'Local demo controls · no command is sent to a real bulb',
    'ควบคุมในแอปตัวอย่าง · ไม่มีการส่งคำสั่งไปยังหลอดไฟจริง',
  );
  String get addLight => _t('Add a light', 'เพิ่มหลอดไฟ');
  String get moreHome =>
      _t('One more way to feel at home', 'เติมความเป็นบ้านอีกนิด');
  String get pairingPrepare =>
      _t('Bring a little\nlight home.', 'เติมแสงไฟ\nให้บ้านของคุณ');
  String get pairingSearching =>
      _t('Finding your\nnew glow…', 'กำลังค้นหา\nแสงไฟดวงใหม่…');
  String get pairingFound =>
      _t('A new light\nis waiting.', 'แสงไฟดวงใหม่\nพร้อมแล้ว');
  String get pairingFailure =>
      _t('Let’s try\nthat again.', 'มาลอง\nกันอีกครั้ง');
  String get pairingAlready =>
      _t('Already right\nat home.', 'อยู่ในบ้าน\nของคุณแล้ว');
  String get pairingSuccess => _t('Right at home.', 'เติมแสงให้บ้านแล้ว');
  String pairingStep(int current) =>
      _t('STEP $current OF 3', 'ขั้นตอน $current จาก 3');
  String get pairingHomeTitle =>
      _t('First, make a home.', 'เริ่มจากเตรียมบ้าน');
  String get pairingNetworkTitle =>
      _t('Connect to your Wi-Fi.', 'เชื่อมต่อ Wi-Fi ที่บ้าน');
  String get connectionMethodTitle =>
      _t('How would you like to connect?', 'ต้องการเชื่อมต่อแบบไหน?');
  String get homeWifiEzMode =>
      _t('Home Wi-Fi only · EZ setup', 'ใช้ Wi-Fi บ้านโดยตรง · แบบ EZ');
  String get bulbWifiApMode =>
      _t('Join the bulb’s Wi-Fi · AP setup', 'เข้าร่วม Wi-Fi ของหลอด · แบบ AP');
  String get ezPairingTitle =>
      _t('Bring your light\nonline.', 'เชื่อมแสงไฟ\nเข้ากับบ้าน');
  String get ezPairingIntro => _t(
    'Use this only when the iPhone stays on home Wi-Fi throughout setup. If iPhone asks to join the bulb’s Wi-Fi, choose AP setup instead.',
    'ใช้วิธีนี้เมื่อ iPhone อยู่บน Wi-Fi บ้านตลอดการตั้งค่า หาก iPhone ขอเข้าร่วม Wi-Fi ของหลอด ให้เลือกแบบ AP แทน',
  );
  String get ezBulbHint => _t(
    'Leave the bulb blinking quickly and enter your home Wi-Fi password. Stay on home Wi-Fi throughout setup.',
    'ให้หลอดไฟกะพริบเร็วไว้ แล้วกรอกรหัสผ่าน Wi-Fi ที่บ้าน โดยเชื่อมต่อ Wi-Fi ที่บ้านตลอดขั้นตอน',
  );
  String get checkingPairingSupport =>
      _t('Checking connection support…', 'กำลังตรวจสอบการรองรับ…');
  String get ezEntitlementRequired => _t(
    'EZ setup over home Wi-Fi needs Apple’s multicast permission, which this build does not have. If the bulb offers a SmartLife Wi-Fi network, choose “Join the bulb’s Wi-Fi” instead—even if the bulb blinks quickly.',
    'การเชื่อมต่อแบบ EZ ผ่าน Wi-Fi บ้านต้องใช้สิทธิ์ multicast จาก Apple ซึ่งแอปเวอร์ชันนี้ยังไม่มี หากหลอดปล่อย Wi-Fi ชื่อ SmartLife ให้เลือก “เข้าร่วม Wi-Fi ของหลอด” แทน แม้หลอดจะกะพริบเร็วก็ตาม',
  );
  String get ezSupportUnavailable => _t(
    'EZ setup is not available in this build. If the bulb offers a SmartLife Wi-Fi network, try the AP setup instead.',
    'แอปเวอร์ชันนี้ยังใช้การเชื่อมต่อแบบ EZ ไม่ได้ หากหลอดปล่อย Wi-Fi ชื่อ SmartLife ให้ลองใช้แบบ AP แทน',
  );
  String get ezRetryTip => _t(
    'Keep the bulb blinking quickly and iPhone on the same 2.4 GHz home Wi-Fi. Check the network name and password, then try again.',
    'ให้หลอดไฟกะพริบเร็ว และ iPhone ต่อ Wi-Fi 2.4 GHz ที่บ้าน ตรวจชื่อเครือข่ายกับรหัสผ่าน แล้วลองใหม่',
  );
  String get discoverHotspotTitle =>
      _t('Find a little\nlight nearby.', 'ค้นหาแสงไฟ\nใกล้ตัวคุณ');
  String get discoverHotspotIntro => _t(
    'Put the bulb in pairing mode. JAVIS will ask iPhone to join its SmartLife setup Wi-Fi if available; blinking speed may vary.',
    'ให้หลอดไฟอยู่ในโหมดจับคู่ แล้ว JAVIS จะขอให้ iPhone เข้าร่วม Wi-Fi สำหรับตั้งค่าชื่อ SmartLife หากพบ ความเร็วในการกะพริบอาจต่างกันได้',
  );
  String get discoverHotspot =>
      _t('Find device hotspot', 'ค้นหาฮอตสปอตอุปกรณ์');
  String get discoveringHotspot =>
      _t('Finding device hotspot…', 'กำลังค้นหาฮอตสปอตอุปกรณ์…');
  String get discoveringHotspotHint => _t(
    'Keep the bulb nearby and confirm the iPhone Wi-Fi connection request when it appears.',
    'วางหลอดไฟไว้ใกล้ ๆ แล้วกดยืนยันเมื่อ iPhone ขอเชื่อมต่อ Wi-Fi ของอุปกรณ์',
  );
  String get wifiPermissionHint => _t(
    'Allow location access to fill in your current Wi-Fi name. You can also enter it yourself. Stay on home Wi-Fi until the connection request appears.',
    'อนุญาตตำแหน่งเพื่อเติมชื่อ Wi-Fi ที่ใช้อยู่ หรือกรอกชื่อเองได้ ให้เชื่อมต่อ Wi-Fi ที่บ้านไว้จนกว่าจะมีคำขอเชื่อมต่ออุปกรณ์',
  );
  String get deviceHotspotFound => _t(
    'Device hotspot found. Your light will be added after Wi-Fi setup completes.',
    'พบฮอตสปอตอุปกรณ์แล้ว จะเพิ่มหลอดไฟเมื่อเชื่อมต่อ Wi-Fi สำเร็จ',
  );
  String get discoveredNetworkIntro => _t(
    'Choose the 2.4 GHz home network your light will use, then enter its password.',
    'เลือก Wi-Fi 2.4 GHz ที่ต้องการให้หลอดไฟใช้ แล้วกรอกรหัสผ่านของเครือข่ายนั้น',
  );
  String get discoveredWifiDescription => _t(
    'Use your home network, not the device hotspot. iPhone cannot fill in the saved password.',
    'ใช้ Wi-Fi ที่บ้าน ไม่ใช่ฮอตสปอตอุปกรณ์ โดย iPhone ไม่สามารถเติมรหัสผ่านที่บันทึกไว้ให้อัตโนมัติได้',
  );
  String get pairManually => _t('Set up manually', 'ตั้งค่าด้วยตนเอง');
  String get useAnotherNetwork =>
      _t('Enter another network', 'กรอกชื่อเครือข่ายอื่น');
  String get chooseWifi => _t('Choose Wi-Fi', 'เลือก Wi-Fi');
  String get findingWifiNetworks =>
      _t('Checking available Wi-Fi…', 'กำลังตรวจสอบ Wi-Fi ที่ใช้ได้…');
  String get wifiListUnavailable => _t(
    'This device did not return a Wi-Fi list. Reconnect iPhone to home Wi-Fi first, then enter the details below and tap Prepare connection to continue with manual setup.',
    'อุปกรณ์ไม่ส่งรายชื่อ Wi-Fi กลับมา ให้ iPhone กลับไปเชื่อมต่อ Wi-Fi ที่บ้านก่อน แล้วกรอกข้อมูลด้านล่างและกดเตรียมการเชื่อมต่อ เพื่อตั้งค่าด้วยตนเอง',
  );
  String get pairingHotspotTitle =>
      _t('Meet your new light.', 'ไปพบหลอดไฟดวงใหม่');
  String get pairingHomeIntro => _t(
    'Set up a private demo home for this iPhone. We’ll keep it ready for your next visit.',
    'ตั้งค่าบ้านเดโมสำหรับ iPhone เครื่องนี้ แล้วกลับมาใช้ต่อได้ครั้งหน้า',
  );
  String get pairingDemoHint => _t(
    'Explore each step with a sample bulb. No real device will be changed.',
    'ลองทุกขั้นตอนด้วยหลอดไฟตัวอย่าง โดยไม่กระทบอุปกรณ์จริง',
  );
  String get pairingNetworkIntro => _t(
    'Enter your 2.4 GHz network, then get the bulb ready to pair.',
    'กรอก Wi-Fi 2.4 GHz แล้วเตรียมหลอดไฟให้พร้อมเชื่อมต่อ',
  );
  String get pairingHotspotIntro => _t(
    'Your connection is prepared. Switch to the bulb’s Wi-Fi, then return here.',
    'เตรียมการเชื่อมต่อแล้ว สลับไป Wi-Fi ของหลอดไฟ แล้วกลับมาที่นี่',
  );
  String get pairingBulbTipTitle =>
      _t('Is the bulb ready to pair?', 'หลอดไฟพร้อมจับคู่หรือยัง?');
  String get pairingBulbTipBody => _t(
    'Put the bulb in pairing mode and look for its SmartLife Wi-Fi. Some bulbs offer it even while blinking quickly; there is no need to wait for slow blinking.',
    'ให้หลอดไฟเข้าโหมดจับคู่ แล้วดูว่ามี Wi-Fi ชื่อ SmartLife หรือไม่ บางรุ่นปล่อย Wi-Fi แม้กะพริบเร็ว จึงไม่ต้องรอให้กะพริบช้า',
  );
  String get pairingOpenSettings =>
      _t('Open iPhone Settings → Wi-Fi', 'เปิดการตั้งค่า iPhone → Wi-Fi');
  String get pairingJoinHotspot => _t(
    'Join the bulb hotspot, often named SmartLife…',
    'เชื่อมต่อฮอตสปอตของหลอดไฟ มักชื่อ SmartLife…',
  );
  String get pairingReturnToApp => _t(
    'Come back to JAVIS and tap Connect a light.',
    'กลับมาที่ JAVIS แล้วกดเชื่อมต่อหลอดไฟ',
  );
  String get pairingHotspotHint => _t(
    'No internet on the bulb Wi-Fi is normal. Return within 8 minutes.',
    'Wi-Fi ของหลอดไม่มีอินเทอร์เน็ตเป็นเรื่องปกติ กลับมาภายใน 8 นาที',
  );
  String get pairingWaitingHint => _t(
    'Keep the bulb powered on. This may take about a minute.',
    'เปิดหลอดไฟทิ้งไว้ ขั้นตอนนี้อาจใช้เวลาประมาณหนึ่งนาที',
  );
  String get pairingRetryTip => _t(
    'Check that the bulb is in pairing mode and its Wi-Fi appears, then reconnect iPhone to home Wi-Fi before preparing again.',
    'ตรวจว่าหลอดอยู่ในโหมดจับคู่และเห็น Wi-Fi ของหลอด ก่อนเตรียมเชื่อมต่อใหม่ให้ iPhone กลับไปต่อ Wi-Fi บ้าน',
  );
  String get pairingPreparedAction =>
      _t('I’ve joined the bulb Wi-Fi', 'เชื่อมต่อ Wi-Fi ของหลอดแล้ว');
  String get prepareDescription => _t(
    'This is a guided pairing prototype. You can explore the experience without connecting a physical bulb.',
    'นี่คือขั้นตอนเชื่อมต่อแบบจำลอง คุณสามารถลองใช้งานได้โดยไม่ต้องเชื่อมต่อหลอดไฟจริง',
  );
  String get searchingDescription => _t(
    'Simulating discovery. No Bluetooth or Wi-Fi scan is running.',
    'กำลังจำลองการค้นหา ไม่มีการสแกน Bluetooth หรือ Wi-Fi จริง',
  );
  String get foundDescription => _t(
    'We found a sample RGB + white smart bulb. Add it to your demo living room.',
    'พบหลอดไฟอัจฉริยะ RGB + แสงขาวตัวอย่าง เพิ่มไว้ในห้องนั่งเล่นตัวอย่างได้เลย',
  );
  String get failureDescription => _t(
    'This simulated search did not find a bulb. Retry to continue the demo.',
    'การค้นหาจำลองครั้งนี้ไม่พบหลอดไฟ ลองอีกครั้งเพื่อใช้งานตัวอย่างต่อ',
  );
  String get alreadyDescription => _t(
    'This sample bulb was already in your demo home. No duplicate was added.',
    'หลอดไฟตัวอย่างนี้อยู่ในบ้านตัวอย่างแล้ว จึงไม่เพิ่มอุปกรณ์ซ้ำ',
  );
  String get successDescription => _t(
    'Your sample bulb is online. Give it a name you’ll recognise.',
    'หลอดไฟตัวอย่างออนไลน์แล้ว ตั้งชื่อให้จำง่าย',
  );
  String get realRequirements => _t(
    'For real pairing, you’ll need',
    'สิ่งที่ต้องใช้สำหรับการเชื่อมต่อจริง',
  );
  String get supportedBulb => _t(
    '01   A supported Wi-Fi smart bulb',
    '01   หลอดไฟอัจฉริยะ Wi-Fi ที่รองรับ',
  );
  String get wifiRequirement =>
      _t('02   A 2.4 GHz Wi-Fi network', '02   เครือข่าย Wi-Fi 2.4 GHz');
  String get pairingMode =>
      _t('03   The bulb in its pairing mode', '03   หลอดไฟอยู่ในโหมดเชื่อมต่อ');
  String get previewFailure =>
      _t('Preview a failed search', 'ทดลองสถานะค้นหาไม่สำเร็จ');
  String get optionalDemo =>
      _t('Optional demo state', 'สถานะตัวอย่าง เลือกเปิดได้');
  String get startPairing => _t('Start demo pairing', 'เริ่มเชื่อมต่อตัวอย่าง');
  String get searchingDevices =>
      _t('Searching sample devices…', 'กำลังค้นหาอุปกรณ์ตัวอย่าง…');
  String get sampleRoom =>
      _t('Sample device · Living room', 'อุปกรณ์ตัวอย่าง · ห้องนั่งเล่น');
  String get addToHome => _t('Add to demo home', 'เพิ่มในบ้านตัวอย่าง');
  String get retry => _t('Try again', 'ลองอีกครั้ง');
  String get backHome => _t('Back to my home', 'กลับบ้านของฉัน');
  String get cancel => _t('Cancel', 'ยกเลิก');
  String get pairingNote => _t(
    'Prototype only · live Tuya iOS pairing is a future milestone',
    'แอปต้นแบบ · การเชื่อมต่อ Tuya บน iOS จริงจะพัฒนาในขั้นถัดไป',
  );

  String get realDeviceMode => _t('Real device mode', 'โหมดอุปกรณ์จริง');
  String get stateUnavailable => _t('State unavailable', 'ยังไม่มีข้อมูลสถานะ');
  String get connected => _t('Connected', 'เชื่อมต่อแล้ว');
  String realConnectedSummary(int count) => _t(
    '$count lights connected · Real devices',
    'เชื่อมต่อไฟ $count ดวง · อุปกรณ์จริง',
  );
  String unknownRoomSummary(int count) => _t(
    '$count lights · State unavailable',
    'ไฟ $count ดวง · ยังไม่มีข้อมูลสถานะ',
  );
  String get realPairing => _t('Connect a light', 'เชื่อมต่อหลอดไฟ');
  String get pairingCancelled =>
      _t('Pairing cancelled.', 'ยกเลิกการเชื่อมต่อแล้ว');
  String get cancelledDescription => _t(
    'You can start again when your light is ready.',
    'เริ่มใหม่ได้เมื่อหลอดไฟพร้อมเชื่อมต่อ',
  );
  String get connectingLight =>
      _t('Connecting your light…', 'กำลังเชื่อมต่อหลอดไฟ…');
  String get realPairingDescription => _t(
    'Prepare your 2.4 GHz Wi-Fi and put the bulb in pairing mode.',
    'เตรียม Wi-Fi 2.4 GHz แล้วให้หลอดไฟอยู่ในโหมดจับคู่',
  );
  String get prepareDemoHome =>
      _t('Set up my demo home', 'ตั้งค่าบ้านสำหรับเดโม');
  String get preparingHome => _t('Preparing your home…', 'กำลังเตรียมบ้าน…');
  String get demoHomeDescription => _t(
    'JAVIS will create a demo app account and reuse this home when you return. Devices added here belong to this JAVIS account.',
    'JAVIS จะสร้างบัญชีแอปสำหรับเดโมและใช้บ้านนี้ต่อเมื่อกลับมา อุปกรณ์ที่เพิ่มจะอยู่ในบัญชี JAVIS นี้',
  );
  String get wifiDetails => _t('Your home Wi-Fi', 'Wi-Fi ที่บ้านของคุณ');
  String get wifiDetailsDescription => _t(
    'Connect this iPhone to your home Wi-Fi first. Enter the exact 2.4 GHz network name and password below.',
    'เชื่อมต่อ iPhone กับ Wi-Fi ที่บ้านก่อน แล้วกรอกชื่อเครือข่าย 2.4 GHz และรหัสผ่านให้ตรงทุกตัว',
  );
  String get wifiName => _t('Wi-Fi name (SSID)', 'ชื่อ Wi-Fi (SSID)');
  String get wifiPassword => _t('Wi-Fi password', 'รหัสผ่าน Wi-Fi');
  String get prepareConnection =>
      _t('Prepare connection', 'เตรียมการเชื่อมต่อ');
  String get preparingConnection =>
      _t('Preparing connection…', 'กำลังเตรียมการเชื่อมต่อ…');
  String get editWifi => _t('Edit Wi-Fi details', 'แก้ไขข้อมูล Wi-Fi');
  String get showPassword => _t('Show password', 'แสดงรหัสผ่าน');
  String get hidePassword => _t('Hide password', 'ซ่อนรหัสผ่าน');
  String get joinBulbHotspot => _t(
    'Ready for the next step. Open iPhone Settings → Wi-Fi and join the bulb’s hotspot (often named SmartLife…). Stay connected even if it has no internet, then return to JAVIS and tap Connect a light within 8 minutes. If no hotspot appears, check that the bulb is in pairing mode.',
    'พร้อมแล้ว เปิดการตั้งค่า iPhone → Wi-Fi แล้วเชื่อมต่อฮอตสปอตของหลอดไฟ (มักชื่อ SmartLife…) เชื่อมต่อไว้แม้จะแจ้งว่าไม่มีอินเทอร์เน็ต แล้วกลับมาที่ JAVIS และกดเชื่อมต่อหลอดไฟภายใน 8 นาที ถ้าไม่พบฮอตสปอต ให้ตรวจว่าหลอดอยู่ในโหมดจับคู่',
  );
  String get wifiPrivacy => _t(
    'Your Wi-Fi password is used for this attempt only. Enter it again if you retry.',
    'ใช้รหัสผ่าน Wi-Fi เฉพาะครั้งนี้ หากลองใหม่ต้องกรอกอีกครั้ง',
  );
  String get activatingLight => _t(
    'Your light is joining your home. Keep the bulb powered on and stay nearby.',
    'หลอดไฟกำลังเข้าร่วมบ้าน เปิดไฟทิ้งไว้และอยู่ใกล้หลอดไฟ',
  );
  String get connectedDescription => _t(
    'Your light is confirmed by the device provider and added to your home.',
    'ผู้ให้บริการยืนยันการเชื่อมต่อและเพิ่มหลอดไฟในบ้านแล้ว',
  );
  String get realControlNote => _t(
    'Controls reflect the last state reported by your light.',
    'ตัวควบคุมแสดงสถานะล่าสุดที่ได้รับจากหลอดไฟ',
  );
  String get noConnectedLights => _t(
    'No connected lights yet. Add a light to get started.',
    'ยังไม่มีหลอดไฟที่เชื่อมต่อ เพิ่มหลอดไฟเพื่อเริ่มใช้งาน',
  );
  String realHomeSummary(int active) => _t(
    '$active lights on · Real devices',
    'เปิดไฟ $active ดวง · อุปกรณ์จริง',
  );
  String get emptyRealRoom => _t(
    'No connected lights in this room yet.',
    'ยังไม่มีหลอดไฟที่เชื่อมต่อในห้องนี้',
  );
  String get realRoomPreview => _t('Room layout preview', 'ตัวอย่างการจัดห้อง');
  String get demoScenesOnly => _t(
    'Scene presets are available in demo mode.',
    'บรรยากาศสำเร็จรูปพร้อมใช้ในโหมดตัวอย่าง',
  );

  String providerStatus(String state) => switch (state) {
    'initializing' => _t(
      'Checking connection setup…',
      'กำลังตรวจสอบการเชื่อมต่อ…',
    ),
    'ready' => _t('Ready to connect', 'พร้อมเชื่อมต่อ'),
    'configurationMissing' => _t(
      'Connection setup is incomplete',
      'ยังตั้งค่าการเชื่อมต่อไม่ครบ',
    ),
    'sdkUnavailable' => _t(
      'Device connection is not installed yet',
      'ยังไม่ได้ติดตั้งส่วนเชื่อมต่ออุปกรณ์',
    ),
    'sessionRequired' => _t(
      'Home setup is required',
      'ต้องตั้งค่าบัญชีและบ้านก่อน',
    ),
    'unsupportedSimulator' => _t(
      'Use a physical iPhone to connect',
      'ใช้ iPhone จริงเพื่อเชื่อมต่อ',
    ),
    'permissionDenied' => _t(
      'Connection permission is needed',
      'ต้องอนุญาตการเชื่อมต่อ',
    ),
    'invalidProvider' => _t(
      'Connection mode is not configured',
      'ตั้งค่าโหมดการเชื่อมต่อไม่ถูกต้อง',
    ),
    _ => _t('Connection is unavailable', 'การเชื่อมต่อไม่พร้อมใช้งาน'),
  };

  String providerDescription(String state) => switch (state) {
    'initializing' => _t(
      'Please wait while JAVIS checks the device provider.',
      'รอสักครู่ JAVIS กำลังตรวจสอบผู้ให้บริการอุปกรณ์',
    ),
    'ready' => realPairingDescription,
    'configurationMissing' => _t(
      'The app needs its secure connection configuration before it can pair a light.',
      'แอปต้องมีการตั้งค่าการเชื่อมต่อที่ปลอดภัยก่อนเพิ่มหลอดไฟ',
    ),
    'sdkUnavailable' => _t(
      'Install the app-specific connection package, then reopen JAVIS. No light has been connected.',
      'ต้องติดตั้งชุดเชื่อมต่อสำหรับแอปนี้ แล้วเปิด JAVIS อีกครั้ง ยังไม่มีการเชื่อมต่อหลอดไฟ',
    ),
    'sessionRequired' => _t(
      'Set up the app account and home before adding a light.',
      'ตั้งค่าบัญชีและบ้านในแอปก่อนเพิ่มหลอดไฟ',
    ),
    'unsupportedSimulator' => _t(
      'Run JAVIS on a physical iPhone. The simulator cannot pair a real light.',
      'เปิด JAVIS บน iPhone จริง Simulator ไม่สามารถเชื่อมต่อหลอดไฟจริงได้',
    ),
    'permissionDenied' => _t(
      'Allow the required connection permissions in iPhone Settings, then try again.',
      'อนุญาตสิทธิ์การเชื่อมต่อที่จำเป็นในการตั้งค่า iPhone แล้วลองอีกครั้ง',
    ),
    'invalidProvider' => _t(
      'Choose a supported connection mode in the app build configuration.',
      'เลือกโหมดการเชื่อมต่อที่รองรับในการตั้งค่าบิลด์ของแอป',
    ),
    _ => _t(
      'Check your connection and try again.',
      'ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง',
    ),
  };

  String lightingError(String code) => switch (code) {
    'multicastEntitlementRequired' => ezEntitlementRequired,
    'deviceNotReady' => deviceNotReady,
    'bluetoothOff' => bluetoothOff,
    'cancelled' => cancelledDescription,
    'busy' => _t(
      'Another operation is running. Wait for it to finish.',
      'มีงานกำลังทำอยู่ รอให้เสร็จก่อน',
    ),
    'timeout' => _t(
      'The connection took too long. Reconnect this iPhone to home Wi-Fi, prepare the connection again, then join the bulb’s hotspot and retry.',
      'การเชื่อมต่อใช้เวลานานเกินไป เชื่อมต่อ iPhone กับ Wi-Fi ที่บ้านเพื่อเตรียมการเชื่อมต่อใหม่ จากนั้นเชื่อมต่อฮอตสปอตของหลอดไฟแล้วลองอีกครั้ง',
    ),
    'permissionDenied' ||
    'configurationMissing' ||
    'sdkUnavailable' ||
    'sessionRequired' ||
    'unsupportedSimulator' => providerDescription(code),
    'unsupportedCommand' => _t(
      'This control is not supported by your light.',
      'หลอดไฟนี้ไม่รองรับการควบคุมนี้',
    ),
    'pairingFailed' => _t(
      'Could not connect the light. Check the 2.4 GHz Wi-Fi details and that the bulb is in pairing mode, then join its SmartLife Wi-Fi and try again.',
      'เชื่อมต่อหลอดไฟไม่ได้ ตรวจชื่อและรหัสผ่าน Wi-Fi 2.4 GHz และให้หลอดอยู่ในโหมดจับคู่ แล้วเข้าร่วม Wi-Fi ชื่อ SmartLife ของหลอดเพื่อลองใหม่',
    ),
    'invalidNetwork' => _t(
      'Enter the 2.4 GHz Wi-Fi name and password before connecting.',
      'กรอกชื่อและรหัสผ่าน Wi-Fi 2.4 GHz ก่อนเชื่อมต่อ',
    ),
    'noDevices' => _t(
      'No supported device hotspot was found. Check that the bulb is in pairing mode, or try manual setup.',
      'ไม่พบฮอตสปอตอุปกรณ์ที่รองรับ ตรวจว่าหลอดอยู่ในโหมดจับคู่ หรือลองตั้งค่าด้วยตนเอง',
    ),
    _ => _t(
      'The device connection failed. Check your connection and try again.',
      'ติดต่ออุปกรณ์ไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง',
    ),
  };

  String room(String key) => switch (key) {
    'Living room' => _t('Living room', 'ห้องนั่งเล่น'),
    'Bedroom' => _t('Bedroom', 'ห้องนอน'),
    'Studio' => _t('Studio', 'ห้องทำงาน'),
    'Kitchen' => _t('Kitchen', 'ห้องครัว'),
    'Front yard' => _t('Front yard', 'หน้าบ้าน'),
    'Office' => _t('Office', 'ห้องทำงาน'),
    'Bathroom' => _t('Bathroom', 'ห้องน้ำ'),
    'Kids room' => _t('Kids room', 'ห้องเด็ก'),
    _ => key,
  };
  String demoDevice(String id, String fallback) => switch (id) {
    'living-lamp' => _t('Ceiling light', 'ไฟเพดาน'),
    'bedroom-ceiling' => _t('Bedroom ceiling light', 'ไฟเพดานห้องนอน'),
    'bedside-lamp' => _t('Bedside light', 'ไฟหัวเตียง'),
    'kitchen-lamp' => _t('Kitchen light', 'ไฟครัว'),
    'porch-lamp' => _t('Porch light', 'ไฟหน้าบ้าน'),
    'new-demo-bulb' => _t('New ambient bulb', 'หลอดไฟบรรยากาศดวงใหม่'),
    _ => fallback,
  };
  String scene(String key) => switch (key) {
    'Unwind' => _t('Unwind', 'ผ่อนคลาย'),
    'Focus' => _t('Focus', 'มีสมาธิ'),
    'Good night' => _t('Good night', 'ราตรีสวัสดิ์'),
    _ => key,
  };
  String swatch(String key) => switch (key) {
    'Rose' => _t('Rose', 'ชมพูกุหลาบ'),
    'Lavender' => _t('Lavender', 'ม่วงลาเวนเดอร์'),
    'Sky' => _t('Sky', 'ฟ้าท้องฟ้า'),
    'Sage' => _t('Sage', 'เขียวเสจ'),
    'Amber' => _t('Amber', 'เหลืองอำพัน'),
    _ => key,
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class AppLanguage extends InheritedWidget {
  const AppLanguage({required this.setLocale, required super.child, super.key});
  final ValueChanged<Locale> setLocale;
  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguage>()!;
  @override
  bool updateShouldNotify(AppLanguage old) => setLocale != old.setLocale;
}

class LanguageButton extends StatefulWidget {
  const LanguageButton({super.key});
  @override
  State<LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<LanguageButton> {
  bool _isOpen = false;

  Future<void> _chooseLanguage() async {
    if (_isOpen) return;
    _isOpen = true;
    final setLocale = AppLanguage.of(context).setLocale;
    try {
      final locale = await showModalBottomSheet<Locale>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        barrierColor: CalmColors.ink.withValues(alpha: .28),
        elevation: 0,
        constraints: const BoxConstraints(maxWidth: 560),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => const _LanguageSheet(),
      );
      if (mounted && locale != null) setLocale(locale);
    } finally {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.language,
    child: TextButton(
      onPressed: _chooseLanguage,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 20),
          const SizedBox(width: 6),
          Text(context.l10n.isThai ? 'ไทย' : 'EN'),
        ],
      ),
    ),
  );
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet();

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  bool _closing = false;

  void _select(String code) {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = Localizations.localeOf(context).languageCode;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Semantics(
              header: true,
              child: Text(
                context.l10n.language,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.chooseLanguage,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 24),
            for (final language in const [
              ('en', 'English'),
              ('th', 'ไทย'),
            ]) ...[
              Semantics(
                button: true,
                selected: selected == language.$1,
                label: language.$2,
                excludeSemantics: true,
                onTap: () => _select(language.$1),
                child: Material(
                  color: selected == language.$1
                      ? scheme.surfaceContainerHighest
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _select(language.$1),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 72),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                language.$2,
                                style: TextStyle(
                                  fontFamily: language.$1 == 'th'
                                      ? 'NotoSansThai'
                                      : 'System',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              selected == language.$1
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected == language.$1
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant.withValues(
                                      alpha: .4,
                                    ),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (language.$1 == 'en') const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
