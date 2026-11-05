part of '../app_localizations.dart';

/// Welcome, phone + OTP sign-in, profile, first home, zones, invitations.
extension OnboardingStrings on AppLocalizations {
  String get welcomeTagline => _t(
    'Every light and door at home,\nfrom one place.',
    'ไฟและประตูทั้งบ้าน\nคุมได้จากที่เดียว',
  );
  String get welcomePointHomes => _t(
    'Several homes, each split into zones',
    'แยกบ้านได้หลายหลัง แบ่งโซนได้',
  );
  String get welcomePointMembers =>
      _t('Invite the people you live with', 'ชวนคนในบ้านมาใช้ด้วยกัน');
  String get welcomePointScenes => _t(
    'One tap changes the whole home',
    'กดครั้งเดียว เปลี่ยนทั้งบ้านด้วยฉาก',
  );
  String get startWithPhone =>
      _t('Start with your mobile number', 'เริ่มต้นด้วยเบอร์มือถือ');
  String get termsNotice => _t(
    'By continuing you agree to the Terms and Privacy Policy.',
    'เมื่อดำเนินการต่อ แสดงว่าคุณยอมรับข้อกำหนดและนโยบายความเป็นส่วนตัว',
  );

  String get yourMobileTitle => _t('Your mobile number', 'เบอร์มือถือของคุณ');
  String get yourMobileSubtitle => _t(
    'We’ll text you a 6-digit code. The same number signs you up and signs you in.',
    'เราจะส่งรหัส 6 หลักทาง SMS ใช้เบอร์นี้ทั้งสมัครใหม่และเข้าสู่ระบบ',
  );
  String get mobileNumber => _t('Mobile number', 'เบอร์มือถือ');
  String get sendCode => _t('Send code', 'ส่งรหัสยืนยัน');
  String get noPasswordNeeded => _t(
    'No password to remember — just the code from SMS.',
    'ไม่ต้องตั้งรหัสผ่าน ใช้รหัสจาก SMS ทุกครั้ง',
  );

  String get enterCodeTitle => _t('Enter the code', 'กรอกรหัสยืนยัน');
  String get codeSentTo =>
      _t('We sent a 6-digit code to ', 'ส่งรหัส 6 หลักไปที่ ');
  String get changeNumber => _t('Change', 'แก้ไขเบอร์');
  String get sixDigitCode => _t('6-digit code', 'รหัส 6 หลัก');
  String get codeInvalid => _t(
    'That code didn’t match. Try again.',
    'รหัสไม่ถูกต้อง ลองใหม่อีกครั้ง',
  );
  String resendIn(String time) =>
      _t('Didn’t get it? Resend in $time', 'ไม่ได้รับรหัส? ส่งใหม่ได้ใน $time');
  String get resendCode => _t('Resend code', 'ส่งรหัสอีกครั้ง');
  String get otpDemoNote => _t(
    'Preview: no SMS is sent. Any 6 digits work; 081 234 5678 opens the demo home.',
    'ต้นแบบ: ยังไม่ส่ง SMS จริง ใส่เลข 6 หลักใดก็ได้ เบอร์ 081 234 5678 จะเข้าบ้านตัวอย่าง',
  );

  String get profileTitle => _t(
    'Welcome! What should we call you?',
    'ยินดีต้อนรับ เราควรเรียกคุณว่าอะไร',
  );
  String get profileSubtitle => _t(
    'People in your home will see this name.',
    'ชื่อนี้จะแสดงให้สมาชิกในบ้านเห็น',
  );
  String get nickname => _t('Nickname', 'ชื่อเล่น');

  String get firstHomeTitle =>
      _t('Name your first home', 'ตั้งชื่อบ้านหลังแรก');
  String get addHomeTitle => _t('Name the new home', 'ตั้งชื่อบ้านหลังใหม่');
  String get firstHomeSubtitle => _t(
    'You can add other places later, like a condo or your parents’ home.',
    'เพิ่มบ้านหลังอื่นทีหลังได้ เช่น คอนโด หรือบ้านพ่อแม่',
  );
  String get homeName => _t('Home name', 'ชื่อบ้าน');
  String get homeNameHint => _t('e.g. Ladprao home', 'เช่น บ้านลาดพร้าว');
  List<String> get homeNamePresets => isThai
      ? const ['บ้านของฉัน', 'คอนโด', 'บ้านพ่อแม่']
      : const ['My home', 'Condo', 'Parents’ home'];
  String get createHome => _t('Create home', 'สร้างบ้าน');
  String get alreadyInvited =>
      _t('Already invited to a home?', 'มีคนชวนเข้าบ้านอยู่แล้ว?');
  String invitesWaiting(int count) => _t(
    '$count ${count == 1 ? 'invitation is' : 'invitations are'} waiting for you',
    'มีคำเชิญ $count รายการรอคุณอยู่',
  );

  String zonesTitle(String home) =>
      _t('Which zones does $home have?', '$homeมีโซนอะไรบ้าง');
  String get zonesSubtitle => _t(
    'Pick as many as you like. You can always change them later.',
    'เลือกได้หลายโซน แก้ไขหรือเพิ่มทีหลังได้เสมอ',
  );
  String get nameYourOwn => _t('Name your own', 'ตั้งชื่อเอง');
  String get newZoneTitle => _t('New zone', 'โซนใหม่');
  String get zoneName => _t('Zone name', 'ชื่อโซน');
  String enterHomeWithZones(int count) => _t(
    'Enter home · $count ${count == 1 ? 'zone' : 'zones'}',
    'เข้าบ้าน · $count โซน',
  );

  String invitedYou(String name) =>
      _t('$name invited you to', '$name ชวนคุณเข้าบ้าน');
  String get yourRole => _t('Your role', 'บทบาทของคุณ');
  String get inThisHome => _t('In this home', 'ในบ้านมี');
  String get inviteExpires => _t('Invitation expires', 'คำเชิญหมดอายุ');
  String get memberRightsNote => _t(
    'Members can use lights and scenes. Unlocking the door depends on what the owner allows.',
    'สมาชิกเปิดปิดไฟและใช้ฉากได้ ส่วนการปลดล็อกประตูขึ้นกับสิทธิ์ที่เจ้าของบ้านตั้งไว้',
  );
  String get joinHome => _t('Join home', 'เข้าร่วมบ้าน');
  String get inviteGone =>
      _t('This invitation is no longer available.', 'คำเชิญนี้ไม่มีแล้ว');
}
