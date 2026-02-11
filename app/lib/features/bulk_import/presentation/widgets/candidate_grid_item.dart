import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/gallery_candidate.dart';

class CandidateGridItem extends StatelessWidget {
  const CandidateGridItem({
    super.key,
    required this.candidate,
    required this.isSelected,
    required this.onTap,
  });

  final GalleryCandidate candidate;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(candidate.thumbnailPath ?? candidate.localPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Selection overlay
          if (isSelected)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),

          // Selection indicator
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
