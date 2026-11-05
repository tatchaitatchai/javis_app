import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/app.dart';
import 'package:javis_app/core/localization/app_localizations.dart';
import 'package:javis_app/features/lighting/lighting_service.dart';
import 'package:javis_app/features/onboarding/welcome_screen.dart';

void main() {
  testWidgets('Launch finishes once while provider initialization runs', (
    tester,
  ) async {
    final service = _CountingLightingService();
    addTearDown(service.dispose);
    await tester.pumpWidget(JavisApp(lightingService: service));
    expect(service.initializations, 1);
    expect(find.byKey(const ValueKey('javis-splash')), findsOneWidget);
    expect(find.byType(LanguageButton).hitTestable(), findsNothing);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const ValueKey('javis-splash')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('javis-splash')), findsNothing);
    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไทย').last);
    await tester.pumpAndSettle();
    expect(find.text('เริ่มต้นด้วยเบอร์มือถือ'), findsOneWidget);
    expect(find.byKey(const ValueKey('javis-splash')), findsNothing);
    expect(service.initializations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion launch uses a short fade and remains readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const JavisApp(themeMode: ThemeMode.dark));
    expect(find.byKey(const ValueKey('javis-splash')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('javis-splash')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('javis-splash')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Language sheet handles large text, selection and dismissal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const JavisApp(themeMode: ThemeMode.dark, showSplash: false),
    );
    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<Locale>), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('English')),
      matchesSemantics(
        label: 'English',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(tester.getSize(find.text('English')).height, greaterThan(40));
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(15, 80));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไทย').last);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(
        of: find.byType(LanguageButton),
        matching: find.text('ไทย'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
    expect(find.text('ภาษา'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('ไทย').last),
      matchesSemantics(
        label: 'ไทย',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

class _CountingLightingService extends MockLightingService {
  int initializations = 0;

  @override
  Future<void> initialize() async {
    initializations++;
    await super.initialize();
  }
}
