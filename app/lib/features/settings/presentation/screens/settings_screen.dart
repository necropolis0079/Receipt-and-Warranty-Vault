import 'package:flutter/material.dart';

/// Placeholder screen for the Settings tab.
///
/// Displays a list of setting categories that will be wired up to
/// their respective configuration screens and BLoC logic.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // TODO: Implement language selection
            },
          ),
          _SettingsTile(
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Light',
            onTap: () {
              // TODO: Implement theme selection
            },
          ),
          _SettingsTile(
            icon: Icons.cloud,
            title: 'Storage Mode',
            subtitle: 'Cloud + Device',
            onTap: () {
              // TODO: Implement storage mode selection
            },
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Warranty Reminders',
            subtitle: 'Enabled',
            onTap: () {
              // TODO: Implement reminder settings
            },
          ),
          _SettingsTile(
            icon: Icons.lock,
            title: 'App Lock',
            subtitle: 'Disabled',
            onTap: () {
              // TODO: Implement app lock settings
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              // TODO: Implement about screen
            },
          ),
          const Divider(),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            textColor: Colors.red,
            onTap: () {
              // TODO: Implement sign out
            },
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
