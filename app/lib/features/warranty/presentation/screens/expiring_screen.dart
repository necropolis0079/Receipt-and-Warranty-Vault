import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../receipt/domain/entities/receipt.dart';
import '../../../receipt/presentation/screens/receipt_detail_screen.dart';
import '../../../receipt/presentation/widgets/receipt_card.dart';
import '../bloc/expiring_bloc.dart';
import '../bloc/expiring_event.dart';
import '../bloc/expiring_state.dart';

/// Screen displaying warranties that are expiring soon or already expired.
///
/// Driven by [ExpiringBloc] state with pull-to-refresh support and two
/// sections: "Expiring Soon" and "Expired".
class ExpiringScreen extends StatefulWidget {
  const ExpiringScreen({super.key});

  @override
  State<ExpiringScreen> createState() => _ExpiringScreenState();
}

class _ExpiringScreenState extends State<ExpiringScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthAuthenticated ? authState.user.userId : '';
    context.read<ExpiringBloc>().add(ExpiringLoadRequested(_userId));
  }

  Future<void> _onRefresh() async {
    context.read<ExpiringBloc>().add(const ExpiringRefreshRequested());
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToDetail(Receipt receipt) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expiringWarranties),
      ),
      body: BlocBuilder<ExpiringBloc, ExpiringState>(
        builder: (context, state) {
          if (state is ExpiringLoading || state is ExpiringInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpiringError) {
            return _ErrorBody(
              message: state.message,
              onRetry: () => context
                  .read<ExpiringBloc>()
                  .add(ExpiringLoadRequested(_userId)),
            );
          }

          if (state is ExpiringEmpty) {
            return _EmptyBody();
          }

          if (state is ExpiringLoaded) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.expiringSoon.isNotEmpty) ...[
                    _SectionHeader(
                      title: l10n.expiringWarranties,
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.accentAmber,
                    ),
                    ...state.expiringSoon.map(
                      (receipt) => ReceiptCard(
                        receipt: receipt,
                        onTap: () => _navigateToDetail(receipt),
                      ),
                    ),
                  ],
                  if (state.expired.isNotEmpty) ...[
                    _SectionHeader(
                      title: l10n.expired,
                      icon: Icons.timer_off_outlined,
                      color: AppColors.error,
                    ),
                    ...state.expired.map(
                      (receipt) => ReceiptCard(
                        receipt: receipt,
                        onTap: () => _navigateToDetail(receipt),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          // Fallback for any unhandled state.
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// =============================================================================
// Section header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyBody extends StatelessWidget {
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
              Icons.timer_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noExpiringWarranties,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allWarrantiesSafe,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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
