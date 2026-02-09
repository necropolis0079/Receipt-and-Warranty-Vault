import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum CaptureOption { camera, gallery, files }

class CaptureOptionSheet extends StatelessWidget {
  const CaptureOptionSheet({super.key, required this.onSelected});

  final ValueChanged<CaptureOption> onSelected;

  static Future<CaptureOption?> show(BuildContext context) {
    return showModalBottomSheet<CaptureOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CaptureOptionSheet(
        onSelected: (option) => Navigator.of(context).pop(option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Receipt',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              subtitle: 'Capture receipt with camera',
              onTap: () => onSelected(CaptureOption.camera),
            ),
            _OptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              subtitle: 'Select existing photos',
              onTap: () => onSelected(CaptureOption.gallery),
            ),
            _OptionTile(
              icon: Icons.folder_outlined,
              label: 'Import Files',
              subtitle: 'Images or PDF documents',
              onTap: () => onSelected(CaptureOption.files),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGreen),
      ),
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}
