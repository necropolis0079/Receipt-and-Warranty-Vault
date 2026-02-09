import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../bloc/trash_cubit.dart';
import '../bloc/trash_state.dart';

/// Screen displaying soft-deleted receipts with restore/delete actions.
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trash),
      ),
      body: BlocBuilder<TrashCubit, TrashState>(
        builder: (context, state) {
          if (state.isLoading && state.receipts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  AppSpacing.verticalGapMd,
                  Text(
                    l10n.trashEmpty,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.paddingMd,
            itemCount: state.receipts.length,
            separatorBuilder: (_, __) => AppSpacing.verticalGapSm,
            itemBuilder: (context, index) {
              final receipt = state.receipts[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long,
                      color: AppColors.textLight),
                  title: Text(receipt.displayName),
                  subtitle: receipt.deletedAt != null
                      ? Text(
                          '${l10n.delete}: ${receipt.deletedAt}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore,
                            color: AppColors.primaryGreen),
                        tooltip: l10n.restoreReceipt,
                        onPressed: () {
                          context
                              .read<TrashCubit>()
                              .restoreReceipt(receipt.receiptId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            color: AppColors.error),
                        tooltip: l10n.deletePermanently,
                        onPressed: () {
                          _confirmPermanentDelete(
                              context, receipt.receiptId, receipt.displayName,
                              l10n);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmPermanentDelete(
    BuildContext context,
    String receiptId,
    String name,
    AppLocalizations l10n,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePermanently),
        content: Text(l10n.permanentDeleteWarning),
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
      if (confirmed == true && context.mounted) {
        context.read<TrashCubit>().permanentlyDelete(receiptId);
      }
    });
  }
}
