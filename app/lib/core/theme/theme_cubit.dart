import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_state.dart';

/// Cubit that manages the app's theme mode (light / dark / system).
///
/// On init, defaults to [AppThemeMode.system]. The saved preference is
/// loaded via [loadSavedTheme] (wired to the settings DAO at startup).
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

  /// Load the saved theme preference from local storage.
  /// Called once at app startup after DI is ready.
  void loadSavedTheme(String? savedThemeMode) {
    if (savedThemeMode == null) return;

    final mode = AppThemeMode.values.where((m) => m.name == savedThemeMode);
    if (mode.isNotEmpty) {
      emit(state.copyWith(mode: mode.first));
    }
  }

  /// Change the app theme mode. The caller is responsible for persisting
  /// the preference (e.g., via settings DAO).
  void changeTheme(AppThemeMode mode) {
    emit(state.copyWith(mode: mode));
  }
}
