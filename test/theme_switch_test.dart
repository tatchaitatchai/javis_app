import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/app.dart';
import 'package:javis_app/core/theme/app_appearance.dart';

class _RecordingPreference implements ThemePreference {
  final saved = <ThemeMode>[];

  @override
  Future<ThemeMode> read() async => ThemeMode.system;

  @override
  Future<void> write(ThemeMode mode) async => saved.add(mode);
}

Future<void> _openProfile(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Me'));
  await tester.pumpAndSettle();
}

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.text('Theme'))).brightness;

SystemUiOverlayStyle _statusBar(WidgetTester tester) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    )
    .value;

void main() {
  group('Theme control', () {
    testWidgets('choosing dark recolors the app and is saved', (tester) async {
      final preference = _RecordingPreference();
      await _openProfile(
        tester,
        JavisApp(
          showSplash: false,
          startSignedIn: true,
          themeMode: ThemeMode.light,
          themePreference: preference,
        ),
      );
      expect(_brightness(tester), Brightness.light);
      expect(_statusBar(tester), SystemUiOverlayStyle.dark);

      await tester.ensureVisible(find.text('Dark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(_brightness(tester), Brightness.dark);
      expect(_statusBar(tester), SystemUiOverlayStyle.light);
      expect(preference.saved, [ThemeMode.dark]);
    });

    testWidgets('System follows the iPhone setting again', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _openProfile(
        tester,
        const JavisApp(
          showSplash: false,
          startSignedIn: true,
          themeMode: ThemeMode.light,
        ),
      );
      expect(_brightness(tester), Brightness.light);

      await tester.ensureVisible(find.text('System'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(_brightness(tester), Brightness.dark);
    });

    testWidgets('labels stay on one line at large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openProfile(
        tester,
        const JavisApp(showSplash: false, startSignedIn: true),
      );

      await tester.scrollUntilVisible(
        find.text('System'),
        200,
        scrollable: find
            .ancestor(
              of: find.text('My homes'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final fitted = find.ancestor(
        of: find.text('System'),
        matching: find.byType(FittedBox),
      );
      expect(fitted, findsOneWidget);
    });
  });

  group('DeviceThemePreference', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.javis.home/theme');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const preference = DeviceThemePreference();

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    void answerRead(Object? Function() answer) =>
        messenger.setMockMethodCallHandler(channel, (_) async => answer());

    test('reads a stored choice', () async {
      answerRead(() => 'dark');
      expect(await preference.read(), ThemeMode.dark);
    });

    test('nothing stored means System', () async {
      answerRead(() => null);
      expect(await preference.read(), ThemeMode.system);
    });

    test('an unknown value means System', () async {
      answerRead(() => 'sepia');
      expect(await preference.read(), ThemeMode.system);
    });

    test('a native failure means System', () async {
      answerRead(() => throw PlatformException(code: 'failed'));
      expect(await preference.read(), ThemeMode.system);
    });

    test('missing native storage means System', () async {
      expect(await preference.read(), ThemeMode.system);
      await preference.write(ThemeMode.dark);
    });

    test('writes the mode name', () async {
      MethodCall? call;
      messenger.setMockMethodCallHandler(channel, (received) async {
        call = received;
        return null;
      });
      await preference.write(ThemeMode.light);
      expect(call?.method, 'write');
      expect(call?.arguments, {'mode': 'light'});
    });
  });
}
