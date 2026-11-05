import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Where the chosen theme is kept between launches. It belongs to the device,
/// not the account, so it stays after sign-out.
abstract interface class ThemePreference {
  Future<ThemeMode> read();
  Future<void> write(ThemeMode mode);
}

/// iOS UserDefaults, through `ThemePreferenceBridge.swift`. A failure never
/// blocks the app: reading falls back to [ThemeMode.system], and a failed write
/// only means the choice lasts until the app closes.
class DeviceThemePreference implements ThemePreference {
  const DeviceThemePreference();

  static const _channel = MethodChannel('com.javis.home/theme');

  @override
  Future<ThemeMode> read() async {
    try {
      final name = await _channel.invokeMethod<String>('read');
      return ThemeMode.values.asNameMap()[name] ?? ThemeMode.system;
    } on PlatformException catch (error) {
      debugPrint('Reading the theme failed: ${error.code}');
    } on MissingPluginException {
      debugPrint('Reading the theme failed: no native storage');
    }
    return ThemeMode.system;
  }

  @override
  Future<void> write(ThemeMode mode) async {
    try {
      await _channel.invokeMethod<void>('write', {'mode': mode.name});
    } on PlatformException catch (error) {
      debugPrint('Saving the theme failed: ${error.code}');
    } on MissingPluginException {
      debugPrint('Saving the theme failed: no native storage');
    }
  }
}

/// Gives screens the current theme choice and a way to change it.
class AppAppearance extends InheritedWidget {
  const AppAppearance({
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> setThemeMode;

  static AppAppearance of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppAppearance>()!;

  @override
  bool updateShouldNotify(AppAppearance old) =>
      themeMode != old.themeMode || setThemeMode != old.setThemeMode;
}
