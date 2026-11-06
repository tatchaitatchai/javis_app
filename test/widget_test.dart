import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/app.dart';
import 'package:javis_app/core/localization/app_localizations.dart';
import 'package:javis_app/core/theme/app_theme.dart';
import 'package:javis_app/features/lighting/lighting_service.dart';
import 'package:javis_app/features/pairing/nearby_radar.dart';

void main() {
  testWidgets('Existing number signs in with OTP and lands on the home', (
    tester,
  ) async {
    await tester.pumpWidget(const JavisApp(showSplash: false));
    await tester.tap(find.text('Start with your mobile number'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0812345678');
    await tester.pump();
    expect(find.text('081 234 5678'), findsOneWidget);
    await tester.tap(find.text('Send code'));
    await _settleNetwork(tester);

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '000000');
    await _settleNetwork(tester);
    expect(find.text('That code didn’t match. Try again.'), findsOneWidget);

    // The keyboard stays attached: the next digits arrive without a tap.
    tester.testTextInput.enterText('123456');
    await _settleNetwork(tester);
    expect(find.text('บ้านลาดพร้าว'), findsOneWidget);
    expect(find.text('Ceiling light'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A new number creates a profile, a first home and its zones', (
    tester,
  ) async {
    await tester.pumpWidget(const JavisApp(showSplash: false));
    await tester.tap(find.text('Start with your mobile number'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0899999999');
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await _settleNetwork(tester);
    await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
    await _settleNetwork(tester);

    await tester.enterText(find.byType(TextField), 'Ploy');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My home'));
    await tester.pump();
    await tester.tap(find.text('Create home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen'));
    await tester.pump();
    await tester.tap(find.textContaining('Enter home'));
    await tester.pumpAndSettle();

    expect(find.text('My home'), findsOneWidget);
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Ploy'), findsOneWidget);
    expect(find.text('+66 89 999 9999'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A light toggles instantly and its detail keeps the state', (
    tester,
  ) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    expect(service.devices.first.isOn, isTrue);
    await tester.tap(find.bySemanticsLabel('Ceiling light power'));
    await tester.pumpAndSettle();
    expect(service.devices.first.isOn, isFalse);

    await tester.tap(find.text('Ceiling light'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Turn on'));
    await tester.pumpAndSettle();
    expect(service.devices.first.isOn, isTrue);
    expect(find.byTooltip('Turn off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Pairing supports failure, retry, success, naming and duplicate prevention',
    (tester) async {
      final service = MockLightingService();
      addTearDown(service.dispose);
      await _signedIn(tester, service);
      await _openBulbPairing(tester);
      await _waitForSampleBulb(tester);
      await tester.scrollUntilVisible(
        find.text('Preview a failed search'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Preview a failed search'));
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Smart bulb'),
        find.byType(Scrollable).last,
        const Offset(0, 250),
      );
      await tester.tap(find.text('Smart bulb'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to demo home'));
      await tester.pumpAndSettle();
      expect(find.text('Right at home.'), findsOneWidget);
      expect(service.devices.length, 6);
      service.confirmPairing(service.devices.last);
      expect(service.devices.length, 6);

      await tester.enterText(find.byType(TextField), 'Desk lamp');
      await tester.tap(find.text('Kitchen').last);
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Desk lamp'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Kitchen ·'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Lock unlocks only after it reports and relocks by itself', (
    tester,
  ) async {
    await _signedIn(tester, MockLightingService());
    await _scrollTo(tester, find.text('Front door'));
    await tester.tap(find.text('Front door'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Unlock door'));
    await tester.tap(find.text('Unlock door'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byIcon(CupertinoIcons.lock_open_fill),
      const Offset(400, 0),
    );
    await tester.pump();
    expect(find.text('Unlocking…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('Unlocked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A demo scene changes lights and a new scene can be saved', (
    tester,
  ) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    await tester.tap(find.text('Scenes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Start Leave home'));
    await tester.pumpAndSettle();
    expect(service.devices.where((d) => d.online && d.isOn), isEmpty);

    await tester.tap(find.byTooltip('New scene'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Movie night');
    await tester.tap(find.text('Add action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All lights'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Movie night'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Removing a member asks first', (tester) async {
    await _signedIn(tester, MockLightingService());
    await tester.tap(find.bySemanticsLabel('บ้านลาดพร้าว, switch home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings for บ้านลาดพร้าว'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ต้น'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ต้น'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from home'));
    await tester.pumpAndSettle();
    expect(find.text('Remove ต้น from this home?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from home'), findsOneWidget);
    expect(find.text('Members · 3'), findsOneWidget);

    await tester.tap(find.text('Remove from home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from home').last);
    await tester.pumpAndSettle();
    expect(find.text('ต้น'), findsNothing);
    expect(find.text('Members · 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Members can be invited and signing out returns to welcome', (
    tester,
  ) async {
    await _signedIn(tester, MockLightingService());
    await tester.tap(find.bySemanticsLabel('บ้านลาดพร้าว, switch home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings for บ้านลาดพร้าว'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0861112222');
    await tester.pump();
    await tester.ensureVisible(find.text('Send invitation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send invitation'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('086 xxx 2222'));
    await tester.pumpAndSettle();
    expect(find.text('086 xxx 2222'), findsOneWidget);
    expect(find.text('Members · 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    // Let the confirmation snack bar leave before tapping near the bottom.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    expect(find.text('Start with your mobile number'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dark theme and large text keep every tab readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const JavisApp(
        themeMode: ThemeMode.dark,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.text('บ้านลาดพร้าว'))).brightness,
      Brightness.dark,
    );
    await tester.scrollUntilVisible(
      find.text('Ceiling light'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Ceiling light'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ceiling light'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('White temperature'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    for (final tab in ['Scenes', 'Me', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('iPad portrait keeps content at a readable width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const JavisApp(showSplash: false, startSignedIn: true),
    );
    await tester.pumpAndSettle();
    final list = find.byType(ListView).first;
    expect(tester.getSize(list).width, 704);
    expect(tester.getRect(list).center.dx, closeTo(417, .1));
    await _openBulbPairing(tester);
    expect(tester.getSize(find.byType(ListView).last).width, 560);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add device opens straight on the radar, in Thai too', (
    tester,
  ) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    await _openBulbPairing(tester);
    expect(find.byType(NearbyRadar), findsOneWidget);
    expect(find.text('Looking for devices nearby…'), findsOneWidget);
    expect(find.text('Light bulb'), findsNothing);
    _setLocale(tester, const Locale('th'));
    await tester.pump();
    expect(find.text('กำลังค้นหาอุปกรณ์ใกล้ตัว…'), findsOneWidget);
    await _waitForSampleBulb(tester);
    expect(find.text('Smart bulb'), findsOneWidget);
    expect(find.text('พบ 1 อุปกรณ์ · ยังค้นหาต่อ'), findsOneWidget);
    expect(find.byKey(const ValueKey('radar-demo-bulb')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A device can be added from the radar itself', (tester) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    await _openBulbPairing(tester);
    await _waitForSampleBulb(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('radar-demo-bulb')));
    await tester.pump();
    expect(find.byType(NearbyRadar), findsNothing);
    expect(find.text('Searching sample devices…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('The radar fits with text at twice the size', (tester) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openBulbPairing(tester);
    await _waitForSampleBulb(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Table lamp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion leaves the radar still', (tester) async {
    Widget radar({required bool reduced}) => MaterialApp(
      theme: calmTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: NearbyRadar(
            devices: const [NearbyDevice('nearby-1')],
            searching: true,
            onChoose: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(radar(reduced: false));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(radar(reduced: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thai and English switch from Me without losing light state', (
    tester,
  ) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    await tester.tap(find.bySemanticsLabel('Ceiling light power'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไทย'));
    await tester.pumpAndSettle();
    expect(find.text('ภาษา'), findsOneWidget);
    final thaiTheme = Theme.of(tester.element(find.text('ภาษา')));
    expect(thaiTheme.textTheme.displaySmall?.fontFamily, 'NotoSerifThai');
    expect(thaiTheme.textTheme.bodyMedium?.fontFamily, 'NotoSansThai');
    await tester.tap(find.text('หน้าแรก'));
    await tester.pumpAndSettle();
    expect(find.text('ไฟเพดาน'), findsOneWidget);
    expect(service.devices.first.isOn, isFalse);

    await tester.tap(find.text('ฉัน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    final englishTheme = Theme.of(tester.element(find.text('Language')));
    expect(englishTheme.textTheme.displaySmall?.fontFamily, 'Georgia');
    expect(englishTheme.textTheme.bodyMedium?.fontFamily, 'System');
    expect(service.devices.first.isOn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A locale change during discovery keeps one pending search', (
    tester,
  ) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await _signedIn(tester, service);
    await _openBulbPairing(tester);
    await _waitForSampleBulb(tester);
    await tester.tap(find.text('Smart bulb'));
    await tester.pump();
    expect(find.text('Searching sample devices…'), findsOneWidget);
    _setLocale(tester, const Locale('th'));
    await tester.pump();
    expect(find.text('กำลังค้นหาอุปกรณ์ตัวอย่าง…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่มในบ้านตัวอย่าง'));
    await tester.pumpAndSettle();
    expect(find.text('เติมแสงให้บ้านแล้ว'), findsOneWidget);
    expect(service.devices.length, 6);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _signedIn(WidgetTester tester, LightingService service) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    JavisApp(lightingService: service, showSplash: false, startSignedIn: true),
  );
  await tester.pumpAndSettle();
}

/// Dashboard “+” → the radar. It never settles, so the route is pumped for a
/// fixed time.
Future<void> _openBulbPairing(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Add device'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Lets the sample scan find its first device.
Future<void> _waitForSampleBulb(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

/// Lets the simulated network delay finish.
Future<void> _settleNetwork(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void _setLocale(WidgetTester tester, Locale locale) =>
    AppLanguage.of(tester.element(find.byType(Scaffold).last))
        .setLocale(locale);

/// Scrolls the top page; text fields have their own horizontal scrollables.
Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .last,
    );
