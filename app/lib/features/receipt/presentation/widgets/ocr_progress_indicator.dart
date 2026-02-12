import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

enum OcrProgressStatus { scanning, extracting, analyzing, complete, failed }

class OcrProgressIndicator extends StatelessWidget {
  const OcrProgressIndicator({super.key, required this.status});

  final OcrProgressStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (String label, IconData? icon) = switch (status) {
      OcrProgressStatus.scanning => (l10n.scanningReceipt, null),
      OcrProgressStatus.extracting => (l10n.extractingData, null),
      OcrProgressStatus.analyzing => (l10n.analyzingFields, null),
      OcrProgressStatus.complete => (l10n.analysisComplete, Icons.check_circle),
      OcrProgressStatus.failed => (l10n.analysisFailed, Icons.error_outline),
    };

    final isComplete = status == OcrProgressStatus.complete;
    final isFailed = status == OcrProgressStatus.failed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.success.withValues(alpha: 0.1)
            : isFailed
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: isComplete ? AppColors.success : AppColors.error,
              size: 24,
            )
          else
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
