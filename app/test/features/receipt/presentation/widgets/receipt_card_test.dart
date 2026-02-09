import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/receipt_card.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/warranty_badge.dart';

void main() {
  Receipt createReceipt({
    String receiptId = 'test-id',
    String userId = 'user-1',
    String? storeName = 'Test Store',
    String? purchaseDate,
    double? totalAmount,
    String currency = 'EUR',
    int warrantyMonths = 0,
    String? warrantyExpiryDate,
    bool isFavorite = false,
  }) {
    return Receipt(
      receiptId: receiptId,
      userId: userId,
      storeName: storeName,
      purchaseDate: purchaseDate,
      totalAmount: totalAmount,
      currency: currency,
      warrantyMonths: warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate,
      isFavorite: isFavorite,
      status: ReceiptStatus.active,
      syncStatus: SyncStatus.pending,
      createdAt: '2026-02-09T10:00:00.000Z',
      updatedAt: '2026-02-09T10:00:00.000Z',
    );
  }

  Widget buildCard({required Receipt receipt, VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: ReceiptCard(receipt: receipt, onTap: onTap),
      ),
    );
  }

  group('ReceiptCard', () {
    testWidgets('renders store name', (tester) async {
      final receipt = createReceipt(storeName: 'Electronics Hub');
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.text('Electronics Hub'), findsOneWidget);
    });

    testWidgets('renders purchase date', (tester) async {
      final receipt = createReceipt(purchaseDate: '2026-01-15');
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.text('2026-01-15'), findsOneWidget);
    });

    testWidgets('renders total amount with currency', (tester) async {
      final receipt = createReceipt(totalAmount: 49.99, currency: 'EUR');
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.text('49.99 EUR'), findsOneWidget);
    });

    testWidgets('renders favorite star when isFavorite is true',
        (tester) async {
      final receipt = createReceipt(isFavorite: true);
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('does not render favorite star when isFavorite is false',
        (tester) async {
      final receipt = createReceipt(isFavorite: false);
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows warranty badge when warrantyMonths > 0',
        (tester) async {
      final futureDate =
          DateTime.now().add(const Duration(days: 365)).toIso8601String();
      final receipt = createReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: futureDate,
      );
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.byType(WarrantyBadge), findsOneWidget);
    });

    testWidgets('does not show warranty badge when warrantyMonths is 0',
        (tester) async {
      final receipt = createReceipt(warrantyMonths: 0);
      await tester.pumpWidget(buildCard(receipt: receipt));

      expect(find.byType(WarrantyBadge), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final receipt = createReceipt();
      await tester.pumpWidget(buildCard(
        receipt: receipt,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(ReceiptCard));
      expect(tapped, isTrue);
    });
  });
}
