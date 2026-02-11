import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:get_it/get_it.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/l10n/locale_state.dart';
import '../../../../core/l10n/supported_locales.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/security/app_lock_cubit.dart';
import '../../../../core/security/app_lock_state.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../receipt/presentation/bloc/trash_cubit.dart';
import '../../../bulk_import/presentation/cubit/bulk_import_cubit.dart';
import '../../../bulk_import/presentation/screens/bulk_import_screen.dart';
import '../../../receipt/presentation/screens/category_management_screen.dart';
import '../../../receipt/presentation/screens/trash_screen.dart';
import 'batch_export_screen.dart';

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
          // Language
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              final displayName =
                  localeState.locale.languageCode == 'el'
                      ? 'Ελληνικά'
                      : 'English';
              return _SettingsTile(
                icon: Icons.language,
                title: l10n.language,
                subtitle: displayName,
                onTap: () => _showLanguageDialog(context),
              );
            },
          ),

          // Theme
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final subtitle = switch (themeState.mode) {
                AppThemeMode.light => l10n.themeLight,
                AppThemeMode.dark => l10n.themeDark,
                AppThemeMode.system => l10n.themeSystem,
              };
              return _SettingsTile(
                icon: Icons.palette,
                title: l10n.theme,
                subtitle: subtitle,
                onTap: () => _showThemeDialog(context),
              );
            },
          ),

          // Reminders
          _ReminderTile(),

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
            icon: Icons.delete_outline,
            title: l10n.trash,
            onTap: () {
              final trashCubit = context.read<TrashCubit>()..loadDeleted();
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: trashCubit,
                    child: const TrashScreen(),
                  ),
                ),
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
            icon: Icons.file_download,
            title: l10n.exportByDateRange,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const BatchExportScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.photo_library,
            title: l10n.bulkImport,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => GetIt.I<BulkImportCubit>(),
                    child: const BulkImportScreen(),
                  ),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: l10n.about,
            onTap: () => _showAboutInfo(context),
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

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCubit = context.read<LocaleCubit>();
    final settingsDao = GetIt.I<AppDatabase>().settingsDao;

    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          SimpleDialogOption(
            onPressed: () {
              localeCubit.changeLocale(SupportedLocales.english);
              settingsDao.setValue('locale', 'en');
              Navigator.of(ctx).pop();
            },
            child: const Text('English'),
          ),
          SimpleDialogOption(
            onPressed: () {
              localeCubit.changeLocale(SupportedLocales.greek);
              settingsDao.setValue('locale', 'el');
              Navigator.of(ctx).pop();
            },
            child: const Text('Ελληνικά'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCubit = context.read<ThemeCubit>();
    final settingsDao = GetIt.I<AppDatabase>().settingsDao;

    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.theme),
        children: [
          SimpleDialogOption(
            onPressed: () {
              themeCubit.changeTheme(AppThemeMode.light);
              settingsDao.setValue('theme', AppThemeMode.light.name);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.themeLight),
          ),
          SimpleDialogOption(
            onPressed: () {
              themeCubit.changeTheme(AppThemeMode.dark);
              settingsDao.setValue('theme', AppThemeMode.dark.name);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.themeDark),
          ),
          SimpleDialogOption(
            onPressed: () {
              themeCubit.changeTheme(AppThemeMode.system);
              settingsDao.setValue('theme', AppThemeMode.system.name);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.themeSystem),
          ),
        ],
      ),
    );
  }

  void _showAboutInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.shield,
        size: 48,
        color: Color(0xFF2D5A3D),
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

/// Stateful reminder tile that reads its initial value from the settings DAO.
class _ReminderTile extends StatefulWidget {
  @override
  State<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<_ReminderTile> {
  bool _enabled = true; // default: enabled

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    if (!GetIt.I.isRegistered<AppDatabase>()) return;
    final value =
        await GetIt.I<AppDatabase>().settingsDao.getValue('reminders_enabled');
    if (mounted && value != null) {
      setState(() => _enabled = value != 'false');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsTile(
      icon: Icons.notifications,
      title: l10n.warrantyReminders,
      subtitle: _enabled ? l10n.reminderEnabled : l10n.reminderDisabled,
      onTap: () => _showReminderDialog(context),
    );
  }

  void _showReminderDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsDao = GetIt.I<AppDatabase>().settingsDao;
    final notificationService = GetIt.I<NotificationService>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.reminderSettings),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(l10n.warrantyReminders),
                  value: _enabled,
                  onChanged: (value) async {
                    setDialogState(() => _enabled = value);
                    setState(() {});
                    await settingsDao.setValue(
                      'reminders_enabled',
                      value.toString(),
                    );
                    if (!value) {
                      await notificationService.cancelAllReminders();
                    }
                  },
                ),
                if (_enabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      '${l10n.reminderDaysBefore(7)}\n'
                      '${l10n.reminderDaysBefore(1)}\n'
                      '${l10n.expiringToday}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.ok),
              ),
            ],
          );
        },
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
