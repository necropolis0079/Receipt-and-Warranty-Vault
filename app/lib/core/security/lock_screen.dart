import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_lock_cubit.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outlined,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              AppSpacing.verticalGapXl,
              Text(
                l10n.lockScreenTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalGapSm,
              Text(
                l10n.lockScreenSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGapXl,
              SizedBox(
                width: 200,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final cubit = context.read<AppLockCubit>();
                    final success = await cubit.unlock(
                      localizedReason: l10n.lockScreenSubtitle,
                    );
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.lockScreenAuthFailed)),
                      );
                    }
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.lockScreenUnlock),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
