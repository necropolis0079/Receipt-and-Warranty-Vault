import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_state.dart';
import 'supported_locales.dart';

/// Cubit that manages the app's active locale.
///
/// On init, defaults to English. The saved preference is loaded via
/// [loadSavedLocale] (wired to the settings DAO after DB integration).
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(LocaleState.initial());

  /// Load the saved locale preference from local storage.
  /// Called once at app startup after DI is ready.
  Future<void> loadSavedLocale(String? savedLocaleCode) async {
    if (savedLocaleCode == null) return;

    final locale = Locale(savedLocaleCode);
    if (SupportedLocales.all.contains(locale)) {
      emit(state.copyWith(locale: locale));
    }
  }

  /// Change the app locale. The caller is responsible for persisting
  /// the preference (e.g., via settings DAO).
  void changeLocale(Locale locale) {
    if (!SupportedLocales.all.contains(locale)) return;
    emit(state.copyWith(locale: locale));
  }
}
