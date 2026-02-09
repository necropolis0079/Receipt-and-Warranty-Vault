import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/constants/app_colors.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/warranty_badge.dart';

void main() {
  Receipt createReceipt({
    int warrantyMonths = 12,
    String? warrantyExpiryDate,
  }) {
    return Receipt(
      receiptId: 'test-id',
      userId: 'user-1',
      storeName: 'Test Store',
      currency: 'EUR',
      warrantyMonths: warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate,
      status: ReceiptStatus.active,
      syncStatus: SyncStatus.pending,
      isFavorite: false,
      createdAt: '2026-02-09T10:00:00.000Z',
      updatedAt: '2026-02-09T10:00:00.000Z',
    );
  }

  Widget buildBadge(Receipt receipt) {
    return MaterialApp(
      home: Scaffold(
        body: WarrantyBadge(receipt: receipt),
      ),
    );
  }

  group('WarrantyBadge', () {
    testWidgets('shows "Active" with green for active warranty',
        (tester) async {
      final receipt = createReceipt(
        warrantyMonths: 24,
        warrantyExpiryDate: '2027-06-01',
      );
      await tester.pumpWidget(buildBadge(receipt));

      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);

      // Verify the icon color is the success green
      final icon = tester.widget<Icon>(find.byIcon(Icons.verified_outlined));
      expect(icon.color, AppColors.success);
    });

    testWidgets('shows "Expiring Soon" with amber for warranty expiring in < 30 days',
        (tester) async {
      // Set expiry to 15 days from now
      final soonDate = DateTime.now()
          .add(const Duration(days: 15))
          .toIso8601String()
          .substring(0, 10);
      final receipt = createReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: soonDate,
      );
      await tester.pumpWidget(buildBadge(receipt));

      expect(find.text('Expiring Soon'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.warning_amber_outlined));
      expect(icon.color, AppColors.accentAmber);
    });

    testWidgets('shows "Expired" with red for expired warranty',
        (tester) async {
      final receipt = createReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: '2024-01-01',
      );
      await tester.pumpWidget(buildBadge(receipt));

      expect(find.text('Expired'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.cancel_outlined));
      expect(icon.color, AppColors.error);
    });

    testWidgets('shows "No Warranty" for warrantyMonths = 0', (tester) async {
      final receipt = createReceipt(
        warrantyMonths: 0,
        warrantyExpiryDate: null,
      );
      await tester.pumpWidget(buildBadge(receipt));

      expect(find.text('No Warranty'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.remove_circle_outline));
      expect(icon.color, AppColors.textLight);
    });
  });
}
