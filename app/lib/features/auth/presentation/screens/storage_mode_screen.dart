import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

enum StorageMode { cloudAndDevice, deviceOnly }

class StorageModeScreen extends StatefulWidget {
  const StorageModeScreen({super.key, required this.onContinue});

  final void Function(StorageMode mode) onContinue;

  @override
  State<StorageModeScreen> createState() => _StorageModeScreenState();
}

class _StorageModeScreenState extends State<StorageModeScreen> {
  StorageMode _selectedMode = StorageMode.cloudAndDevice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.storageMode),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.verticalGapLg,
            Text(
              l10n.authChooseStorageMode,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalGapXl,

            // Cloud + Device
            _StorageModeCard(
              icon: Icons.cloud_outlined,
              title: l10n.cloudAndDevice,
              description: l10n.authCloudDescription,
              selected: _selectedMode == StorageMode.cloudAndDevice,
              onTap: () {
                setState(() => _selectedMode = StorageMode.cloudAndDevice);
              },
            ),
            AppSpacing.verticalGapMd,

            // Device Only
            _StorageModeCard(
              icon: Icons.phone_android_outlined,
              title: l10n.deviceOnly,
              description: l10n.authDeviceOnlyDescription,
              selected: _selectedMode == StorageMode.deviceOnly,
              onTap: () {
                setState(() => _selectedMode = StorageMode.deviceOnly);
              },
            ),

            const Spacer(),

            // Continue
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => widget.onContinue(_selectedMode),
                child: Text(l10n.next),
              ),
            ),
            AppSpacing.verticalGapXl,
          ],
        ),
      ),
    );
  }
}

class _StorageModeCard extends StatelessWidget {
  const _StorageModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color:
                selected ? AppColors.primaryGreen : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryGreen.withValues(alpha: 0.1)
                    : AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
            ),
            AppSpacing.horizontalGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalGapXs,
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}
