import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'backend/create_backend.dart';
import 'backend/demo_backend.dart';
import 'backend/javis_backend.dart';
import 'core/localization/app_localizations.dart';
import 'core/motion/motion.dart';
import 'core/theme/app_appearance.dart';
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
    this.backend,
    this.themeMode = ThemeMode.system,
    this.themePreference,
    this.showSplash = true,
    this.startSignedIn = false,
  });
  final LightingService? lightingService;
  final JavisBackend? backend;

  /// The theme to open with. The user can change it on the profile screen.
  final ThemeMode themeMode;

  /// Keeps the user's theme choice. Without it, the choice lasts for this run.
  final ThemePreference? themePreference;
  final bool showSplash;

  /// Opens the seeded demo account instead of the welcome screen.
  final bool startSignedIn;
  @override
  State<JavisApp> createState() => _JavisAppState();
}

class _JavisAppState extends State<JavisApp> with WidgetsBindingObserver {
  Locale? _locale;
  late ThemeMode _themeMode = widget.themeMode;
  late final LightingService _service =
      widget.lightingService ?? createLightingService();
  late final JavisBackend _backend = widget.backend ?? createBackend();
  late final _account = AccountStore(_backend);
  late final _homes = HomeStore(_backend);
  late final _scenes = SceneStore(_backend);
  final _lock = LockStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_service.initialize());
    _account.onSignedOut = () {
      _homes.reset();
      _scenes.reset();
    };
    if (widget.startSignedIn) _openDemoAccount();
    _homes.addListener(_onHomesChanged);
    _service.addListener(_claimNewLights);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    unawaited(widget.themePreference?.write(mode));
  }

  void _openDemoAccount() {
    final demo = _backend as DemoBackend;
    _account.signInDemo();
    _homes.adopt(demo.demoAccount());
    _scenes.adopt(_homes.activeHome!.id, demo.scenes);
  }

  void _onHomesChanged() {
    unawaited(_scenes.show(_homes.activeHome?.id));
    _claimNewLights();
  }

  void _claimNewLights() => unawaited(_homes.claimNewLights(_service));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _backend.isDemo) return;
    if (!_account.signedIn) return;
    unawaited(_homes.refresh());
    unawaited(_scenes.reload());
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_locale == null) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homes.removeListener(_onHomesChanged);
    _service.removeListener(_claimNewLights);
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
    final reduceMotion = MediaQueryData.fromView(View.of(context))
        .disableAnimations;
    return AppLanguage(
      setLocale: (locale) => setState(() => _locale = locale),
      child: AppAppearance(
        themeMode: _themeMode,
        setThemeMode: _setThemeMode,
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
            themeMode: _themeMode,
            themeAnimationDuration: reduceMotion
                ? Duration.zero
                : Motion.standard,
            themeAnimationCurve: Motion.curve,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: Theme.of(context).brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: child!,
            ),
            home: LaunchExperience(
              enabled: widget.showSplash,
              child: const AppRoot(),
            ),
          ),
        ),
      ),
    );
  }
}
