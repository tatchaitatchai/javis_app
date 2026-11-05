import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'calm_palette.dart';

export 'calm_palette.dart';

abstract final class CalmColors {
  static const background = Color(0xFFF2F0E8);
  static const ink = Color(0xFF253026);
  static const sage = Color(0xFF667860);
  static const gold = Color(0xFFE3C68C);
  static Color muted(BuildContext context) => context.palette.textMuted;
  static Color surface(BuildContext context) => context.palette.raised;
}

ThemeData calmTheme(
  Brightness brightness, {
  Locale locale = const Locale('en'),
}) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? CalmPalette.dark : CalmPalette.light;
  final thai = locale.languageCode == 'th';
  final bodyFamily = thai ? 'NotoSansThai' : 'System';
  final headingFamily = thai ? 'NotoSerifThai' : 'Georgia';
  final scheme =
      ColorScheme.fromSeed(
        seedColor: CalmColors.sage,
        brightness: brightness,
        surface: palette.canvas,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.onStrong,
        onSurface: palette.text,
        onSurfaceVariant: palette.textMuted,
        surfaceContainerLow: palette.raised,
        surfaceContainerHighest: palette.line,
        error: palette.danger,
      );
  TextStyle heading(double size) => TextStyle(
    fontFamily: headingFamily,
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: thai ? 1.4 : 1.2,
    color: palette.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [palette],
    scaffoldBackgroundColor: palette.canvas,
    fontFamily: bodyFamily,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.canvas,
      foregroundColor: palette.text,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    textTheme: TextTheme(
      displaySmall: heading(thai ? 34 : 38),
      headlineMedium: heading(thai ? 28 : 30),
      headlineSmall: heading(thai ? 22 : 24),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: thai ? 1.35 : 1.2,
        color: palette.text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: thai ? 1.45 : 1.3,
        color: palette.text,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: thai ? 1.6 : 1.5,
        color: palette.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: thai ? 1.55 : 1.45,
        color: palette.text,
      ),
      bodySmall: TextStyle(
        fontSize: 13.5,
        height: thai ? 1.55 : 1.4,
        color: palette.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: thai ? 1.4 : 1.2,
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.hairline, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: .25),
      selectionHandleColor: palette.accent,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 7,
      activeTrackColor: palette.accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.strong,
      contentTextStyle: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        color: palette.onStrong,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.paper,
      modalBackgroundColor: palette.paper,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
