import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/widgets/app_shell.dart';

/// Smoke test — verifies the app's navigation shell renders without errors.
void main() {
  testWidgets('App shell renders the bottom navigation bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell()),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
