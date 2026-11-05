import 'package:flutter/widgets.dart';

import 'features/account/account_store.dart';
import 'features/home/home_store.dart';
import 'features/lighting/lighting_service.dart';
import 'features/lock/lock_store.dart';
import 'features/scenes/scene_store.dart';

/// Hands the app's long-lived services to every screen.
///
/// The services are `ChangeNotifier`s; widgets listen to the one they render
/// with `ListenableBuilder`, so a change rebuilds only that part of the tree.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.lighting,
    required this.account,
    required this.homes,
    required this.lock,
    required this.scenes,
    required super.child,
    super.key,
  });

  final LightingService lighting;
  final AccountStore account;
  final HomeStore homes;
  final LockStore lock;
  final SceneStore scenes;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      lighting != oldWidget.lighting ||
      account != oldWidget.account ||
      homes != oldWidget.homes ||
      lock != oldWidget.lock ||
      scenes != oldWidget.scenes;
}

extension AppScopeContext on BuildContext {
  AppScope get app => AppScope.of(this);
}
