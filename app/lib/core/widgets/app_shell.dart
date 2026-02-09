import 'package:flutter/material.dart';
import 'package:warrantyvault/features/receipt/presentation/screens/vault_screen.dart';
import 'package:warrantyvault/features/warranty/presentation/screens/expiring_screen.dart';
import 'package:warrantyvault/features/receipt/presentation/screens/add_receipt_screen.dart';
import 'package:warrantyvault/features/search/presentation/screens/search_screen.dart';
import 'package:warrantyvault/features/settings/presentation/screens/settings_screen.dart';

/// The main application shell providing 5-tab bottom navigation.
///
/// Uses an [IndexedStack] to preserve the state of each tab when switching
/// between them. The center "+Add" tab is styled to be visually prominent.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _forestGreen = Color(0xFF2D5A3D);
  static const _unselectedGray = Color(0xFF6B7280);

  final List<Widget> _screens = const [
    VaultScreen(),
    ExpiringScreen(),
    AddReceiptScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _forestGreen,
        unselectedItemColor: _unselectedGray,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Vault',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Expiring',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              size: 32,
              color: _currentIndex == 2 ? _forestGreen : _unselectedGray,
            ),
            activeIcon: const Icon(
              Icons.add_circle,
              size: 32,
              color: _forestGreen,
            ),
            label: 'Add',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
