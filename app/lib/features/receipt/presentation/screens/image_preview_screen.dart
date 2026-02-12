import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/image_data.dart';

/// Full-screen image preview for a single receipt image.
///
/// Shows the image on a dark background with crop and delete actions.
/// Returns via [Navigator.pop]:
/// - `ImageData` if the image was cropped (caller should replace the image).
/// - `true` if the user confirmed deletion (caller should remove the image).
/// - `null` if dismissed without changes.
class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({super.key, required this.image});

  final ImageData image;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late ImageData _currentImage;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  Future<void> _onCrop() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImage.localPath,
      compressQuality: 90,
    );
    if (croppedFile == null || !mounted) return;

    final file = File(croppedFile.path);
    final bytes = await file.length();
    final updated = _currentImage.copyWith(
      localPath: croppedFile.path,
      sizeBytes: bytes,
    );

    setState(() {
      _currentImage = updated;
    });
  }

  void _onDelete() {
    final l10n = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteImage),
        content: Text(l10n.deleteImageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = File(_currentImage.localPath);
    final fileExists = file.existsSync();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Return the (possibly cropped) image if it changed, null otherwise.
        final result = _currentImage != widget.image ? _currentImage : null;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).imagePreview),
          backgroundColor: Colors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.crop),
              tooltip: AppLocalizations.of(context).crop,
              onPressed: _onCrop,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLocalizations.of(context).delete,
              onPressed: _onDelete,
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
                    errorBuilder: (_, __, ___) =>
                        const _ImageErrorPlaceholder(),
                  ),
                )
              : const _ImageErrorPlaceholder(),
        ),
      ),
    );
  }
}

/// Placeholder shown when the image file does not exist or fails to load.
class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: AppColors.textLight,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).imageNotAvailable,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
