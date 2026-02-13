import 'package:flutter_test/flutter_test.dart';

/// Mirrors the warranty expiry calculation from:
///   - add_receipt_bloc.dart (_buildReceipt method)
///   - edit_receipt_screen.dart (_save method)
///
/// Given a [purchaseDate] and [warrantyMonths], returns the calculated expiry
/// date, or `null` if [warrantyMonths] is 0 or negative.
///
/// The algorithm:
///   1. Compute targetMonth = purchaseDate.month + warrantyMonths
///   2. Find the last day of the target month via DateTime(year, targetMonth+1, 0)
///   3. Clamp the purchase day to at most that last day
///   4. Return DateTime(year, targetMonth, clampedDay)
///
/// Dart's DateTime constructor handles month overflow natively (e.g. month 13
/// becomes January of the next year), so year roll-over is automatic.
DateTime? calculateWarrantyExpiry(DateTime purchaseDate, int warrantyMonths) {
  if (warrantyMonths <= 0) return null;

  final targetMonth = purchaseDate.month + warrantyMonths;
  final expiryRaw = DateTime(purchaseDate.year, targetMonth + 1, 0);
  final clampedDay = purchaseDate.day <= expiryRaw.day
      ? purchaseDate.day
      : expiryRaw.day;
  final expiryDate = DateTime(purchaseDate.year, targetMonth, clampedDay);
  return expiryDate;
}

void main() {
  group('Warranty Expiry Calculation', () {
    // -----------------------------------------------------------------------
    // 1. Normal case — no day clamping needed
    // -----------------------------------------------------------------------
    group('normal cases (no overflow)', () {
      test('Jan 15 + 1 month = Feb 15', () {
        final purchase = DateTime(2025, 1, 15);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 15));
      });

      test('Mar 10 + 3 months = Jun 10', () {
        final purchase = DateTime(2025, 3, 10);
        final expiry = calculateWarrantyExpiry(purchase, 3);
        expect(expiry, DateTime(2025, 6, 10));
      });

      test('Jun 1 + 6 months = Dec 1', () {
        final purchase = DateTime(2025, 6, 1);
        final expiry = calculateWarrantyExpiry(purchase, 6);
        expect(expiry, DateTime(2025, 12, 1));
      });
    });

    // -----------------------------------------------------------------------
    // 2. End-of-month overflow — the classic bug this fix addresses
    // -----------------------------------------------------------------------
    group('end-of-month overflow clamping', () {
      test('Jan 31 + 1 month = Feb 28 (non-leap year 2025)', () {
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 28));
        // Before the fix, Dart would overflow to Mar 3
        expect(expiry!.month, 2, reason: 'Must stay in February');
        expect(expiry.day, 28);
      });

      test('Mar 31 + 1 month = Apr 30 (April has 30 days)', () {
        final purchase = DateTime(2025, 3, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 4, 30));
        expect(expiry!.month, 4);
        expect(expiry.day, 30);
      });

      test('May 31 + 6 months = Nov 30 (November has 30 days)', () {
        final purchase = DateTime(2025, 5, 31);
        final expiry = calculateWarrantyExpiry(purchase, 6);
        expect(expiry, DateTime(2025, 11, 30));
        expect(expiry!.month, 11);
        expect(expiry.day, 30);
      });

      test('Aug 31 + 1 month = Sep 30', () {
        final purchase = DateTime(2025, 8, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 9, 30));
      });

      test('Oct 31 + 1 month = Nov 30', () {
        final purchase = DateTime(2025, 10, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 11, 30));
      });

      test('Jan 29 + 1 month in non-leap year = Feb 28', () {
        final purchase = DateTime(2025, 1, 29);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 28));
      });

      test('Jan 30 + 1 month in non-leap year = Feb 28', () {
        final purchase = DateTime(2025, 1, 30);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 28));
      });
    });

    // -----------------------------------------------------------------------
    // 3. Leap year handling
    // -----------------------------------------------------------------------
    group('leap year handling', () {
      test('Jan 31 + 1 month in 2024 (leap year) = Feb 29', () {
        final purchase = DateTime(2024, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2024, 2, 29));
        expect(expiry!.month, 2);
        expect(expiry.day, 29);
      });

      test('Jan 31 + 1 month in 2025 (non-leap year) = Feb 28', () {
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 28));
        expect(expiry!.month, 2);
        expect(expiry.day, 28);
      });

      test('Jan 29 + 1 month in 2024 (leap year) = Feb 29', () {
        final purchase = DateTime(2024, 1, 29);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2024, 2, 29));
      });

      test('Jan 29 + 1 month in 2025 (non-leap year) = Feb 28', () {
        final purchase = DateTime(2025, 1, 29);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 28));
      });

      test('Feb 29 (leap year) + 12 months = Feb 28 next year (non-leap)', () {
        final purchase = DateTime(2024, 2, 29);
        final expiry = calculateWarrantyExpiry(purchase, 12);
        expect(expiry, DateTime(2025, 2, 28));
      });

      test('Feb 29 (leap year 2024) + 48 months = Feb 29 (leap year 2028)', () {
        final purchase = DateTime(2024, 2, 29);
        final expiry = calculateWarrantyExpiry(purchase, 48);
        expect(expiry, DateTime(2028, 2, 29));
      });
    });

    // -----------------------------------------------------------------------
    // 4. Year boundary crossing
    // -----------------------------------------------------------------------
    group('year boundary crossing', () {
      test('Dec 15 + 1 month = Jan 15 next year', () {
        final purchase = DateTime(2025, 12, 15);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2026, 1, 15));
      });

      test('Dec 31 + 1 month = Jan 31 next year', () {
        final purchase = DateTime(2025, 12, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2026, 1, 31));
      });

      test('Dec 31 + 2 months = Feb 28 next year (non-leap)', () {
        final purchase = DateTime(2024, 12, 31);
        final expiry = calculateWarrantyExpiry(purchase, 2);
        expect(expiry, DateTime(2025, 2, 28));
      });

      test('Nov 30 + 3 months = Feb 28 (non-leap year)', () {
        final purchase = DateTime(2024, 11, 30);
        final expiry = calculateWarrantyExpiry(purchase, 3);
        expect(expiry, DateTime(2025, 2, 28));
      });

      test('Oct 31 + 4 months = Feb 28 next year (non-leap)', () {
        final purchase = DateTime(2024, 10, 31);
        final expiry = calculateWarrantyExpiry(purchase, 4);
        expect(expiry, DateTime(2025, 2, 28));
      });
    });

    // -----------------------------------------------------------------------
    // 5. Multi-year warranties (12, 24, 36 months)
    // -----------------------------------------------------------------------
    group('multi-year warranties', () {
      test('12 months warranty = same date next year', () {
        final purchase = DateTime(2025, 6, 15);
        final expiry = calculateWarrantyExpiry(purchase, 12);
        expect(expiry, DateTime(2026, 6, 15));
      });

      test('24 months warranty = same date 2 years later', () {
        final purchase = DateTime(2025, 3, 20);
        final expiry = calculateWarrantyExpiry(purchase, 24);
        expect(expiry, DateTime(2027, 3, 20));
      });

      test('36 months warranty = same date 3 years later', () {
        final purchase = DateTime(2025, 7, 10);
        final expiry = calculateWarrantyExpiry(purchase, 36);
        expect(expiry, DateTime(2028, 7, 10));
      });

      test('12 months from Jan 31 = Jan 31 next year', () {
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 12);
        expect(expiry, DateTime(2026, 1, 31));
      });

      test('24 months from Mar 31 = Mar 31 two years later', () {
        final purchase = DateTime(2025, 3, 31);
        final expiry = calculateWarrantyExpiry(purchase, 24);
        expect(expiry, DateTime(2027, 3, 31));
      });
    });

    // -----------------------------------------------------------------------
    // 6. Zero and edge-case warranty months
    // -----------------------------------------------------------------------
    group('zero and edge-case warranty months', () {
      test('zero warranty months returns null (no expiry)', () {
        final purchase = DateTime(2025, 6, 15);
        final expiry = calculateWarrantyExpiry(purchase, 0);
        expect(expiry, isNull);
      });

      test('negative warranty months returns null', () {
        final purchase = DateTime(2025, 6, 15);
        final expiry = calculateWarrantyExpiry(purchase, -1);
        expect(expiry, isNull);
      });

      test('1 month warranty from first day of month', () {
        final purchase = DateTime(2025, 1, 1);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 2, 1));
      });
    });

    // -----------------------------------------------------------------------
    // 7. Day preservation — day 30 in months with 31 days stays day 30
    // -----------------------------------------------------------------------
    group('day preservation (day fits in target month)', () {
      test('day 30 preserved when target month has 31 days', () {
        // Apr 30 + 1 month = May 30 (May has 31 days, so day 30 is preserved)
        final purchase = DateTime(2025, 4, 30);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 5, 30));
        expect(expiry!.day, 30, reason: 'Day 30 should not jump to 31');
      });

      test('day 28 preserved when target month has 31 days', () {
        // Feb 28 + 1 month = Mar 28
        final purchase = DateTime(2025, 2, 28);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 3, 28));
        expect(expiry!.day, 28);
      });

      test('day 15 preserved across all month lengths', () {
        // Day 15 always fits — test several months
        for (int month = 1; month <= 12; month++) {
          final purchase = DateTime(2025, month, 15);
          final expiry = calculateWarrantyExpiry(purchase, 1)!;
          expect(expiry.day, 15,
              reason: 'Day 15 should be preserved from month $month');
        }
      });

      test('day 30 in Jun + 1 month = Jul 30 (preserved, not bumped to 31)', () {
        final purchase = DateTime(2025, 6, 30);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 7, 30));
      });

      test('day 30 in Sep + 1 month = Oct 30 (preserved)', () {
        final purchase = DateTime(2025, 9, 30);
        final expiry = calculateWarrantyExpiry(purchase, 1);
        expect(expiry, DateTime(2025, 10, 30));
      });
    });

    // -----------------------------------------------------------------------
    // 8. February edge cases (the trickiest month)
    // -----------------------------------------------------------------------
    group('February edge cases', () {
      test('Feb 28 non-leap + 12 months = Feb 28 next year', () {
        final purchase = DateTime(2025, 2, 28);
        final expiry = calculateWarrantyExpiry(purchase, 12);
        expect(expiry, DateTime(2026, 2, 28));
      });

      test('Feb 28 in year before leap + 12 months = Feb 28 (leap year)', () {
        // 2023 -> 2024 (leap)
        final purchase = DateTime(2023, 2, 28);
        final expiry = calculateWarrantyExpiry(purchase, 12);
        expect(expiry, DateTime(2024, 2, 28));
        // Day 28 fits in both, so it stays 28 (not 29)
        expect(expiry!.day, 28);
      });

      test('Jan 31 + 13 months = Feb 28 next year (non-leap 2026)', () {
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 13);
        expect(expiry, DateTime(2026, 2, 28));
      });

      test('Jan 31 + 13 months in 2023 = Feb 29 2024 (leap year)', () {
        final purchase = DateTime(2023, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 13);
        expect(expiry, DateTime(2024, 2, 29));
      });
    });

    // -----------------------------------------------------------------------
    // 9. Large warranty durations
    // -----------------------------------------------------------------------
    group('large warranty durations', () {
      test('60 months (5 years) warranty', () {
        final purchase = DateTime(2025, 6, 15);
        final expiry = calculateWarrantyExpiry(purchase, 60);
        expect(expiry, DateTime(2030, 6, 15));
      });

      test('120 months (10 years) warranty', () {
        final purchase = DateTime(2025, 1, 1);
        final expiry = calculateWarrantyExpiry(purchase, 120);
        expect(expiry, DateTime(2035, 1, 1));
      });

      test('60 months from end-of-month still clamps correctly', () {
        // Jan 31 2025 + 60 months = Jan 31 2030
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 60);
        expect(expiry, DateTime(2030, 1, 31));
      });
    });

    // -----------------------------------------------------------------------
    // 10. ISO 8601 string round-trip (mirrors production usage)
    // -----------------------------------------------------------------------
    group('ISO 8601 string output (mirrors production format)', () {
      test('expiry date formatted as YYYY-MM-DD matches production code', () {
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1)!;
        // Production code does: expiryDate.toIso8601String().split('T').first
        final formatted = expiry.toIso8601String().split('T').first;
        expect(formatted, '2025-02-28');
      });

      test('year crossing formatted correctly', () {
        final purchase = DateTime(2025, 12, 15);
        final expiry = calculateWarrantyExpiry(purchase, 1)!;
        final formatted = expiry.toIso8601String().split('T').first;
        expect(formatted, '2026-01-15');
      });

      test('leap year date formatted correctly', () {
        final purchase = DateTime(2024, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1)!;
        final formatted = expiry.toIso8601String().split('T').first;
        expect(formatted, '2024-02-29');
      });
    });

    // -----------------------------------------------------------------------
    // 11. Regression guard — the original bug scenario
    // -----------------------------------------------------------------------
    group('regression: original overflow bug', () {
      test('Jan 31 + 1 month must NOT produce March (the original bug)', () {
        final purchase = DateTime(2025, 1, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1)!;
        expect(expiry.month, isNot(3),
            reason: 'Before the fix, naive DateTime addition overflowed '
                'Jan 31 + 1 month into March 3');
        expect(expiry.month, 2);
      });

      test('Mar 31 + 1 month must NOT produce May (overflow to May 1)', () {
        final purchase = DateTime(2025, 3, 31);
        final expiry = calculateWarrantyExpiry(purchase, 1)!;
        expect(expiry.month, isNot(5),
            reason: 'Naive addition of 1 month to Mar 31 could overflow to May 1');
        expect(expiry.month, 4);
        expect(expiry.day, 30);
      });

      test('consecutive month additions all stay in correct month', () {
        // Purchase on Jan 31 — verify each +N months for N=1..12
        final purchase = DateTime(2025, 1, 31);
        final expectedMonths = [
          2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, // +1 through +12
        ];
        for (int i = 0; i < 12; i++) {
          final months = i + 1;
          final expiry = calculateWarrantyExpiry(purchase, months)!;
          expect(expiry.month, expectedMonths[i],
              reason: 'Jan 31 + $months months should be in month '
                  '${expectedMonths[i]} but got month ${expiry.month}');
        }
      });
    });
  });
}
