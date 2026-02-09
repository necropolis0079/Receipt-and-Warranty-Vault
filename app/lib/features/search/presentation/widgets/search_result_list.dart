import 'package:flutter/material.dart';

import '../../../receipt/domain/entities/receipt.dart';
import '../../../receipt/presentation/screens/receipt_detail_screen.dart';
import '../../../receipt/presentation/widgets/receipt_card.dart';

/// Displays a scrollable list of search result [Receipt]s using [ReceiptCard].
///
/// Tapping a card navigates to [ReceiptDetailScreen] for that receipt.
class SearchResultList extends StatelessWidget {
  const SearchResultList({
    super.key,
    required this.results,
    this.onReceiptTap,
  });

  final List<Receipt> results;

  /// Optional callback invoked when a receipt is tapped.
  /// If not provided, the default behaviour navigates to [ReceiptDetailScreen].
  final void Function(Receipt receipt)? onReceiptTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final receipt = results[index];
        return ReceiptCard(
          receipt: receipt,
          onTap: () {
            if (onReceiptTap != null) {
              onReceiptTap!(receipt);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReceiptDetailScreen(receipt: receipt),
                ),
              );
            }
          },
        );
      },
    );
  }
}
