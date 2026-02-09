import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/receipt.dart';

enum WarrantyStatus { active, expiringSoon, expired, noWarranty }

class WarrantyBadge extends StatelessWidget {
  const WarrantyBadge({super.key, required this.receipt});

  final Receipt receipt;

  WarrantyStatus get _status {
    if (receipt.warrantyMonths <= 0) return WarrantyStatus.noWarranty;
    if (receipt.warrantyExpiryDate == null) return WarrantyStatus.noWarranty;

    final expiry = DateTime.tryParse(receipt.warrantyExpiryDate!);
    if (expiry == null) return WarrantyStatus.noWarranty;

    final now = DateTime.now();
    if (expiry.isBefore(now)) return WarrantyStatus.expired;
    if (expiry.difference(now).inDays <= 30) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    final (Color bg, Color fg, String label, IconData icon) = switch (status) {
      WarrantyStatus.active => (
          AppColors.success.withValues(alpha: 0.1),
          AppColors.success,
          'Active',
          Icons.verified_outlined,
        ),
      WarrantyStatus.expiringSoon => (
          AppColors.accentAmber.withValues(alpha: 0.1),
          AppColors.accentAmber,
          'Expiring Soon',
          Icons.warning_amber_outlined,
        ),
      WarrantyStatus.expired => (
          AppColors.error.withValues(alpha: 0.1),
          AppColors.error,
          'Expired',
          Icons.cancel_outlined,
        ),
      WarrantyStatus.noWarranty => (
          AppColors.divider,
          AppColors.textLight,
          'No Warranty',
          Icons.remove_circle_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
