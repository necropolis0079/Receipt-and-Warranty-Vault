import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/image_data.dart';

class ImagePreviewStrip extends StatelessWidget {
  const ImagePreviewStrip({
    super.key,
    required this.images,
    this.onCrop,
    this.onDelete,
    this.onTap,
  });

  final List<ImageData> images;
  final ValueChanged<int>? onCrop;
  final ValueChanged<int>? onDelete;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final image = images[index];
          return GestureDetector(
            onTap: () => onTap?.call(index),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(image),
                ),
                if (onDelete != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onDelete?.call(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (onCrop != null)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onCrop?.call(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.crop,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(ImageData image) {
    final path = image.thumbnailPath ?? image.localPath;
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, width: 80, height: 100, fit: BoxFit.cover);
    }
    return Container(
      width: 80,
      height: 100,
      color: AppColors.cream,
      child: const Icon(Icons.image_outlined, color: AppColors.textLight),
    );
  }
}
