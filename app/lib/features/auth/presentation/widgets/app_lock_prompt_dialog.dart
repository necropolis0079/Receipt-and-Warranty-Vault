import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// Dialog shown after onboarding to prompt the user to enable app lock.
///
/// Returns `true` when "Enable Now" is tapped, `false` when "Maybe Later" is
/// tapped. The caller is responsible for actually enabling the lock.
class AppLockPromptDialog extends StatelessWidget {
  const AppLockPromptDialog({super.key});

  /// Convenience method to show the dialog and return the user's choice.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLockPromptDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.appLockPromptTitle)),
        ],
      ),
      content: Text(l10n.appLockPromptMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.maybeLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: Text(l10n.enableNow),
        ),
      ],
    );
  }
}
