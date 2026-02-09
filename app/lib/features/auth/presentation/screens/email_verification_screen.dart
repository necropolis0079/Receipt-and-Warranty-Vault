import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onVerify() {
    final code = _codeController.text.trim();
    if (code.length == 6) {
      context.read<AuthBloc>().add(AuthConfirmSignUpRequested(
            email: widget.email,
            code: code,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.authVerifyEmail),
        backgroundColor: Colors.transparent,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is AuthCodeResent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.authCodeResent)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.verticalGapXl,
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: AppColors.primaryGreen,
              ),
              AppSpacing.verticalGapLg,
              Text(
                l10n.authVerificationSent,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGapSm,
              Text(
                widget.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGapXl,

              // 6-digit code field
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.authVerificationCode,
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 8,
                ),
              ),
              AppSpacing.verticalGapLg,

              // Verify button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onVerify,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(l10n.confirm),
                    ),
                  );
                },
              ),
              AppSpacing.verticalGapMd,

              // Resend code
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                        AuthResendCodeRequested(email: widget.email),
                      );
                },
                child: Text(l10n.authResendCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
