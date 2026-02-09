import 'package:equatable/equatable.dart';

enum LockTimeout { immediate, after1Min, after5Min }

class AppLockState extends Equatable {
  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
    required this.timeout,
    required this.isDeviceSupported,
  });

  final bool isEnabled;
  final bool isLocked;
  final LockTimeout timeout;
  final bool isDeviceSupported;

  factory AppLockState.initial() => const AppLockState(
        isEnabled: false,
        isLocked: false,
        timeout: LockTimeout.immediate,
        isDeviceSupported: false,
      );

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    LockTimeout? timeout,
    bool? isDeviceSupported,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      timeout: timeout ?? this.timeout,
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
    );
  }

  @override
  List<Object?> get props => [isEnabled, isLocked, timeout, isDeviceSupported];
}
