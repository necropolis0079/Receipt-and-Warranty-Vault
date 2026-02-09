import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:get_it/get_it.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/app_lock_cubit.dart';
import '../../../../core/security/app_lock_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../receipt/presentation/screens/category_management_screen.dart';

/// Settings screen with live App Lock toggle and Sign Out action.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: 'English',
            onTap: () {
              // TODO: Implement language selection
            },
          ),
          _SettingsTile(
            icon: Icons.palette,
            title: l10n.theme,
            subtitle: l10n.themeLight,
            onTap: () {
              // TODO: Implement theme selection
            },
          ),
          _SettingsTile(
            icon: Icons.cloud,
            title: l10n.storageMode,
            subtitle: l10n.cloudAndDevice,
            onTap: () {
              // TODO: Implement storage mode selection
            },
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: l10n.warrantyReminders,
            subtitle: 'Enabled',
            onTap: () {
              // TODO: Implement reminder settings
            },
          ),

          // App Lock toggle — wired to AppLockCubit
          BlocBuilder<AppLockCubit, AppLockState>(
            builder: (context, lockState) {
              return SwitchListTile(
                secondary: const Icon(Icons.lock),
                title: Text(l10n.enableAppLock),
                subtitle: Text(
                  lockState.isEnabled
                      ? l10n.biometricAuth
                      : lockState.isDeviceSupported
                          ? l10n.appLock
                          : l10n.appLockBiometricUnavailable,
                ),
                value: lockState.isEnabled,
                onChanged: lockState.isDeviceSupported
                    ? (enabled) {
                        if (enabled) {
                          context.read<AppLockCubit>().enable();
                        } else {
                          context.read<AppLockCubit>().disable();
                        }
                      }
                    : null,
              );
            },
          ),

          _SettingsTile(
            icon: Icons.category,
            title: l10n.manageCategories,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CategoryManagementScreen(
                    categoriesDao: GetIt.I<AppDatabase>().categoriesDao,
                  ),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: l10n.about,
            onTap: () {
              // TODO: Implement about screen
            },
          ),
          const Divider(),

          // Sign Out — wired to AuthBloc
          _SettingsTile(
            icon: Icons.logout,
            title: l10n.signOut,
            textColor: Colors.red,
            onTap: () {
              _showConfirmDialog(
                context,
                title: l10n.signOut,
                message: l10n.authSignOutConfirm,
                onConfirm: () {
                  context
                      .read<AuthBloc>()
                      .add(const AuthSignOutRequested());
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: Text(
              l10n.confirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
