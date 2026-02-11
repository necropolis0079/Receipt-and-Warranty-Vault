import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/vault_bloc.dart';
import '../bloc/vault_event.dart';
import '../bloc/vault_state.dart';
import '../widgets/capture_option_sheet.dart';
import '../widgets/receipt_card.dart';
import 'add_receipt_screen.dart';
import 'receipt_detail_screen.dart';

/// Main vault screen displaying the user's receipt list.
///
/// Driven by [VaultBloc] state. Supports pull-to-refresh, empty/error states,
/// a stats bar, and a FAB for quick receipt capture.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthAuthenticated ? authState.user.userId : '';
    context.read<VaultBloc>().add(VaultLoadRequested(_userId));
  }

  Future<void> _onRefresh() async {
    context.read<VaultBloc>().add(VaultLoadRequested(_userId));
    // Give the stream a moment to emit a new state.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _onFabPressed() async {
    final option = await CaptureOptionSheet.show(context);
    if (option != null && mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AddReceiptScreen(initialOption: option),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myReceipts),
      ),
      body: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          if (state is VaultLoading || state is VaultInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VaultError) {
            return _ErrorBody(
              message: state.message,
              onRetry: () => context
                  .read<VaultBloc>()
                  .add(VaultLoadRequested(_userId)),
            );
          }

          if (state is VaultEmpty) {
            return _EmptyBody(
              onAdd: _onFabPressed,
            );
          }

          if (state is VaultLoaded) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: Column(
                children: [
                  _StatsBar(
                    receiptsCount: state.receipts.length,
                    activeWarranties: state.activeCount,
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = state.receipts[index];
                        return ReceiptCard(
                          receipt: receipt,
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptDetailScreen(receipt: receipt),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Fallback for any unhandled state.
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        tooltip: l10n.addReceipt,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// =============================================================================
// Stats bar
// =============================================================================

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.receiptsCount,
    required this.activeWarranties,
  });

  final int receiptsCount;
  final int activeWarranties;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primaryGreen.withValues(alpha: 0.08),
      child: Text(
        '${l10n.receiptsCount(receiptsCount)} \u00B7 '
        '${l10n.activeWarrantiesCount(activeWarranties)}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noReceiptsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addYourFirstReceipt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addReceipt),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Error state
// =============================================================================

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.error,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
