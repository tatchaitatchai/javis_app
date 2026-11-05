import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/theme/app_appearance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const themePreference = DeviceThemePreference();
  final themeMode = await themePreference.read();
  runApp(JavisApp(themeMode: themeMode, themePreference: themePreference));
}
