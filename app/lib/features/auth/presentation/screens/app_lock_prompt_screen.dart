import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class AppLockPromptScreen extends StatelessWidget {
  const AppLockPromptScreen({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 56,
                  color: AppColors.primaryGreen,
                ),
              ),
              AppSpacing.verticalGapXl,

              // Title
              Text(
                l10n.authSecureYourApp,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGapMd,

              // Description
              Text(
                l10n.authAppLockDescription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Enable button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onEnable,
                  child: Text(l10n.enableAppLock),
                ),
              ),
              AppSpacing.verticalGapSm,

              // Skip button
              SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(l10n.authMaybeLater),
                ),
              ),
              AppSpacing.verticalGapXl,
            ],
          ),
        ),
      ),
    );
  }
}
