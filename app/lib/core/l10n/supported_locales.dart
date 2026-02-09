import 'dart:ui';

abstract final class SupportedLocales {
  static const english = Locale('en');
  static const greek = Locale('el');

  static const List<Locale> all = [english, greek];

  static const Locale defaultLocale = english;
}
