import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/l10n/locale_cubit.dart';
import 'package:warrantyvault/core/l10n/locale_state.dart';
import 'package:warrantyvault/core/l10n/supported_locales.dart';

void main() {
  group('LocaleCubit', () {
    late LocaleCubit cubit;

    setUp(() {
      cubit = LocaleCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state defaults to English', () {
      expect(cubit.state.locale, SupportedLocales.english);
    });

    blocTest<LocaleCubit, LocaleState>(
      'changeLocale emits Greek locale',
      build: LocaleCubit.new,
      act: (c) => c.changeLocale(SupportedLocales.greek),
      expect: () => [const LocaleState(locale: Locale('el'))],
    );

    blocTest<LocaleCubit, LocaleState>(
      'changeLocale ignores unsupported locale',
      build: LocaleCubit.new,
      act: (c) => c.changeLocale(const Locale('fr')),
      expect: () => <LocaleState>[],
    );

    blocTest<LocaleCubit, LocaleState>(
      'changeLocale back to English after switching to Greek',
      build: LocaleCubit.new,
      act: (c) {
        c.changeLocale(SupportedLocales.greek);
        c.changeLocale(SupportedLocales.english);
      },
      expect: () => [
        const LocaleState(locale: Locale('el')),
        const LocaleState(locale: Locale('en')),
      ],
    );

    blocTest<LocaleCubit, LocaleState>(
      'loadSavedLocale loads Greek from saved code',
      build: LocaleCubit.new,
      act: (c) => c.loadSavedLocale('el'),
      expect: () => [const LocaleState(locale: Locale('el'))],
    );

    blocTest<LocaleCubit, LocaleState>(
      'loadSavedLocale does nothing for null code',
      build: LocaleCubit.new,
      act: (c) => c.loadSavedLocale(null),
      expect: () => <LocaleState>[],
    );

    blocTest<LocaleCubit, LocaleState>(
      'loadSavedLocale ignores unsupported locale code',
      build: LocaleCubit.new,
      act: (c) => c.loadSavedLocale('ja'),
      expect: () => <LocaleState>[],
    );
  });

  group('LocaleState', () {
    test('copyWith creates new instance with updated locale', () {
      const initial = LocaleState(locale: Locale('en'));
      final updated = initial.copyWith(locale: const Locale('el'));

      expect(updated.locale, const Locale('el'));
      expect(initial.locale, const Locale('en'));
    });

    test('copyWith without args returns equivalent state', () {
      const state = LocaleState(locale: Locale('en'));
      final copy = state.copyWith();

      expect(copy, state);
    });

    test('equality works via Equatable', () {
      const a = LocaleState(locale: Locale('en'));
      const b = LocaleState(locale: Locale('en'));
      const c = LocaleState(locale: Locale('el'));

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('SupportedLocales', () {
    test('all contains exactly English and Greek', () {
      expect(SupportedLocales.all, hasLength(2));
      expect(SupportedLocales.all, contains(const Locale('en')));
      expect(SupportedLocales.all, contains(const Locale('el')));
    });

    test('defaultLocale is English', () {
      expect(SupportedLocales.defaultLocale, const Locale('en'));
    });
  });
}
