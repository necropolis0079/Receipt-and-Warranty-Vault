import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/receipt.dart';
import 'warranty_badge.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onTap,
  });

  final Receipt receipt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.textLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            receipt.displayName,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (receipt.isFavorite)
                          const Icon(
                            Icons.star,
                            color: AppColors.accentAmber,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (receipt.purchaseDate != null) ...[
                          Text(
                            receipt.purchaseDate!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMedium,
                                    ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (receipt.totalAmount != null)
                          Text(
                            '${receipt.totalAmount!.toStringAsFixed(2)} ${receipt.currency}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                      ],
                    ),
                    if (receipt.warrantyMonths > 0) ...[
                      const SizedBox(height: 6),
                      WarrantyBadge(receipt: receipt),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
