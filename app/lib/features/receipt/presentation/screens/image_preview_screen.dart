import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/image_data.dart';

/// Full-screen image preview for a single receipt image.
///
/// Shows the image on a dark background with basic action buttons
/// (crop placeholder and delete) in the app bar.
class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({super.key, required this.image});

  final ImageData image;

  void _onCrop(BuildContext context) {
    // TODO: Integrate image_cropper for crop/rotate functionality.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crop is not yet implemented.')),
    );
  }

  void _onDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text(
          'Are you sure you want to delete this image? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        // TODO: Dispatch image deletion event to the appropriate bloc.
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = File(image.localPath);
    final fileExists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Image Preview'),
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            tooltip: 'Crop',
            onPressed: () => _onCrop(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _onDelete(context),
          ),
        ],
      ),
      body: Center(
        child: fileExists
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const _ImageErrorPlaceholder(),
                ),
              )
            : const _ImageErrorPlaceholder(),
      ),
    );
  }
}

/// Placeholder shown when the image file does not exist or fails to load.
class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: AppColors.textLight,
        ),
        SizedBox(height: 16),
        Text(
          'Image not available',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
