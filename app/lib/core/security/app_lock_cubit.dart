import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_lock_service.dart';
import 'app_lock_state.dart';

class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit({required AppLockService appLockService})
      : _appLockService = appLockService,
        super(AppLockState.initial());

  final AppLockService _appLockService;
  DateTime? _lastPausedAt;

  /// Check device capability on startup.
  Future<void> checkDeviceSupport() async {
    final supported = await _appLockService.isDeviceSupported();
    emit(state.copyWith(isDeviceSupported: supported));
  }

  /// Enable app lock. Returns true if the device supports it.
  Future<bool> enable() async {
    final supported = await _appLockService.isDeviceSupported();
    if (!supported) return false;

    emit(state.copyWith(isEnabled: true, isDeviceSupported: true));
    return true;
  }

  /// Disable app lock.
  void disable() {
    emit(state.copyWith(isEnabled: false, isLocked: false));
  }

  /// Change the lock timeout.
  void setTimeout(LockTimeout timeout) {
    emit(state.copyWith(timeout: timeout));
  }

  /// Called when the app goes to background.
  void onAppPaused() {
    _lastPausedAt = DateTime.now();
  }

  /// Called when the app comes to foreground.
  /// Locks the app if enough time has passed since pause.
  void onAppResumed() {
    if (!state.isEnabled) return;

    if (_lastPausedAt == null) {
      emit(state.copyWith(isLocked: true));
      return;
    }

    final elapsed = DateTime.now().difference(_lastPausedAt!);
    final thresholdSeconds = switch (state.timeout) {
      LockTimeout.immediate => 0,
      LockTimeout.after1Min => 60,
      LockTimeout.after5Min => 300,
    };

    if (elapsed.inSeconds >= thresholdSeconds) {
      emit(state.copyWith(isLocked: true));
    }
  }

  /// Attempt to unlock. Returns true on success.
  Future<bool> unlock({required String localizedReason}) async {
    final success =
        await _appLockService.authenticate(localizedReason: localizedReason);
    if (success) {
      emit(state.copyWith(isLocked: false));
    }
    return success;
  }
}
