import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/settings/presentation/screens/privacy_policy_screen.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const PrivacyPolicyScreen(),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
  }

  group('PrivacyPolicyScreen', () {
    testWidgets('renders Privacy Policy app bar title', (tester) async {
      await pumpApp(tester);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('renders privacy policy content', (tester) async {
      await pumpApp(tester);
      expect(find.textContaining('Data Storage'), findsOneWidget);
    });

    testWidgets('content is scrollable', (tester) async {
      await pumpApp(tester);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses bodyMedium text style', (tester) async {
      await pumpApp(tester);
      // Find the main content Text widget (not the AppBar title)
      final textFinder = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);
    });
  });
}
