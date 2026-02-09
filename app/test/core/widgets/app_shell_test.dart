import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/widgets/app_shell.dart';

void main() {
  Widget buildApp() {
    return const MaterialApp(home: AppShell());
  }

  group('AppShell', () {
    testWidgets('renders a BottomNavigationBar', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('shows all 5 tab labels', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Vault'), findsOneWidget);
      expect(find.text('Expiring'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      // "Settings" appears as both tab label and AppBar title when selected,
      // but on startup the Vault tab is active so only the tab label shows.
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('starts on the Vault tab (index 0)', (tester) async {
      await tester.pumpWidget(buildApp());

      // The Vault screen's AppBar title is "My Receipts".
      expect(find.text('My Receipts'), findsOneWidget);
    });

    testWidgets('uses IndexedStack to preserve tab state', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('tapping Expiring tab shows expiring screen', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Expiring'));
      await tester.pumpAndSettle();

      expect(find.text('Expiring Warranties'), findsOneWidget);
    });

    testWidgets('tapping Search tab shows search screen', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Search'), findsWidgets);
    });

    testWidgets('tapping Add tab shows add receipt screen', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add Receipt'), findsOneWidget);
    });
  });
}
