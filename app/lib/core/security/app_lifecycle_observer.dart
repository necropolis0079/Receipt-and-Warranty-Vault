import 'package:flutter/widgets.dart';

import 'app_lock_cubit.dart';

/// Observes app lifecycle changes and notifies [AppLockCubit]
/// when the app goes to background / returns to foreground.
class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleObserver({required this.appLockCubit});

  final AppLockCubit appLockCubit;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        appLockCubit.onAppPaused();
      case AppLifecycleState.resumed:
        appLockCubit.onAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }
}
