import 'dart:async';

import 'package:flutter/foundation.dart';

enum LockStatus { locked, unlocking, unlocked }

enum LockEvent { autoLocked, unlockedInApp, unlockedFingerprint }

@immutable
class LockActivity {
  const LockActivity({required this.event, required this.at, this.actor});
  final LockEvent event;
  final DateTime at;
  final String? actor;
}

/// Preview of the front-door lock (spec 012). It never talks to hardware.
///
/// The status becomes “unlocked” only when this simulated lock reports back,
/// mirroring the rule the real integration must follow.
class LockStore extends ChangeNotifier {
  LockStore({
    this.reportDelay = const Duration(milliseconds: 1200),
    this.autoLockAfter = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _updatedAt = now.subtract(const Duration(minutes: 1));
    _activity = [
      LockActivity(
        event: LockEvent.autoLocked,
        at: now.subtract(const Duration(minutes: 1)),
      ),
      LockActivity(
        event: LockEvent.unlockedInApp,
        actor: 'มายด์',
        at: now.subtract(const Duration(minutes: 2)),
      ),
      LockActivity(
        event: LockEvent.unlockedFingerprint,
        actor: 'คุณแม่',
        at: now.subtract(const Duration(hours: 6, minutes: 37)),
      ),
    ];
  }

  final Duration reportDelay;
  final Duration autoLockAfter;
  final DateTime Function() _clock;

  LockStatus _status = LockStatus.locked;
  late DateTime _updatedAt;
  late List<LockActivity> _activity;
  bool _autoLock = true;
  final int batteryPercent = 82;
  final bool doorClosed = true;
  Timer? _reportTimer;
  Timer? _autoLockTimer;

  LockStatus get status => _status;
  DateTime get updatedAt => _updatedAt;
  bool get autoLock => _autoLock;
  List<LockActivity> get activity => List.unmodifiable(_activity);
  bool get busy => _status == LockStatus.unlocking;

  void unlock({required String actor}) {
    if (_status != LockStatus.locked) return;
    _status = LockStatus.unlocking;
    notifyListeners();
    _reportTimer = Timer(reportDelay, () {
      _status = LockStatus.unlocked;
      _record(LockEvent.unlockedInApp, actor: actor);
      if (_autoLock) {
        _autoLockTimer = Timer(autoLockAfter, _lockFromDevice);
      }
    });
  }

  void setAutoLock(bool value) {
    _autoLock = value;
    if (!value) _autoLockTimer?.cancel();
    if (value && _status == LockStatus.unlocked) {
      _autoLockTimer = Timer(autoLockAfter, _lockFromDevice);
    }
    notifyListeners();
  }

  void _lockFromDevice() {
    _status = LockStatus.locked;
    _record(LockEvent.autoLocked);
  }

  void _record(LockEvent event, {String? actor}) {
    _updatedAt = _clock();
    _activity = [
      LockActivity(event: event, actor: actor, at: _updatedAt),
      ..._activity,
    ].take(6).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _reportTimer?.cancel();
    _autoLockTimer?.cancel();
    super.dispose();
  }
}
