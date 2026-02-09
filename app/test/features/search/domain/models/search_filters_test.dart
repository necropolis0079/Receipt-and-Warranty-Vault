import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/search/domain/models/search_filters.dart';

void main() {
  group('SearchFilters', () {
    // ---------------------------------------------------------------
    // Helper: create a Receipt with sensible defaults.
    // ---------------------------------------------------------------
    Receipt makeReceipt({
      String id = 'r-1',
      String? category,
      String? purchaseDate,
      double? totalAmount,
      int warrantyMonths = 0,
    }) {
      return Receipt(
        receiptId: id,
        userId: 'user-1',
        storeName: 'Test Store',
        category: category,
        purchaseDate: purchaseDate,
        totalAmount: totalAmount,
        warrantyMonths: warrantyMonths,
        createdAt: DateTime(2025, 1, 1).toIso8601String(),
        updatedAt: DateTime(2025, 1, 1).toIso8601String(),
      );
    }

    // ---------------------------------------------------------------
    // SearchFilters.empty
    // ---------------------------------------------------------------
    test('SearchFilters.empty has all null fields and isActive is false', () {
      const filters = SearchFilters.empty;

      expect(filters.category, isNull);
      expect(filters.dateFrom, isNull);
      expect(filters.dateTo, isNull);
      expect(filters.amountMin, isNull);
      expect(filters.amountMax, isNull);
      expect(filters.hasWarranty, isNull);
      expect(filters.isActive, isFalse);
    });

    // ---------------------------------------------------------------
    // isActive
    // ---------------------------------------------------------------
    test('isActive returns true when category is set', () {
      const filters = SearchFilters(category: 'Electronics');
      expect(filters.isActive, isTrue);
    });

    test('isActive returns true when dateFrom is set', () {
      final filters = SearchFilters(dateFrom: DateTime(2025, 1, 1));
      expect(filters.isActive, isTrue);
    });

    test('isActive returns true when hasWarranty is set', () {
      const filters = SearchFilters(hasWarranty: true);
      expect(filters.isActive, isTrue);
    });

    // ---------------------------------------------------------------
    // applyTo — category
    // ---------------------------------------------------------------
    test('applyTo filters by category', () {
      const filters = SearchFilters(category: 'Electronics');
      final receipts = [
        makeReceipt(id: 'r-1', category: 'Electronics'),
        makeReceipt(id: 'r-2', category: 'Groceries'),
        makeReceipt(id: 'r-3', category: 'Electronics'),
      ];

      final result = filters.applyTo(receipts);

      expect(result, hasLength(2));
      expect(result.map((r) => r.receiptId), containsAll(['r-1', 'r-3']));
    });

    // ---------------------------------------------------------------
    // applyTo — date range
    // ---------------------------------------------------------------
    test('applyTo filters by date range (dateFrom and dateTo)', () {
      final filters = SearchFilters(
        dateFrom: DateTime(2025, 3, 1),
        dateTo: DateTime(2025, 3, 31),
      );
      final receipts = [
        makeReceipt(id: 'r-1', purchaseDate: '2025-02-15'),
        makeReceipt(id: 'r-2', purchaseDate: '2025-03-10'),
        makeReceipt(id: 'r-3', purchaseDate: '2025-03-31'),
        makeReceipt(id: 'r-4', purchaseDate: '2025-04-05'),
      ];

      final result = filters.applyTo(receipts);

      expect(result, hasLength(2));
      expect(result.map((r) => r.receiptId), containsAll(['r-2', 'r-3']));
    });

    // ---------------------------------------------------------------
    // applyTo — amount range
    // ---------------------------------------------------------------
    test('applyTo filters by amount range (amountMin and amountMax)', () {
      const filters = SearchFilters(amountMin: 50.0, amountMax: 200.0);
      final receipts = [
        makeReceipt(id: 'r-1', totalAmount: 10.0),
        makeReceipt(id: 'r-2', totalAmount: 75.0),
        makeReceipt(id: 'r-3', totalAmount: 200.0),
        makeReceipt(id: 'r-4', totalAmount: 500.0),
      ];

      final result = filters.applyTo(receipts);

      expect(result, hasLength(2));
      expect(result.map((r) => r.receiptId), containsAll(['r-2', 'r-3']));
    });

    // ---------------------------------------------------------------
    // applyTo — hasWarranty true and false
    // ---------------------------------------------------------------
    test('applyTo filters by hasWarranty true', () {
      const filters = SearchFilters(hasWarranty: true);
      final receipts = [
        makeReceipt(id: 'r-1', warrantyMonths: 12),
        makeReceipt(id: 'r-2', warrantyMonths: 0),
        makeReceipt(id: 'r-3', warrantyMonths: 24),
      ];

      final result = filters.applyTo(receipts);

      expect(result, hasLength(2));
      expect(result.map((r) => r.receiptId), containsAll(['r-1', 'r-3']));
    });

    test('applyTo filters by hasWarranty false', () {
      const filters = SearchFilters(hasWarranty: false);
      final receipts = [
        makeReceipt(id: 'r-1', warrantyMonths: 12),
        makeReceipt(id: 'r-2', warrantyMonths: 0),
        makeReceipt(id: 'r-3', warrantyMonths: 0),
      ];

      final result = filters.applyTo(receipts);

      expect(result, hasLength(2));
      expect(result.map((r) => r.receiptId), containsAll(['r-2', 'r-3']));
    });

    // ---------------------------------------------------------------
    // applyTo — multiple filters (AND logic)
    // ---------------------------------------------------------------
    test('applyTo with multiple filters combines them (AND logic)', () {
      final filters = SearchFilters(
        category: 'Electronics',
        amountMin: 100.0,
        dateFrom: DateTime(2025, 3, 1),
        hasWarranty: true,
      );
      final receipts = [
        // Passes all filters
        makeReceipt(
          id: 'r-1',
          category: 'Electronics',
          totalAmount: 150.0,
          purchaseDate: '2025-03-15',
          warrantyMonths: 12,
        ),
        // Wrong category
        makeReceipt(
          id: 'r-2',
          category: 'Groceries',
          totalAmount: 150.0,
          purchaseDate: '2025-03-15',
          warrantyMonths: 12,
        ),
        // Amount too low
        makeReceipt(
          id: 'r-3',
          category: 'Electronics',
          totalAmount: 50.0,
          purchaseDate: '2025-03-15',
          warrantyMonths: 12,
        ),
        // Date too early
        makeReceipt(
          id: 'r-4',
          category: 'Electronics',
          totalAmount: 150.0,
          purchaseDate: '2025-02-15',
          warrantyMonths: 12,
        ),
        // No warranty
        makeReceipt(
          id: 'r-5',
          category: 'Electronics',
          totalAmount: 150.0,
          purchaseDate: '2025-03-15',
          warrantyMonths: 0,
        ),
      ];

      final result = filters.applyTo(receipts);

      expect(result, hasLength(1));
      expect(result.first.receiptId, 'r-1');
    });

    // ---------------------------------------------------------------
    // copyWith
    // ---------------------------------------------------------------
    test('copyWith creates correct copies', () {
      final original = SearchFilters(
        category: 'Electronics',
        dateFrom: DateTime(2025, 1, 1),
        amountMin: 10.0,
      );

      final copied = original.copyWith(
        category: 'Groceries',
        amountMax: 500.0,
      );

      // Changed fields
      expect(copied.category, 'Groceries');
      expect(copied.amountMax, 500.0);

      // Preserved fields
      expect(copied.dateFrom, DateTime(2025, 1, 1));
      expect(copied.amountMin, 10.0);

      // Original is unchanged
      expect(original.category, 'Electronics');
      expect(original.amountMax, isNull);
    });
  });
}
