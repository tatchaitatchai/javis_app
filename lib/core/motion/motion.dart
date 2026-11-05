import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Shared timing so every control moves the same way.
///
/// Durations collapse to zero when the user turns on Reduce Motion.
abstract final class Motion {
  static const press = Duration(milliseconds: 110);
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const gentle = Duration(milliseconds: 380);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Light, consistent haptics. iOS ignores them when system haptics are off.
abstract final class Haptics {
  static void tap() => HapticFeedback.selectionClick();
  static void toggle() => HapticFeedback.lightImpact();
  static void confirm() => HapticFeedback.mediumImpact();
  static void warn() => HapticFeedback.heavyImpact();
}
