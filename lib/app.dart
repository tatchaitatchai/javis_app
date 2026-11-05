import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/launch_experience.dart';
import 'features/account/account_store.dart';
import 'features/home/home_store.dart';
import 'features/lighting/lighting_service.dart';
import 'features/lighting/tuya_lighting_service.dart';
import 'features/lock/lock_store.dart';
import 'features/scenes/scene_store.dart';
import 'features/shell/app_root.dart';

class JavisApp extends StatefulWidget {
  const JavisApp({
    super.key,
    this.lightingService,
    this.themeMode = ThemeMode.system,
    this.showSplash = true,
    this.startSignedIn = false,
  });
  final LightingService? lightingService;
  final ThemeMode themeMode;
  final bool showSplash;

  /// Opens the seeded demo account instead of the welcome screen.
  final bool startSignedIn;
  @override
  State<JavisApp> createState() => _JavisAppState();
}

class _JavisAppState extends State<JavisApp> with WidgetsBindingObserver {
  Locale? _locale;
  late final LightingService _service =
      widget.lightingService ?? createLightingService();
  final _account = AccountStore();
  final _homes = HomeStore();
  final _lock = LockStore();
  final _scenes = SceneStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_service.initialize());
    if (widget.startSignedIn) {
      _account.signInDemo();
      _homes.loadDemoAccount(
        yourName: _account.name,
        yourPhone: _account.phone!,
      );
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_locale == null) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.lightingService == null) _service.dispose();
    _account.dispose();
    _homes.dispose();
    _lock.dispose();
    _scenes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale =
        _locale ??
        basicLocaleListResolution(
          WidgetsBinding.instance.platformDispatcher.locales,
          AppLocalizations.supportedLocales,
        );
    return AppLanguage(
      setLocale: (locale) => setState(() => _locale = locale),
      child: AppScope(
        lighting: _service,
        account: _account,
        homes: _homes,
        lock: _lock,
        scenes: _scenes,
        child: MaterialApp(
          title: 'JAVIS Home',
          debugShowCheckedModeBanner: false,
          theme: calmTheme(Brightness.light, locale: locale),
          darkTheme: calmTheme(Brightness.dark, locale: locale),
          themeMode: widget.themeMode,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LaunchExperience(
            enabled: widget.showSplash,
            child: const AppRoot(),
          ),
        ),
      ),
    );
  }
}
