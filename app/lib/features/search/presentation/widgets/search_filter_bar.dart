import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/search_filters.dart';

/// A horizontally scrollable row of filter chips for refining search results.
///
/// Provides quick access to category, date range, and warranty filters.
/// A "Clear Filters" chip appears when any filter is active.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.filters,
    required this.onFilterChanged,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFilterChanged;

  // ---------------------------------------------------------------------------
  // Default category list (mirrors the 10 default categories).
  // ---------------------------------------------------------------------------

  static const _defaultCategories = <String>[
    'Electronics',
    'Groceries',
    'Clothing & Apparel',
    'Home & Furniture',
    'Health & Pharmacy',
    'Restaurants & Food',
    'Transportation',
    'Entertainment',
    'Services & Subscriptions',
    'Other',
  ];

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onCategoryTap(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.filterByCategory,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (filters.category != null)
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop('__clear__'),
                        child: Text(l10n.clearFilters),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _defaultCategories.length,
                  itemBuilder: (_, index) {
                    final cat = _defaultCategories[index];
                    final isSelected = filters.category == cat;
                    return ListTile(
                      title: Text(cat),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primaryGreen)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(cat),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((selected) {
      if (selected == null) return;
      if (selected == '__clear__') {
        onFilterChanged(SearchFilters(
          dateFrom: filters.dateFrom,
          dateTo: filters.dateTo,
          amountMin: filters.amountMin,
          amountMax: filters.amountMax,
          hasWarranty: filters.hasWarranty,
        ));
      } else {
        onFilterChanged(filters.copyWith(category: selected));
      }
    });
  }

  void _onDateRangeTap(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: filters.dateFrom != null && filters.dateTo != null
          ? DateTimeRange(start: filters.dateFrom!, end: filters.dateTo!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGreen,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onFilterChanged(filters.copyWith(
        dateFrom: picked.start,
        dateTo: picked.end,
      ));
    }
  }

  void _onWarrantyTap() {
    // Cycle through: null -> true -> false -> null
    final bool? next;
    if (filters.hasWarranty == null) {
      next = true;
    } else if (filters.hasWarranty == true) {
      next = false;
    } else {
      next = null;
    }

    // Because copyWith does not allow setting to null, rebuild manually.
    onFilterChanged(SearchFilters(
      category: filters.category,
      dateFrom: filters.dateFrom,
      dateTo: filters.dateTo,
      amountMin: filters.amountMin,
      amountMax: filters.amountMax,
      hasWarranty: next,
    ));
  }

  void _onClearAll() {
    onFilterChanged(SearchFilters.empty);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _warrantyLabel(AppLocalizations l10n) {
    if (filters.hasWarranty == true) return l10n.hasWarranty;
    if (filters.hasWarranty == false) return l10n.noWarrantyFilter;
    return l10n.filterByWarranty;
  }

  String _dateLabel(AppLocalizations l10n) {
    if (filters.dateFrom != null && filters.dateTo != null) {
      final from = _formatDate(filters.dateFrom!);
      final to = _formatDate(filters.dateTo!);
      return '$from - $to';
    }
    return l10n.filterByDate;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          // ---- Category chip ----
          _FilterChipWidget(
            label: filters.category ?? l10n.category,
            isActive: filters.category != null,
            onTap: () => _onCategoryTap(context),
          ),
          AppSpacing.horizontalGapSm,

          // ---- Date range chip ----
          _FilterChipWidget(
            label: _dateLabel(l10n),
            isActive: filters.dateFrom != null || filters.dateTo != null,
            onTap: () => _onDateRangeTap(context),
          ),
          AppSpacing.horizontalGapSm,

          // ---- Warranty toggle chip ----
          _FilterChipWidget(
            label: _warrantyLabel(l10n),
            isActive: filters.hasWarranty != null,
            onTap: _onWarrantyTap,
          ),

          // ---- Clear all chip (shown only when filters are active) ----
          if (filters.isActive) ...[
            AppSpacing.horizontalGapSm,
            ActionChip(
              label: Text(l10n.clearFilters),
              avatar: const Icon(Icons.clear, size: 16),
              onPressed: _onClearAll,
              backgroundColor: AppColors.error.withValues(alpha: 0.08),
              labelStyle: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Private helper widget
// =============================================================================

/// A single styled filter chip with active/inactive visual states.
class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryGreen.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: isActive ? AppColors.primaryGreen : AppColors.textMedium,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: isActive
            ? AppColors.primaryGreen.withValues(alpha: 0.5)
            : AppColors.divider,
      ),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
