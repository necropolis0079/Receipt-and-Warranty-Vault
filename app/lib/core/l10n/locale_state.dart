import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'supported_locales.dart';

class LocaleState extends Equatable {
  const LocaleState({required this.locale});

  final Locale locale;

  factory LocaleState.initial() =>
      LocaleState(locale: SupportedLocales.defaultLocale);

  LocaleState copyWith({Locale? locale}) =>
      LocaleState(locale: locale ?? this.locale);

  @override
  List<Object?> get props => [locale];
}
