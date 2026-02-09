import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/receipt.dart';
import '../bloc/vault_event.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/warranty_badge.dart';

/// Read-only detail view for a single receipt.
///
/// Displays all receipt fields in a scrollable card layout with an image
/// gallery at the top and action buttons at the bottom.
class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({super.key, required this.receipt});

  final Receipt receipt;

  // ---------------------------------------------------------------------------
  // Icon mapping for category strings
  // ---------------------------------------------------------------------------

  static IconData _categoryIcon(String? category) {
    if (category == null) return Icons.label_outline;
    return switch (category.toLowerCase()) {
      'electronics' => Icons.devices,
      'groceries' => Icons.shopping_cart,
      'clothing & apparel' || 'clothing' => Icons.checkroom,
      'home & furniture' || 'home' => Icons.chair,
      'health & pharmacy' || 'health' => Icons.local_pharmacy,
      'restaurants & food' || 'restaurant' => Icons.restaurant,
      'transportation' || 'car' => Icons.directions_car,
      'entertainment' => Icons.movie,
      'services & subscriptions' || 'subscription' => Icons.subscriptions,
      'other' => Icons.more_horiz,
      _ => Icons.label_outline,
    };
  }

  // ---------------------------------------------------------------------------
  // Status display helpers
  // ---------------------------------------------------------------------------

  static String _statusLabel(ReceiptStatus status) {
    return switch (status) {
      ReceiptStatus.active => 'Active',
      ReceiptStatus.returned => 'Returned',
      ReceiptStatus.deleted => 'Deleted',
    };
  }

  static Color _statusColor(ReceiptStatus status) {
    return switch (status) {
      ReceiptStatus.active => AppColors.success,
      ReceiptStatus.returned => AppColors.accentAmber,
      ReceiptStatus.deleted => AppColors.error,
    };
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: Text(
          'Are you sure you want to delete "${receipt.displayName}"? '
          'It can be recovered within 30 days.',
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
        context.read<VaultBloc>().add(VaultReceiptDeleted(receipt.receiptId));
        Navigator.of(context).pop();
      }
    });
  }

  void _onToggleFavorite(BuildContext context) {
    context.read<VaultBloc>().add(
          VaultReceiptFavoriteToggled(
            receiptId: receipt.receiptId,
            isFavorite: !receipt.isFavorite,
          ),
        );
  }

  void _onMarkAsReturned(BuildContext context) {
    // TODO: Dispatch a VaultReceiptStatusChanged event once available.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mark as Returned is not yet implemented.')),
    );
  }

  void _onEdit(BuildContext context) {
    // TODO: Navigate to receipt edit screen.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit is not yet implemented.')),
    );
  }

  void _onShare(BuildContext context) {
    // TODO: Implement share/export.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share is not yet implemented.')),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.displayName),
        actions: [
          IconButton(
            icon: Icon(
              receipt.isFavorite ? Icons.star : Icons.star_border,
              color: receipt.isFavorite ? AppColors.accentAmber : null,
            ),
            tooltip: receipt.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: () => _onToggleFavorite(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Image gallery ----
            _ImageGallerySection(localImagePaths: receipt.localImagePaths),

            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Store & status ----
                  _DetailCard(
                    children: [
                      _FieldRow(
                        icon: Icons.store,
                        label: 'Store',
                        value: receipt.displayName,
                      ),
                      const Divider(height: 1),
                      _FieldRow(
                        icon: Icons.calendar_today,
                        label: 'Purchase Date',
                        value: receipt.purchaseDate ?? 'N/A',
                      ),
                      const Divider(height: 1),
                      _FieldRow(
                        icon: Icons.attach_money,
                        label: 'Total',
                        value: receipt.totalAmount != null
                            ? '${receipt.totalAmount!.toStringAsFixed(2)} ${receipt.currency}'
                            : 'N/A',
                      ),
                      const Divider(height: 1),
                      _FieldRow(
                        icon: _categoryIcon(receipt.category),
                        label: 'Category',
                        value: receipt.category ?? 'Uncategorized',
                      ),
                    ],
                  ),

                  AppSpacing.verticalGapMd,

                  // ---- Warranty ----
                  _DetailCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            AppSpacing.horizontalGapSm,
                            Text(
                              'Warranty',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            WarrantyBadge(receipt: receipt),
                          ],
                        ),
                      ),
                      if (receipt.warrantyMonths > 0) ...[
                        const Divider(height: 1),
                        _FieldRow(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: '${receipt.warrantyMonths} months',
                        ),
                      ],
                      if (receipt.warrantyExpiryDate != null) ...[
                        const Divider(height: 1),
                        _FieldRow(
                          icon: Icons.event,
                          label: 'Expires',
                          value: receipt.warrantyExpiryDate!,
                        ),
                      ],
                    ],
                  ),

                  AppSpacing.verticalGapMd,

                  // ---- Status ----
                  _DetailCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            AppSpacing.horizontalGapSm,
                            Text(
                              'Status',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(receipt.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusLabel(receipt.status),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _statusColor(receipt.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ---- Notes ----
                  if (receipt.userNotes != null &&
                      receipt.userNotes!.isNotEmpty) ...[
                    AppSpacing.verticalGapMd,
                    _DetailCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notes,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  AppSpacing.horizontalGapSm,
                                  Text(
                                    'Notes',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.verticalGapSm,
                              Text(
                                receipt.userNotes!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ---- Tags ----
                  if (receipt.userTags.isNotEmpty) ...[
                    AppSpacing.verticalGapMd,
                    _DetailCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.sell_outlined,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  AppSpacing.horizontalGapSm,
                                  Text(
                                    'Tags',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.verticalGapSm,
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: receipt.userTags
                                    .map(
                                      (tag) => Chip(
                                        label: Text(tag),
                                        labelStyle: theme
                                            .textTheme.labelSmall
                                            ?.copyWith(
                                          color: AppColors.primaryGreen,
                                        ),
                                        backgroundColor: AppColors.primaryGreen
                                            .withValues(alpha: 0.08),
                                        side: BorderSide.none,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  AppSpacing.verticalGapLg,

                  // ---- Action buttons ----
                  _ActionButtonBar(
                    onEdit: () => _onEdit(context),
                    onDelete: () => _onDelete(context),
                    onShare: () => _onShare(context),
                    onMarkReturned: receipt.status == ReceiptStatus.active
                        ? () => _onMarkAsReturned(context)
                        : null,
                  ),

                  AppSpacing.verticalGapLg,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

/// Horizontal scrollable gallery of receipt images.
class _ImageGallerySection extends StatelessWidget {
  const _ImageGallerySection({required this.localImagePaths});

  final List<String> localImagePaths;

  @override
  Widget build(BuildContext context) {
    if (localImagePaths.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.cream,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  size: 48, color: AppColors.textLight),
              SizedBox(height: 8),
              Text(
                'No images',
                style: TextStyle(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: localImagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final path = localImagePaths[index];
          final file = File(path);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.existsSync()
                ? Image.file(
                    file,
                    width: 160,
                    height: 204,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const _ImagePlaceholder(width: 160, height: 204),
                  )
                : const _ImagePlaceholder(width: 160, height: 204),
          );
        },
      ),
    );
  }
}

/// Placeholder shown when an image cannot be loaded.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.cream,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}

/// A styled card wrapper for detail sections.
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// A single field row inside a [_DetailCard].
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          AppSpacing.horizontalGapSm,
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of action buttons at the bottom of the detail screen.
class _ActionButtonBar extends StatelessWidget {
  const _ActionButtonBar({
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    this.onMarkReturned,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback? onMarkReturned;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.primaryGreen,
          onPressed: onEdit,
        ),
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.error,
          onPressed: onDelete,
        ),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          color: AppColors.primaryGreen,
          onPressed: onShare,
        ),
        if (onMarkReturned != null)
          _ActionButton(
            icon: Icons.assignment_return_outlined,
            label: 'Returned',
            color: AppColors.accentAmber,
            onPressed: onMarkReturned!,
          ),
      ],
    );
  }
}

/// Individual action button used in [_ActionButtonBar].
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
