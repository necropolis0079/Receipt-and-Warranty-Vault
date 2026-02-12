import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// Banner shown when OCR confidence is low (< 0.34, meaning 0 or 1 of 3
/// fields were extracted). Offers the user two choices: add a better photo
/// to re-run OCR, or dismiss and fill the form manually.
class OcrFeedbackBanner extends StatelessWidget {
  const OcrFeedbackBanner({
    super.key,
    required this.onAddBetterPhoto,
    required this.onFillManually,
  });

  final VoidCallback onAddBetterPhoto;
  final VoidCallback onFillManually;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // amber 50
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)), // amber 300
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.ocrLowConfidenceTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ocrLowConfidenceMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddBetterPhoto,
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: Text(l10n.addBetterPhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: onFillManually,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.fillManually),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
