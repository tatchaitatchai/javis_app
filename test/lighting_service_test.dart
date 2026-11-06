import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/app.dart';
import 'package:javis_app/app_scope.dart';
import 'package:javis_app/backend/demo_backend.dart';
import 'package:javis_app/core/localization/app_localizations.dart';
import 'package:javis_app/core/widgets/calm_buttons.dart';
import 'package:javis_app/features/account/account_store.dart';
import 'package:javis_app/features/home/home_store.dart';
import 'package:javis_app/features/lighting/light_detail_screen.dart';
import 'package:javis_app/features/lighting/lighting_service.dart';
import 'package:javis_app/features/lighting/tuya_lighting_service.dart';
import 'package:javis_app/features/lock/lock_store.dart';
import 'package:javis_app/features/scenes/scene_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _bleTests();

  test('Provider selection is explicit and unknown values fail closed', () {
    final demo = createLightingService(provider: 'demo');
    final tuya = createLightingService(provider: 'tuya');
    final unknown = createLightingService(provider: 'typo');
    addTearDown(demo.dispose);
    addTearDown(tuya.dispose);
    addTearDown(unknown.dispose);
    expect(demo.isDemo, isTrue);
    expect(tuya.isDemo, isFalse);
    expect(tuya.devices, isEmpty);
    expect(unknown.isDemo, isFalse);
    expect(unknown.readiness, LightingReadiness.invalidProvider);
    expect(unknown.devices, isEmpty);
  });

  testWidgets('Unavailable native mode shows real status and no demo lights', (
    tester,
  ) async {
    final native = _NativeHarness(tester, readiness: 'sdkUnavailable');
    final service = native.service;
    await tester.pumpWidget(
      JavisApp(
        lightingService: service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(service.readiness, LightingReadiness.sdkUnavailable);
    expect(service.devices, isEmpty);
    expect(find.text('Device connection is not installed yet'), findsOneWidget);
    expect(find.text('Ambient lamp'), findsNothing);
    await _openBulbPairing(tester);
    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Try again'),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Start demo pairing'), findsNothing);
    expect(find.text('Preview a failed search'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing method implementation reports SDK unavailable', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _NativeHarness.methods,
      (_) async => throw MissingPluginException(),
    );
    await native.service.initialize();
    expect(native.service.readiness, LightingReadiness.sdkUnavailable);
    expect(native.service.devices, isEmpty);
  });

  testWidgets('An unmapped real bulb never appears off or exposes power', (
    tester,
  ) async {
    final native = _NativeHarness(tester)
      ..devices = [
        {..._bulb, 'isOn': false, 'capabilities': <String, Object>{}},
      ];
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 lights connected · Real devices'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('My light'),
      200,
      scrollable: _pageScroll,
    );
    expect(find.text('Living room · State unavailable'), findsOneWidget);
    expect(find.text('Living room · Off'), findsNothing);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My light'));
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Turn on'), findsNothing);
    expect(find.text('Off'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home setup reuses one request and applies its ready snapshot', (
    tester,
  ) async {
    final native = _NativeHarness(tester, readiness: 'sessionRequired')
      ..prepareHomeGate = Completer<Map<String, Object>>();
    final service = native.service;
    await service.initialize();
    final first = service.prepareHome();
    final second = service.prepareHome();
    expect(identical(first, second), isTrue);
    expect(service.preparingHome, isTrue);
    await tester.pump();
    expect(native.prepareHomeCount, 1);
    native.prepareHomeGate!.complete({
      'readiness': 'ready',
      'devices': [_bulb],
    });
    await first;
    expect(service.preparingHome, isFalse);
    expect(service.readiness, LightingReadiness.ready);
    expect(service.devices.single.id, 'bulb');
  });

  testWidgets('An existing installation restores its paired home on launch', (
    tester,
  ) async {
    final native = _NativeHarness(tester, readiness: 'sessionRequired')
      ..canRestoreHome = true
      ..devices = [_bulb];
    final service = native.service;
    await service.initialize();
    await tester.pump();
    expect(native.prepareHomeCount, 1);
    expect(service.readiness, LightingReadiness.ready);
    expect(service.devices.single.id, 'bulb');
  });

  testWidgets('A fresh installation does not create a home on launch', (
    tester,
  ) async {
    final native = _NativeHarness(tester, readiness: 'sessionRequired');
    await native.service.initialize();
    await tester.pump();
    expect(native.prepareHomeCount, 0);
    expect(native.service.readiness, LightingReadiness.sessionRequired);
  });

  testWidgets('Real pairing rejects missing Wi-Fi before native activation', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await native.service.initialize();
    for (final network in [
      null,
      const WifiPairingConfiguration(ssid: ' ', password: 'example'),
      const WifiPairingConfiguration(ssid: 'Home', password: ''),
    ]) {
      await expectLater(
        native.service.startPairing(network: network),
        throwsA(_error(LightingError.invalidNetwork)),
      );
    }
    expect(native.startCount, 0);
    expect(native.service.pairingActive, isFalse);
  });

  testWidgets('AP flow prepares online, forwards Wi-Fi once and clears retry', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _selectAp(tester);
    await tester.tap(find.text('Set up manually'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Prepare connection'),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pairing-ssid')),
      -200,
      scrollable: _pageScroll,
    );
    await tester.enterText(
      find.byKey(const ValueKey('pairing-ssid')),
      _network.ssid,
    );
    await tester.enterText(
      find.byKey(const ValueKey('pairing-password')),
      _network.password,
    );
    await tester.pump();
    await tester.tap(find.text('Prepare connection'));
    await tester.pumpAndSettle();
    expect(native.preparePairingCount, 1);
    expect(native.startCount, 0);
    expect(find.byKey(const ValueKey('pairing-password')), findsNothing);
    expect(find.text('Open iPhone Settings → Wi-Fi'), findsOneWidget);
    await tester.tap(find.text('I’ve joined the bulb Wi-Fi'));
    await tester.pump();
    expect(native.lastPairing, {
      'operationId': native.service.pairing!.id,
      'ssid': _network.ssid,
      'password': _network.password,
      'mode': 'ap',
    });
    await native.service.cancelPairing();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up manually'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pairing-password')),
      200,
      scrollable: _pageScroll,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('pairing-password')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Prepare connection'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('EZ is the default and missing permission points to bulb Wi-Fi', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _useWifiSetup(tester);
    expect(find.text('Join the bulb’s Wi-Fi · AP setup'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('EZ setup over home Wi-Fi needs Apple'),
      150,
      scrollable: _pageScroll,
    );
    expect(
      find.textContaining('EZ setup over home Wi-Fi needs Apple'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pairing-password')), findsNothing);
    expect(native.discoveryCalls, isEmpty);
    expect(native.startCount, 0);
    expect(native.preparePairingCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'EZ prepares on home Wi-Fi and activates without hotspot search',
    (tester) async {
      final native = _NativeHarness(tester)..ezAvailable = true;
      await tester.pumpWidget(
        JavisApp(
          lightingService: native.service,
          showSplash: false,
          startSignedIn: true,
        ),
      );
      await tester.pumpAndSettle();
      await _openBulbPairing(tester);
      await _useWifiSetup(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pairing-password')),
        150,
        scrollable: _pageScroll,
      );
      expect(find.text(_network.ssid), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('pairing-password')),
        _network.password,
      );
      await tester.pump();
      await tester.tap(find.text('Connect a light'));
      await tester.pump();
      expect(native.discoveryCalls, ['currentWifi', 'preparePairing']);
      expect(native.capabilitiesCount, 2);
      expect(native.lastPairing, {
        'operationId': native.service.pairing!.id,
        'ssid': _network.ssid,
        'password': _network.password,
        'mode': 'ez',
      });
      expect(find.text('Open iPhone Settings → Wi-Fi'), findsNothing);
      expect(find.byKey(const ValueKey('pairing-password')), findsNothing);
      native.devices = [_bulb];
      native.emit({
        'type': 'pairing',
        'operationId': native.service.pairing!.id,
        'status': 'success',
        'deviceId': 'bulb',
      });
      await tester.pumpAndSettle();
      expect(find.text('Right at home.'), findsOneWidget);
      expect(native.service.devices.single.id, 'bulb');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EZ service rechecks permission before any native activation', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await native.service.initialize();
    await expectLater(
      native.service.startPairing(network: _ezNetwork),
      throwsA(_error(LightingError.multicastEntitlementRequired)),
    );
    expect(native.startCount, 0);
    expect(native.service.pairingActive, isFalse);
  });

  testWidgets(
    'Cancelling an EZ capability check cannot start late activation',
    (tester) async {
      final native = _NativeHarness(tester)
        ..capabilitiesGate = Completer<Map<String, Object?>>();
      await native.service.initialize();
      final pairing = native.service.startPairing(network: _ezNetwork);
      final rejected = expectLater(
        pairing,
        throwsA(_error(LightingError.cancelled)),
      );
      await tester.pump();
      await native.service.cancelPairing();
      await rejected;
      native.capabilitiesGate!.complete({'ezAvailable': true});
      await tester.pump();
      expect(native.startCount, 0);
      expect(native.service.pairingActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Discovery precedes Wi-Fi entry and offers real network choices',
    (tester) async {
      final native = _NativeHarness(tester)
        ..wifiNetworks = [
          {'ssid': 'Other home'},
          {'ssid': 'Other home'},
          {'ssid': ''},
        ];
      await tester.pumpWidget(
        JavisApp(
          lightingService: native.service,
          showSplash: false,
          startSignedIn: true,
        ),
      );
      await tester.pumpAndSettle();
      await _openBulbPairing(tester);
      await _selectAp(tester);
      expect(find.byKey(const ValueKey('pairing-ssid')), findsNothing);
      expect(find.byKey(const ValueKey('pairing-password')), findsNothing);
      await tester.tap(find.text('Find device hotspot'));
      await tester.pumpAndSettle();
      expect(native.discoveryCalls, [
        'currentWifi',
        'preparePairing',
        'discoverBulbHotspot',
        'listBulbWifi',
      ]);
      expect(native.startCount, 0);
      expect(native.cancelSetupCount, 1);
      expect(native.service.devices, isEmpty);
      expect(find.textContaining('Device hotspot found.'), findsOneWidget);
      expect(find.text(_network.ssid), findsNothing);
      expect(find.byKey(const ValueKey('pairing-ssid')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('choose-home-wifi')),
        150,
        scrollable: _pageScroll,
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose Wi-Fi'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.widgetWithText(PrimaryButton, 'Connect a light'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('choose-home-wifi')));
      await tester.pumpAndSettle();
      expect(find.text('Other home'), findsOneWidget);
      await tester.tap(find.text('Other home'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('pairing-password')),
        _network.password,
      );
      await tester.pump();
      await tester.tap(find.text('Connect a light'));
      await tester.pump();
      expect(native.cancelSetupCount, 1);
      expect(native.lastPairing, {
        'operationId': native.service.pairing!.id,
        'ssid': 'Other home',
        'password': _network.password,
        'mode': 'ap',
      });
      await native.service.cancelPairing();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Discovery failure has manual fallback and no invented result', (
    tester,
  ) async {
    final native = _NativeHarness(tester)..discoveryError = 'noDevices';
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _selectAp(tester);
    await tester.tap(find.text('Find device hotspot'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No supported device hotspot'), findsOneWidget);
    expect(find.textContaining('Device hotspot found.'), findsNothing);
    expect(find.byKey(const ValueKey('pairing-password')), findsNothing);
    await tester.tap(find.text('Set up manually'));
    await tester.pumpAndSettle();
    expect(native.cancelSetupCount, 2);
    expect(find.byKey(const ValueKey('pairing-password')), findsOneWidget);
    expect(find.text(_network.ssid), findsOneWidget);
    expect(native.startCount, 0);
  });

  testWidgets(
    'Unavailable Wi-Fi list cancels setup and requires the manual AP flow',
    (tester) async {
      final native = _NativeHarness(tester)..wifiListError = true;
      await tester.pumpWidget(
        JavisApp(
          lightingService: native.service,
          showSplash: false,
          startSignedIn: true,
        ),
      );
      await tester.pumpAndSettle();
      await _openBulbPairing(tester);
      await _selectAp(tester);
      await tester.tap(find.text('Find device hotspot'));
      await tester.pumpAndSettle();
      expect(native.cancelSetupCount, 2);
      expect(find.text('Connect a light'), findsNothing);
      expect(find.text('Prepare connection'), findsOneWidget);
      expect(
        find.textContaining('Reconnect iPhone to home Wi-Fi first'),
        findsOneWidget,
      );
      expect(find.textContaining('Device hotspot found.'), findsNothing);
      expect(find.byKey(const ValueKey('selected-home-wifi')), findsOneWidget);
      expect(find.byKey(const ValueKey('choose-home-wifi')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Enter another network'),
        150,
        scrollable: _pageScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter another network'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('pairing-ssid')))
            .controller!
            .text,
        _network.ssid,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Leaving during network permission ignores its late reply', (
    tester,
  ) async {
    final native = _NativeHarness(tester)
      ..currentWifiGate = Completer<Map<String, Object?>>();
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _selectAp(tester);
    await tester.tap(find.text('Find device hotspot'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Finding device hotspot…'), findsOneWidget);
    expect(native.preparePairingCount, 0);
    await tester.tap(find.byType(CalmBackButton).first);
    await tester.pumpAndSettle();
    expect(native.cancelSetupCount, 2);
    native.currentWifiGate!.complete({'ssid': _network.ssid});
    await tester.pumpAndSettle();
    expect(native.preparePairingCount, 0);
    expect(native.discoveryCalls, ['currentWifi']);
    expect(native.service.devices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Leaving during the Wi-Fi query cancels native setup work', (
    tester,
  ) async {
    final native = _NativeHarness(tester)
      ..wifiListGate = Completer<Map<String, Object>>();
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _selectAp(tester);
    await tester.tap(find.text('Find device hotspot'));
    await tester.pumpAndSettle();
    expect(native.cancelSetupCount, 1);
    expect(find.text('Checking available Wi-Fi…'), findsOneWidget);
    await tester.tap(find.byType(CalmBackButton).first);
    await tester.pumpAndSettle();
    expect(native.cancelSetupCount, 2);
    native.wifiListGate!.complete({
      'networks': [
        {'ssid': 'Late home network'},
      ],
    });
    await tester.pumpAndSettle();
    expect(native.startCount, 0);
    expect(native.service.devices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Setup cancellation does not cancel an active pairing', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    final service = native.service;
    await service.initialize();
    final pairing = service.startPairing(network: _network);
    final cancelled = expectLater(
      pairing,
      throwsA(_error(LightingError.cancelled)),
    );
    await service.cancelSetup();
    expect(native.cancelSetupCount, 1);
    expect(service.pairingActive, isTrue);
    expect(native.cancelled, isEmpty);
    await service.cancelPairing();
    await cancelled;
  });

  testWidgets('Cancelled discovery cannot overwrite a new setup request', (
    tester,
  ) async {
    final native = _NativeHarness(tester)
      ..hotspotGate = Completer<Map<String, Object>>();
    final service = native.service;
    await service.initialize();
    final firstGate = native.hotspotGate!;
    final first = service.discoverBulbHotspot();
    final firstCancelled = expectLater(
      first,
      throwsA(_error(LightingError.cancelled)),
    );
    await service.cancelSetup();
    native.hotspotGate = Completer<Map<String, Object>>();
    final second = service.discoverBulbHotspot();
    firstGate.complete({'ssid': 'SmartLife-old'});
    await firstCancelled;
    expect(identical(second, service.discoverBulbHotspot()), isTrue);
    native.hotspotGate!.complete({'ssid': 'SmartLife-new'});
    expect((await second).ssid, 'SmartLife-new');
    expect(native.service.devices, isEmpty);
  });

  testWidgets('Location denial leaves a usable manual home-network form', (
    tester,
  ) async {
    final native = _NativeHarness(tester)
      ..currentWifiError = 'permissionDenied';
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _selectAp(tester);
    await tester.tap(find.text('Find device hotspot'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pairing-ssid')),
      150,
      scrollable: _pageScroll,
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('pairing-ssid')),
    );
    expect(field.controller!.text, isEmpty);
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Prepare connection'),
          )
          .onPressed,
      isNull,
    );
    expect(native.service.readiness, LightingReadiness.ready);
    expect(native.service.devices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('One pairing, cancellation and stale events cannot add a light', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    final service = native.service;
    await service.initialize();
    final attempt = service.startPairing(network: _network);
    final cancelled = expectLater(
      attempt,
      throwsA(_error(LightingError.cancelled)),
    );
    final oldId = service.pairing!.id;
    await expectLater(
      service.startPairing(network: _network),
      throwsA(_error(LightingError.busy)),
    );
    await service.cancelPairing();
    await cancelled;
    expect(native.cancelled, [oldId]);
    expect(service.pairing!.phase, PairingPhase.cancelled);
    expect(service.pairingActive, isFalse);
    final next = service.startPairing(network: _network);
    final nextCancelled = expectLater(
      next,
      throwsA(_error(LightingError.cancelled)),
    );
    final newId = service.pairing!.id;
    expect(newId, isNot(oldId));
    native.emit({
      'type': 'pairing',
      'operationId': oldId,
      'status': 'success',
      'deviceId': 'bulb',
    });
    await tester.pump();
    expect(service.pairing!.id, newId);
    expect(service.pairingActive, isTrue);
    expect(service.devices, isEmpty);
    await service.cancelPairing();
    await nextCancelled;
  });

  testWidgets(
    'Provider success refreshes before adding and deduplicates snapshots',
    (tester) async {
      final native = _NativeHarness(tester);
      final service = native.service;
      await service.initialize();
      final attempt = service.startPairing(network: _network);
      native.devices = [_bulb, _bulb];
      native.emit({
        'type': 'pairing',
        'operationId': service.pairing!.id,
        'status': 'success',
        'deviceId': 'bulb',
      });
      await tester.pump();
      final light = await attempt;
      expect(light.id, 'bulb');
      expect(service.devices.length, 1);
      expect(service.pairing!.phase, PairingPhase.success);
      expect(native.refreshCount, 1);
    },
  );

  for (final streamFailure in [false, true]) {
    testWidgets(
      'Accepted pairing stops native work after ${streamFailure ? 'stream' : 'readiness'} failure',
      (tester) async {
        final native = _NativeHarness(tester);
        final service = native.service;
        await service.initialize();
        final attempt = service.startPairing(network: _network);
        final failed = expectLater(
          attempt,
          throwsA(
            _error(
              streamFailure
                  ? LightingError.transportFailure
                  : LightingError.unavailable,
            ),
          ),
        );
        final operationId = service.pairing!.id;
        await tester.pump();
        expect(native.startCount, 1);
        // Cleanup failure must not replace the event that ended pairing.
        native.cancelFailure = true;
        if (streamFailure) {
          native.failStream();
        } else {
          native.emit({'type': 'readiness', 'readiness': 'sessionRequired'});
        }
        await tester.pump();
        await failed;
        expect(native.cancelled, [operationId]);
        expect(service.pairing!.phase, PairingPhase.failed);
        expect(service.devices, isEmpty);
      },
    );
  }

  testWidgets(
    'Session loss during post-pair refresh rejects the stale success',
    (tester) async {
      final native = _NativeHarness(tester);
      final service = native.service;
      await service.initialize();
      native.refreshGate = Completer<Map<String, Object>>();
      final attempt = service.startPairing(network: _network);
      final failed = expectLater(
        attempt,
        throwsA(_error(LightingError.unavailable)),
      );
      final operationId = service.pairing!.id;
      native.emit({
        'type': 'pairing',
        'operationId': operationId,
        'status': 'success',
        'deviceId': 'bulb',
      });
      await tester.pump();
      expect(native.refreshCount, 1);
      native.emit({'type': 'readiness', 'readiness': 'sessionRequired'});
      await tester.pump();
      native.refreshGate!.complete({
        'devices': [_bulb],
      });
      await tester.pump();
      await failed;
      expect(service.readiness, LightingReadiness.sessionRequired);
      expect(service.devices, isEmpty);
      expect(service.pairing!.phase, PairingPhase.failed);
      expect(native.cancelled, [operationId]);
    },
  );

  testWidgets('Delayed refresh cannot restore devices after a session cycle', (
    tester,
  ) async {
    final native = _NativeHarness(tester)..devices = [_bulb];
    final service = native.service;
    await service.initialize();
    native.refreshGate = Completer<Map<String, Object>>();
    final refresh = service.refreshDevices();
    final failed = expectLater(
      refresh,
      throwsA(_error(LightingError.unavailable)),
    );
    native.emit({'type': 'readiness', 'readiness': 'sessionRequired'});
    await tester.pump();
    native.emit({'type': 'readiness', 'readiness': 'ready'});
    await tester.pump();
    native.refreshGate!.complete({
      'devices': [_bulb],
    });
    await failed;
    expect(service.readiness, LightingReadiness.ready);
    expect(service.devices, isEmpty);
  });

  testWidgets(
    'Delayed initialization cannot overwrite a newer session status',
    (tester) async {
      final native = _NativeHarness(tester)
        ..initializationGate = Completer<Map<String, Object>>();
      final service = native.service;
      final initialization = service.initialize();
      await tester.pump();
      native.emit({'type': 'readiness', 'readiness': 'sessionRequired'});
      await tester.pump();
      native.initializationGate!.complete({
        'readiness': 'ready',
        'devices': [_bulb],
      });
      await initialization;
      expect(service.readiness, LightingReadiness.sessionRequired);
      expect(service.devices, isEmpty);
    },
  );

  testWidgets(
    'Command failure and acceptance never replace confirmed device state',
    (tester) async {
      final native = _NativeHarness(tester)..devices = [_bulb];
      final service = native.service;
      await service.initialize();
      native.commandFailure = true;
      await expectLater(
        service.sendCommand('bulb', const LightCommand(isOn: false)),
        throwsA(_error(LightingError.transportFailure)),
      );
      expect(service.devices.single.isOn, isTrue);
      expect(service.isCommandPending('bulb'), isFalse);
      native.commandFailure = false;
      await service.sendCommand('bulb', const LightCommand(isOn: false));
      expect(service.devices.single.isOn, isTrue);
      expect(native.lastCommand, {
        'deviceId': 'bulb',
        'command': {'isOn': false},
      });
      native.emit({
        'type': 'devices',
        'devices': [
          {..._bulb, 'isOn': false},
        ],
      });
      await tester.pump();
      expect(service.devices.single.isOn, isFalse);
      await expectLater(
        service.sendCommand('bulb', const LightCommand(brightness: .4)),
        throwsA(_error(LightingError.unsupportedCommand)),
      );
    },
  );

  testWidgets(
    'Concurrent commands are rejected until the device command completes',
    (tester) async {
      final native = _NativeHarness(tester)..devices = [_bulb];
      final service = native.service;
      await service.initialize();
      native.commandGate = Completer<Map<String, Object>>();
      final first = service.sendCommand(
        'bulb',
        const LightCommand(isOn: false),
      );
      expect(service.isCommandPending('bulb'), isTrue);
      await expectLater(
        service.sendCommand('bulb', const LightCommand(isOn: true)),
        throwsA(_error(LightingError.busy)),
      );
      native.commandGate!.complete({});
      await first;
      expect(service.isCommandPending('bulb'), isFalse);
    },
  );

  testWidgets(
    'Removal waits for provider success and preserves light on failure',
    (tester) async {
      final native = _NativeHarness(tester)..devices = [_bulb];
      final service = native.service;
      await service.initialize();
      native.removalGate = Completer<Map<String, Object>>();
      final removal = service.removeDevice('bulb');
      expect(service.isRemovalPending('bulb'), isTrue);
      expect(service.devices.single.id, 'bulb');
      await expectLater(
        service.removeDevice('bulb'),
        throwsA(_error(LightingError.busy)),
      );
      await expectLater(
        service.sendCommand('bulb', const LightCommand(isOn: false)),
        throwsA(_error(LightingError.busy)),
      );
      native.removalGate!.completeError(
        PlatformException(code: 'transportFailure'),
      );
      await expectLater(
        removal,
        throwsA(_error(LightingError.transportFailure)),
      );
      expect(service.isRemovalPending('bulb'), isFalse);
      expect(service.devices.single.id, 'bulb');

      native.removalGate = null;
      await service.removeDevice('bulb');
      expect(native.lastRemoval, {'deviceId': 'bulb'});
      expect(service.devices, isEmpty);
      expect(service.isRemovalPending('bulb'), isFalse);
    },
  );

  testWidgets('Remove confirmation can be cancelled before any native call', (
    tester,
  ) async {
    final native = _NativeHarness(tester)..devices = [_bulb];
    await native.service.initialize();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _scoped(
          native.service,
          const LightDetailScreen(deviceId: 'bulb'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Remove light'),
      200,
      scrollable: _pageScroll,
    );
    await tester.tap(find.text('Remove light'));
    await tester.pumpAndSettle();
    expect(find.text('Let this light go?'), findsOneWidget);
    expect(native.removeCount, 0);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Let this light go?'), findsNothing);
    expect(native.removeCount, 0);
    expect(native.service.devices.single.id, 'bulb');
  });

  testWidgets('Confirmed removal calls native and clears the real light', (
    tester,
  ) async {
    final native = _NativeHarness(tester)..devices = [_bulb];
    await native.service.initialize();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _scoped(
          native.service,
          const LightDetailScreen(deviceId: 'bulb'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Remove light'),
      200,
      scrollable: _pageScroll,
    );
    await tester.tap(find.text('Remove light'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(FilledButton, 'Remove light');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(native.removeCount, 1);
    expect(native.service.devices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Demo light does not offer real-device removal', (tester) async {
    final service = MockLightingService();
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _scoped(
          service,
          const LightDetailScreen(deviceId: 'living-lamp'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remove light'), findsNothing);
    await expectLater(
      service.removeDevice('living-lamp'),
      throwsA(_error(LightingError.unavailable)),
    );
  });

  testWidgets(
    'Leaving pairing route cancels transport and ignores late success',
    (tester) async {
      final native = _NativeHarness(tester);
      await tester.pumpWidget(
        JavisApp(
          lightingService: native.service,
          showSplash: false,
          startSignedIn: true,
        ),
      );
      await tester.pumpAndSettle();
      await _openBulbPairing(tester);
      await _selectAp(tester);
      await tester.tap(find.text('Set up manually'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pairing-ssid')),
        200,
        scrollable: _pageScroll,
      );
      await tester.enterText(
        find.byKey(const ValueKey('pairing-ssid')),
        _network.ssid,
      );
      await tester.enterText(
        find.byKey(const ValueKey('pairing-password')),
        _network.password,
      );
      await tester.pump();
      await tester.tap(find.text('Prepare connection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I’ve joined the bulb Wi-Fi'));
      await tester.pump();
      final operationId = native.service.pairing!.id;
      await tester.tap(find.byType(CalmBackButton).first);
      await tester.pumpAndSettle();
      expect(native.cancelled, [operationId]);
      native.emit({
        'type': 'pairing',
        'operationId': operationId,
        'status': 'success',
        'deviceId': 'bulb',
      });
      await tester.pumpAndSettle();
      expect(native.service.devices, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

void _bleTests() {
  testWidgets('Pairing opens on a Bluetooth scan and a found light pops up', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    expect(native.startScanCount, 1);
    expect(find.text('Looking for devices nearby…'), findsOneWidget);
    expect(find.text('Open iPhone Settings → Wi-Fi'), findsNothing);
    native.emit({
      'type': 'nearby',
      'devices': [
        {'id': 'nearby-1'},
        {'id': 'nearby-1'},
      ],
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(native.service.nearbyDevices.length, 1);
    expect(find.text('New device 1'), findsOneWidget);
    native.emit({
      'type': 'nearby',
      'devices': [
        {
          'id': 'nearby-1',
          'name': ' Wi-Fi Smart Lock ',
          'iconUrl': 'http://not-secure.example/icon.png',
        },
        {'id': '', 'name': 'No id'},
      ],
    });
    await tester.pump();
    expect(native.service.nearbyDevices.single.iconUrl, isNull);
    await tester.tap(find.byKey(const ValueKey('radar-nearby-1')));
    await tester.pumpAndSettle();
    expect(find.text('Wi-Fi Smart Lock'), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-home-wifi')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pairing-password')),
      150,
      scrollable: _pageScroll,
    );
    await tester.enterText(
      find.byKey(const ValueKey('pairing-password')),
      _network.password,
    );
    await tester.pump();
    await tester.tap(find.text('Connect device'));
    await tester.pump();
    expect(native.preparePairingCount, 0);
    expect(native.lastPairing, {
      'operationId': native.service.pairing!.id,
      'ssid': _network.ssid,
      'password': _network.password,
      'mode': 'ble',
      'deviceId': 'nearby-1',
    });
    native.devices = [_bulb];
    native.emit({
      'type': 'pairing',
      'operationId': native.service.pairing!.id,
      'status': 'success',
      'deviceId': 'bulb',
    });
    await tester.pumpAndSettle();
    expect(find.text('Right at home.'), findsOneWidget);
    expect(native.service.devices.single.id, 'bulb');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bluetooth off and denied are explained, and on resumes', (
    tester,
  ) async {
    final native = _NativeHarness(tester)..bluetooth = 'off';
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    expect(find.textContaining('Bluetooth is off.'), findsOneWidget);
    native.emit({'type': 'bluetooth', 'state': 'unauthorized'});
    await tester.pump();
    expect(find.textContaining('not allowed to use Bluetooth'), findsOneWidget);
    native.emit({'type': 'bluetooth', 'state': 'on'});
    await tester.pump();
    expect(find.textContaining('Bluetooth is off.'), findsNothing);
    expect(find.textContaining('not allowed to use Bluetooth'), findsNothing);
    expect(find.text('Looking for devices nearby…'), findsOneWidget);
    expect(native.startScanCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wi-Fi setup and leaving stop the scan; late finds are ignored', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await tester.pumpWidget(
      JavisApp(
        lightingService: native.service,
        showSplash: false,
        startSignedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    await _openBulbPairing(tester);
    await _useWifiSetup(tester);
    expect(native.stopScanCount, 1);
    expect(native.service.scanning, isFalse);
    native.emit({
      'type': 'nearby',
      'devices': [
        {'id': 'nearby-1'},
      ],
    });
    await tester.pump();
    expect(native.service.nearbyDevices, isEmpty);
    expect(find.text('New device 1'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('use-nearby-setup')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(native.startScanCount, 2);
    await tester.tap(find.byType(CalmBackButton).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(native.stopScanCount, greaterThanOrEqualTo(2));
    native.emit({
      'type': 'nearby',
      'devices': [
        {'id': 'nearby-2'},
      ],
    });
    await tester.pumpAndSettle();
    expect(native.service.nearbyDevices, isEmpty);
    expect(native.startCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bluetooth pairing needs a nearby device before activation', (
    tester,
  ) async {
    final native = _NativeHarness(tester);
    await native.service.initialize();
    await expectLater(
      native.service.startPairing(
        network: const WifiPairingConfiguration(
          ssid: 'Demo Wi-Fi',
          password: 'example-password',
          mode: WifiPairingMode.ble,
        ),
      ),
      throwsA(_error(LightingError.invalidNetwork)),
    );
    expect(native.startCount, 0);
  });
}

Matcher _error(LightingError code) =>
    isA<LightingException>().having((e) => e.code, 'code', code);

Finder get _pageScroll => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    )
    .last;

/// Leaves the Bluetooth scan for the Wi-Fi (EZ/AP) fallback.
Future<void> _useWifiSetup(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('use-wifi-setup')));
  await tester.pumpAndSettle();
}

Future<void> _selectAp(WidgetTester tester) async {
  await _useWifiSetup(tester);
  await tester.ensureVisible(find.byKey(const ValueKey('pairing-mode-ap')));
  await tester.tap(find.byKey(const ValueKey('pairing-mode-ap')));
  await tester.pumpAndSettle();
}

const _network = WifiPairingConfiguration(
  ssid: 'Demo Wi-Fi',
  password: 'example-password',
);

const _ezNetwork = WifiPairingConfiguration(
  ssid: 'Demo Wi-Fi',
  password: 'example-password',
  mode: WifiPairingMode.ez,
);

const _bulb = <String, Object>{
  'id': 'bulb',
  'name': 'My light',
  'room': 'Living room',
  'isOn': true,
  'online': true,
  'capabilities': {'power': true},
};

class _NativeHarness {
  _NativeHarness(WidgetTester tester, {this.readiness = 'ready'}) {
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          _sink = sink;
        },
      ),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(methods, (
      call,
    ) async {
      switch (call.method) {
        case 'initialize':
          if (initializationGate != null) {
            return await initializationGate!.future;
          }
          return {
            'readiness': readiness,
            'devices': devices,
            'canRestoreHome': canRestoreHome,
          };
        case 'refreshDevices':
          refreshCount++;
          if (refreshGate != null) return await refreshGate!.future;
          return {'devices': devices};
        case 'preparePairing':
          discoveryCalls.add('preparePairing');
          preparePairingCount++;
          return {};
        case 'pairingCapabilities':
          capabilitiesCount++;
          if (capabilitiesGate != null) return await capabilitiesGate!.future;
          return {
            'ezAvailable': ezAvailable,
            'ezReason': ezAvailable ? null : 'multicastEntitlementRequired',
          };
        case 'currentWifi':
          discoveryCalls.add('currentWifi');
          if (currentWifiError != null) {
            throw PlatformException(code: currentWifiError!);
          }
          if (currentWifiGate != null) return await currentWifiGate!.future;
          return {'ssid': currentSsid};
        case 'discoverBulbHotspot':
          discoveryCalls.add('discoverBulbHotspot');
          if (discoveryError != null) {
            throw PlatformException(code: discoveryError!);
          }
          if (hotspotGate != null) return await hotspotGate!.future;
          return {'ssid': 'SmartLife-setup', 'name': 'Device hotspot'};
        case 'listBulbWifi':
          discoveryCalls.add('listBulbWifi');
          if (wifiListError) throw PlatformException(code: 'unavailable');
          if (wifiListGate != null) return await wifiListGate!.future;
          return {'networks': wifiNetworks};
        case 'cancelSetup':
          cancelSetupCount++;
          return {'cancelled': true};
        case 'startDeviceScan':
          startScanCount++;
          if (scanError != null) throw PlatformException(code: scanError!);
          return {'bluetooth': bluetooth};
        case 'stopDeviceScan':
          stopScanCount++;
          return {'stopped': true};
        case 'prepareHome':
          prepareHomeCount++;
          if (prepareHomeGate != null) return await prepareHomeGate!.future;
          return {'readiness': 'ready', 'devices': devices};
        case 'startPairing':
          startCount++;
          lastPairing = call.arguments;
          return {};
        case 'cancelPairing':
          cancelled.add((call.arguments as Map)['operationId'] as String);
          if (cancelFailure) throw PlatformException(code: 'sdkUnavailable');
          return {'cancelled': true};
        case 'sendCommand':
          lastCommand = call.arguments;
          if (commandFailure) throw PlatformException(code: 'transportFailure');
          return commandGate == null ? {} : await commandGate!.future;
        case 'removeDevice':
          removeCount++;
          lastRemoval = call.arguments;
          if (removalGate != null) return await removalGate!.future;
          devices = [];
          return {'devices': devices};
      }
      throw MissingPluginException();
    });
    addTearDown(service.dispose);
  }
  static const methods = MethodChannel('test/javis/lighting');
  static const events = EventChannel('test/javis/lighting/events');
  final service = TuyaLightingService(methods: methods, events: events);
  final String readiness;
  MockStreamHandlerEventSink? _sink;
  List<Map<String, Object>> devices = [];
  final List<String> cancelled = [];
  bool commandFailure = false;
  bool canRestoreHome = false;
  bool cancelFailure = false;
  int startCount = 0;
  int removeCount = 0;
  int refreshCount = 0;
  int prepareHomeCount = 0;
  int preparePairingCount = 0;
  int cancelSetupCount = 0;
  int capabilitiesCount = 0;
  int startScanCount = 0;
  int stopScanCount = 0;
  String bluetooth = 'on';
  String? scanError;
  bool ezAvailable = false;
  final List<String> discoveryCalls = [];
  String? currentSsid = _network.ssid;
  String? currentWifiError;
  String? discoveryError;
  bool wifiListError = false;
  List<Map<String, Object>> wifiNetworks = [];
  Object? lastPairing;
  Object? lastCommand;
  Object? lastRemoval;
  Completer<Map<String, Object>>? removalGate;
  Completer<Map<String, Object>>? commandGate;
  Completer<Map<String, Object>>? refreshGate;
  Completer<Map<String, Object>>? initializationGate;
  Completer<Map<String, Object>>? prepareHomeGate;
  Completer<Map<String, Object?>>? currentWifiGate;
  Completer<Map<String, Object>>? wifiListGate;
  Completer<Map<String, Object>>? hotspotGate;
  Completer<Map<String, Object?>>? capabilitiesGate;
  void emit(Map<String, Object> value) => _sink!.success(value);
  void failStream() => _sink!.error(code: 'transportFailure');
}

/// Dashboard “+” → the radar. Its sweep never settles, so the route
/// transition is pumped for a fixed time.
Future<void> _openBulbPairing(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Add device'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Detail screens read their services from [AppScope].
Widget _scoped(LightingService service, Widget child) {
  final backend = DemoBackend();
  final homes = HomeStore(backend)..adopt(backend.demoAccount());
  final account = AccountStore(backend)..signInDemo();
  return AppScope(
    lighting: service,
    account: account,
    homes: homes,
    lock: LockStore(),
    scenes: SceneStore(backend)..adopt(homes.activeHome!.id, backend.scenes),
    child: child,
  );
}
