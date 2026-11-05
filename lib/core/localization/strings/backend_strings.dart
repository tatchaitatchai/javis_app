part of '../app_localizations.dart';

/// What to tell the user when the server says no. Codes never reach the screen.
extension BackendStrings on AppLocalizations {
  String failure(BackendFailure failure) => switch (failure.code) {
    BackendFailure.offline => _t(
      'Can’t reach JAVIS. Check your connection and try again.',
      'เชื่อมต่อ JAVIS ไม่ได้ ตรวจอินเทอร์เน็ตแล้วลองอีกครั้ง',
    ),
    'rate_limited' => _t(
      'That’s a lot of tries. Please wait a little and try again.',
      'ลองหลายครั้งเกินไป รอสักครู่แล้วลองใหม่',
    ),
    'too_many_attempts' => _t(
      'Too many wrong codes. Request a new one.',
      'ใส่รหัสผิดหลายครั้ง ขอรหัสใหม่อีกครั้ง',
    ),
    'sms_unavailable' => _t(
      'The code couldn’t be sent. Try again shortly.',
      'ส่งรหัสไม่สำเร็จ ลองใหม่อีกครั้งในอีกสักครู่',
    ),
    'invalid_phone' => _t(
      'Check this mobile number.',
      'ตรวจเบอร์มือถืออีกครั้ง',
    ),
    'invalid_name' || 'invalid_home' || 'invalid_zone' => _t(
      'Check this name and try again.',
      'ตรวจชื่ออีกครั้งแล้วลองใหม่',
    ),
    'already_member' => alreadyMember,
    'already_invited' => _t(
      'This number already has an invitation.',
      'เบอร์นี้มีคำเชิญอยู่แล้ว',
    ),
    'member_limit_reached' => _t(
      'This home has reached its limit of people.',
      'บ้านนี้มีสมาชิกครบจำนวนแล้ว',
    ),
    'home_limit_reached' => _t(
      'You’ve reached the limit of homes.',
      'คุณมีบ้านครบจำนวนแล้ว',
    ),
    'zone_limit_reached' => _t(
      'This home has reached its limit of zones.',
      'บ้านนี้มีโซนครบจำนวนแล้ว',
    ),
    'device_limit_reached' => _t(
      'This home has reached its limit of devices.',
      'บ้านนี้มีอุปกรณ์ครบจำนวนแล้ว',
    ),
    'scene_limit_reached' => _t(
      'This home has reached its limit of scenes.',
      'บ้านนี้มีฉากครบจำนวนแล้ว',
    ),
    'device_claimed' => _t(
      'This device already belongs to another home.',
      'อุปกรณ์นี้อยู่ในบ้านอื่นแล้ว',
    ),
    'home_has_devices' => _t(
      'Remove this home’s devices first.',
      'เอาอุปกรณ์ออกจากบ้านนี้ก่อน',
    ),
    'forbidden' => _t(
      'Your role in this home doesn’t allow that.',
      'บทบาทของคุณในบ้านนี้ทำรายการนี้ไม่ได้',
    ),
    'invite_not_found' => inviteGone,
    'home_not_found' ||
    'member_not_found' ||
    'device_not_found' ||
    'scene_not_found' => _t(
      'This is no longer here. Pull the latest and try again.',
      'รายการนี้ไม่มีแล้ว ลองเปิดหน้านี้ใหม่อีกครั้ง',
    ),
    'unauthorized' => _t('Please sign in again.', 'กรุณาเข้าสู่ระบบอีกครั้ง'),
    _ => _t(
      'That didn’t work. Please try again.',
      'ทำรายการไม่สำเร็จ ลองอีกครั้ง',
    ),
  };

  String get tryAgain => _t('Try again', 'ลองอีกครั้ง');
  String get cantLoadHomes =>
      _t('Your homes couldn’t be loaded.', 'โหลดข้อมูลบ้านไม่สำเร็จ');
  String get cantLoadScenes =>
      _t('Scenes couldn’t be loaded.', 'โหลดฉากไม่สำเร็จ');
  String get cantConnectTitle =>
      _t('Can’t reach JAVIS', 'เชื่อมต่อ JAVIS ไม่ได้');
  String get cantConnectBody => _t(
    'You’re still signed in. Check your connection and try again.',
    'คุณยังเข้าสู่ระบบอยู่ ตรวจอินเทอร์เน็ตแล้วลองอีกครั้ง',
  );
  String get noHomeYetTitle => _t('No home here yet', 'ยังไม่มีบ้าน');
  String get noHomeYetBody => _t(
    'Create a home, or accept an invitation to join one.',
    'สร้างบ้านของคุณ หรือตอบรับคำเชิญเข้าบ้าน',
  );
  String otpDebugNote(String code) => _t(
    'Test mode: no SMS is sent. Your code is $code',
    'โหมดทดสอบ ยังไม่ส่ง SMS จริง รหัสของคุณคือ $code',
  );
  String get someone => _t('Someone', 'มีคน');
  String get unnamedMember => _t('Household member', 'สมาชิกในบ้าน');
  String zoneTotal(int count) =>
      _t('$count ${count == 1 ? 'zone' : 'zones'}', '$count โซน');
  String get leaveHome => _t('Leave this home', 'ออกจากบ้านนี้');
  String leaveHomeQuestion(String home) => _t('Leave $home?', 'ออกจาก $home?');
  String get removeFromHome => _t('Remove from home', 'เอาออกจากบ้าน');
  String removeMemberQuestion(String name) =>
      _t('Remove $name from this home?', 'เอา $name ออกจากบ้านนี้?');
  String get revokeInvite => _t('Cancel invitation', 'ยกเลิกคำเชิญ');
  String get noUnlockRight => _t(
    'The home owner hasn’t given you unlock access.',
    'เจ้าของบ้านยังไม่ได้ให้สิทธิ์ปลดล็อกกับคุณ',
  );
}
