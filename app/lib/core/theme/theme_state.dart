import 'package:equatable/equatable.dart';

/// The app's theme mode preference.
enum AppThemeMode { light, dark, system }

class ThemeState extends Equatable {
  const ThemeState({required this.mode});

  final AppThemeMode mode;

  factory ThemeState.initial() => const ThemeState(mode: AppThemeMode.system);

  ThemeState copyWith({AppThemeMode? mode}) =>
      ThemeState(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
