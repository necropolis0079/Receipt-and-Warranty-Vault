import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:get_it/get_it.dart';

import '../../../../core/database/app_database.dart'; // debug seeder only
import '../../../../core/database/daos/categories_dao.dart';
import '../../../../core/database/daos/settings_dao.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/debug/debug_data_seeder.dart';
import '../../../../core/notifications/reminder_scheduler.dart';
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
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../receipt/presentation/bloc/trash_cubit.dart';
import '../../../receipt/presentation/bloc/vault_bloc.dart';
import '../../../receipt/presentation/bloc/vault_event.dart';
import '../../../warranty/presentation/bloc/expiring_bloc.dart';
import '../../../warranty/presentation/bloc/expiring_event.dart';
import '../../../bulk_import/presentation/cubit/bulk_import_cubit.dart';
import '../../../bulk_import/presentation/screens/bulk_import_screen.dart';
import '../../../receipt/presentation/screens/category_management_screen.dart';
import '../../../receipt/presentation/screens/trash_screen.dart';
import 'batch_export_screen.dart';
import 'privacy_policy_screen.dart';

/// Settings screen with live App Lock toggle and Clear All Data action.
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
                      ? l10n.languageGreek
                      : l10n.languageEnglish;
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
                    categoriesDao: GetIt.I<CategoriesDao>(),
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
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          // Debug: Seed test data (remove before production)
          if (kDebugMode)
            _SettingsTile(
              icon: Icons.bug_report,
              title: 'Seed 20 Test Receipts',
              subtitle: 'Debug only — inserts test data',
              onTap: () => _seedTestData(context),
            ),

          const Divider(),

          // Clear All Data — GDPR wipe (device-auth mode)
          _SettingsTile(
            icon: Icons.delete_forever,
            title: l10n.clearAllData,
            textColor: Colors.red,
            onTap: () {
              _showConfirmDialog(
                context,
                title: l10n.clearAllData,
                message: l10n.clearAllDataConfirm,
                onConfirm: () async {
                  // Close the database
                  await DatabaseProvider.close();
                  // Delete account (removes device UUID + emits unauthenticated)
                  if (context.mounted) {
                    context
                        .read<AuthBloc>()
                        .add(const AuthDeleteAccountRequested());
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _seedTestData(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }
    final userId = authState.user.userId;
    final db = GetIt.I<AppDatabase>();
    final seeder = DebugDataSeeder(database: db);

    try {
      final count = await seeder.seedTestData(userId);
      if (context.mounted) {
        // Refresh the vault and expiring warranties
        context.read<VaultBloc>().add(VaultLoadRequested(userId));
        context.read<ExpiringBloc>().add(ExpiringLoadRequested(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeded $count test receipts')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seed error: $e')),
        );
      }
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCubit = context.read<LocaleCubit>();
    final settingsDao = GetIt.I<SettingsDao>();

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
    final settingsDao = GetIt.I<SettingsDao>();

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
  List<int> _selectedIntervals = ReminderScheduler.defaultIntervals;

  /// Maps day values to their l10n label getter.
  static const List<int> _allIntervalOptions = [30, 14, 7, 3, 1, 0];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!GetIt.I.isRegistered<SettingsDao>()) return;
    final value =
        await GetIt.I<SettingsDao>().getValue('reminders_enabled');
    final scheduler = GetIt.I<ReminderScheduler>();
    final intervals = await scheduler.getIntervals();
    if (mounted) {
      setState(() {
        _enabled = value == null || value != 'false';
        _selectedIntervals = intervals;
      });
    }
  }

  String _intervalLabel(int days, AppLocalizations l10n) {
    return switch (days) {
      30 => l10n.days30Before,
      14 => l10n.days14Before,
      7 => l10n.days7Before,
      3 => l10n.days3Before,
      1 => l10n.days1Before,
      0 => l10n.dayOfExpiry,
      _ => '$days',
    };
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
    final settingsDao = GetIt.I<SettingsDao>();
    final notificationService = GetIt.I<NotificationService>();
    final scheduler = GetIt.I<ReminderScheduler>();

    // Work with a local copy so we can revert on cancel if needed.
    var dialogEnabled = _enabled;
    var dialogIntervals = List<int>.from(_selectedIntervals);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.reminderSettings),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l10n.warrantyReminders),
                  value: dialogEnabled,
                  onChanged: (value) async {
                    setDialogState(() => dialogEnabled = value);
                    setState(() => _enabled = value);
                    await settingsDao.setValue(
                      'reminders_enabled',
                      value.toString(),
                    );
                    if (!value) {
                      await notificationService.cancelAllReminders();
                    }
                  },
                ),
                if (dialogEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 8, bottom: 4),
                    child: Text(
                      l10n.reminderIntervalsMessage,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _allIntervalOptions.map((days) {
                        final selected = dialogIntervals.contains(days);
                        return FilterChip(
                          label: Text(_intervalLabel(days, l10n)),
                          selected: selected,
                          onSelected: (isSelected) async {
                            setDialogState(() {
                              if (isSelected) {
                                dialogIntervals.add(days);
                              } else {
                                dialogIntervals.remove(days);
                              }
                            });
                            setState(() {
                              _selectedIntervals =
                                  List<int>.from(dialogIntervals);
                            });
                            await scheduler.saveIntervals(dialogIntervals);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
