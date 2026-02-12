import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:warrantyvault/core/services/home_widget_service.dart';
import 'package:warrantyvault/core/services/widget_click_handler.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_bloc.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_state.dart';
import 'package:warrantyvault/features/receipt/presentation/screens/vault_screen.dart';
import 'package:warrantyvault/features/warranty/presentation/screens/expiring_screen.dart';
import 'package:warrantyvault/features/receipt/presentation/screens/add_receipt_screen.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/capture_option_sheet.dart';
import 'package:warrantyvault/features/search/presentation/screens/search_screen.dart';
import 'package:warrantyvault/features/settings/presentation/screens/settings_screen.dart';

/// The main application shell providing 5-tab bottom navigation.
///
/// Uses an [IndexedStack] to preserve the state of each tab when switching
/// between them. The center "+Add" tab opens a modal bottom sheet instead of
/// navigating to a tab screen.
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
    SizedBox.shrink(), // Placeholder — Add tab opens modal
    SearchScreen(),
    SettingsScreen(),
  ];

  final HomeWidgetService _homeWidgetService =
      GetIt.I<HomeWidgetService>();
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();

    // Handle cold-start widget launch (URI stored during main()).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingUri = _homeWidgetService.consumePendingUri();
      if (pendingUri != null && mounted) {
        WidgetClickHandler.handle(pendingUri, context);
      }
    });

    // Handle warm-start widget taps.
    _widgetClickSub = _homeWidgetService.widgetClickStream.listen((uri) {
      if (uri != null && mounted) {
        WidgetClickHandler.handle(uri, context);
      }
    });
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _openAddReceipt();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openAddReceipt() async {
    final option = await CaptureOptionSheet.show(context);
    if (option != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddReceiptScreen(initialOption: option),
        ),
      );
    }
  }

  void _onVaultStateChanged(VaultState state) {
    final l10n = AppLocalizations.of(context);
    final String statsText;

    if (state is VaultLoaded) {
      final receiptCount = state.receipts.length;
      final warrantyCount =
          state.receipts.where((r) => r.isWarrantyActive).length;
      statsText =
          '${l10n.receiptsCount(receiptCount)} · ${l10n.activeWarrantiesCount(warrantyCount)}';
    } else if (state is VaultEmpty) {
      statsText =
          '${l10n.receiptsCount(0)} · ${l10n.activeWarrantiesCount(0)}';
    } else {
      return;
    }

    _homeWidgetService.updateStats(statsText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<VaultBloc, VaultState>(
      listener: (context, state) => _onVaultStateChanged(state),
      child: Scaffold(
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
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: l10n.navigationVault,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.timer_outlined),
              activeIcon: const Icon(Icons.timer),
              label: l10n.navigationExpiring,
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
              label: l10n.navigationAdd,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: l10n.navigationSearch,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: l10n.navigationSettings,
            ),
          ],
        ),
      ),
    );
  }
}
