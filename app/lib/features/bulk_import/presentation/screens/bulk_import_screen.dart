import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../cubit/bulk_import_cubit.dart';
import '../cubit/bulk_import_state.dart';
import '../widgets/candidate_grid_item.dart';

class BulkImportScreen extends StatelessWidget {
  const BulkImportScreen({
    super.key,
    this.onComplete,
  });

  /// Called when import completes or the user skips/closes.
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bulkImport),
        actions: [
          TextButton(
            onPressed: () => _finish(context),
            child: Text(l10n.skipOnboarding),
          ),
        ],
      ),
      body: BlocConsumer<BulkImportCubit, BulkImportState>(
        listener: (context, state) {
          if (state is BulkImportComplete) {
            final message = state.failedCount > 0
                ? l10n.bulkImportCompleteWithFailures(
                    state.count, state.failedCount)
                : l10n.foundImages(state.count);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            BulkImportInitial() => _buildInitial(context, l10n),
            BulkImportScanning() => _buildScanning(l10n),
            BulkImportCandidatesReady() =>
              _buildCandidates(context, l10n, state),
            BulkImportProcessing() => _buildProcessing(l10n, state),
            BulkImportComplete() => _buildComplete(context, l10n, state),
            BulkImportError() => _buildError(context, l10n, state),
            BulkImportPermissionDenied() =>
              _buildPermissionDenied(context, l10n),
          };
        },
      ),
    );
  }

  Widget _buildInitial(BuildContext context, AppLocalizations l10n) {
    // Auto-start scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BulkImportCubit>().scanGallery();
    });
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.bulkImport,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildScanning(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(l10n.scanningGallery),
        ],
      ),
    );
  }

  Widget _buildCandidates(
    BuildContext context,
    AppLocalizations l10n,
    BulkImportCandidatesReady state,
  ) {
    if (state.candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, size: 64),
            const SizedBox(height: 16),
            Text(l10n.foundImages(0)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _finish(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }

    final cubit = context.read<BulkImportCubit>();
    final selectedCount = state.selectedIds.length;

    return Column(
      children: [
        // Header with count and select/deselect buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.foundImages(state.candidates.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: selectedCount == state.candidates.length
                    ? cubit.deselectAll
                    : cubit.selectAll,
                child: Text(
                  selectedCount == state.candidates.length
                      ? l10n.deselectAll
                      : l10n.selectAll,
                ),
              ),
            ],
          ),
        ),

        // Grid of candidates
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65,
            ),
            itemCount: state.candidates.length,
            itemBuilder: (context, index) {
              final candidate = state.candidates[index];
              return CandidateGridItem(
                candidate: candidate,
                isSelected: state.selectedIds.contains(candidate.id),
                onTap: () => cubit.toggleSelection(candidate.id),
              );
            },
          ),
        ),

        // Import button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedCount > 0
                    ? () => _startImport(context)
                    : null,
                icon: const Icon(Icons.download),
                label: Text(
                  '${l10n.importSelected} ($selectedCount)',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing(AppLocalizations l10n, BulkImportProcessing state) {
    final progress = state.total > 0 ? state.current / state.total : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress),
            const SizedBox(height: 24),
            Text('${state.current} / ${state.total}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(
    BuildContext context,
    AppLocalizations l10n,
    BulkImportComplete state,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.failedCount > 0 ? Icons.warning_amber : Icons.check_circle,
            size: 64,
            color: state.failedCount > 0
                ? const Color(0xFFD4920B)
                : const Color(0xFF2D5A3D),
          ),
          const SizedBox(height: 16),
          Text(
            state.failedCount > 0
                ? l10n.bulkImportCompleteWithFailures(
                    state.count, state.failedCount)
                : l10n.foundImages(state.count),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _finish(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppLocalizations l10n,
    BulkImportError state,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFC0392B)),
          const SizedBox(height: 16),
          Text(l10n.genericError),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<BulkImportCubit>().scanGallery(),
            child: Text(l10n.retry),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _finish(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.genericError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  context.read<BulkImportCubit>().scanGallery(),
              child: Text(l10n.retry),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _finish(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  void _startImport(BuildContext context) {
    // userId will be provided by the parent — for now use empty string
    // The auth_gate integration passes the real userId
    context.read<BulkImportCubit>().importSelected('');
  }

  void _finish(BuildContext context) {
    if (onComplete != null) {
      onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }
}
