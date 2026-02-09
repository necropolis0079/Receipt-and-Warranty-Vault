import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/search_filters.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_result_list.dart';

/// Full search screen with debounced text input, filter chips, and
/// state-driven result display.
///
/// Uses [SearchBloc] to issue queries and react to search lifecycle states.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Current client-side filters. Kept in widget state so the filter bar can
  /// update independently of the bloc (which receives the filters via events).
  SearchFilters _filters = SearchFilters.empty;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    });
  }

  void _onFilterChanged(SearchFilters filters) {
    setState(() => _filters = filters);
    context.read<SearchBloc>().add(SearchFilterChanged(filters));
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() => _filters = SearchFilters.empty);
    context.read<SearchBloc>().add(const SearchCleared());
  }

  void _onRetry() {
    final query = _searchController.text;
    if (query.trim().isNotEmpty) {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchReceipts),
      ),
      body: Column(
        children: [
          // ---- Search text field ----
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _onClearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
          ),

          // ---- Filter chips bar ----
          SearchFilterBar(
            filters: _filters,
            onFilterChanged: _onFilterChanged,
          ),

          // ---- Results area ----
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                return switch (state) {
                  SearchInitial() => _buildInitialState(l10n),
                  SearchLoading() => _buildLoadingState(),
                  SearchEmpty(:final query) => _buildEmptyState(l10n, query),
                  SearchLoaded(:final results) =>
                    SearchResultList(results: results),
                  SearchError(:final message) =>
                    _buildErrorState(l10n, message),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // State-specific builders
  // ---------------------------------------------------------------------------

  Widget _buildInitialState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search,
            size: 64,
            color: AppColors.textLight,
          ),
          AppSpacing.verticalGapMd,
          Text(
            l10n.searchReceipts,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, String query) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textLight,
            ),
            AppSpacing.verticalGapMd,
            Text(
              '${l10n.noResultsFound} "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String message) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            AppSpacing.verticalGapMd,
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGapMd,
            OutlinedButton.icon(
              onPressed: _onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
