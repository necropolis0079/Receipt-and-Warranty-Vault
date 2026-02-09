import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB completeness', () {
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> elArb;

    setUpAll(() {
      final enFile = File('lib/core/l10n/arb/app_en.arb');
      final elFile = File('lib/core/l10n/arb/app_el.arb');

      expect(enFile.existsSync(), isTrue,
          reason: 'app_en.arb must exist');
      expect(elFile.existsSync(), isTrue,
          reason: 'app_el.arb must exist');

      enArb = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      elArb = jsonDecode(elFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('English ARB has @@locale set to "en"', () {
      expect(enArb['@@locale'], 'en');
    });

    test('Greek ARB has @@locale set to "el"', () {
      expect(elArb['@@locale'], 'el');
    });

    test('Greek ARB has every non-metadata key from English ARB', () {
      final enKeys =
          enArb.keys.where((k) => !k.startsWith('@')).toSet();
      final elKeys =
          elArb.keys.where((k) => !k.startsWith('@')).toSet();

      final missing = enKeys.difference(elKeys);
      expect(missing, isEmpty,
          reason: 'Greek ARB is missing keys: $missing');
    });

    test('English ARB has every non-metadata key from Greek ARB', () {
      final enKeys =
          enArb.keys.where((k) => !k.startsWith('@')).toSet();
      final elKeys =
          elArb.keys.where((k) => !k.startsWith('@')).toSet();

      final extra = elKeys.difference(enKeys);
      expect(extra, isEmpty,
          reason: 'Greek ARB has extra keys not in English: $extra');
    });

    test('no empty values in English ARB', () {
      final empty = enArb.entries
          .where(
              (e) => !e.key.startsWith('@') && (e.value as String).isEmpty)
          .map((e) => e.key)
          .toList();
      expect(empty, isEmpty,
          reason: 'English ARB has empty values for: $empty');
    });

    test('no empty values in Greek ARB', () {
      final empty = elArb.entries
          .where(
              (e) => !e.key.startsWith('@') && (e.value as String).isEmpty)
          .map((e) => e.key)
          .toList();
      expect(empty, isEmpty,
          reason: 'Greek ARB has empty values for: $empty');
    });

    test('both ARBs have a reasonable number of keys', () {
      final enKeyCount =
          enArb.keys.where((k) => !k.startsWith('@')).length;
      final elKeyCount =
          elArb.keys.where((k) => !k.startsWith('@')).length;

      // We defined ~120 strings; ensure we haven't accidentally lost any.
      expect(enKeyCount, greaterThanOrEqualTo(100),
          reason: 'English ARB seems to have too few keys ($enKeyCount)');
      expect(elKeyCount, greaterThanOrEqualTo(100),
          reason: 'Greek ARB seems to have too few keys ($elKeyCount)');
    });
  });
}
