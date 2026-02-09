import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/auth/presentation/screens/welcome_screen.dart';

void main() {
  bool getStartedCalled = false;

  setUp(() {
    getStartedCalled = false;
  });

  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: WelcomeScreen(
        onGetStarted: () => getStartedCalled = true,
      ),
    );
  }

  testWidgets('displays first onboarding page', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Warranty Vault'), findsOneWidget);
    expect(
      find.text(
          'Capture receipts instantly with your camera or import from your gallery.'),
      findsOneWidget,
    );
  });

  testWidgets('displays skip button', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('skip button calls onGetStarted', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    expect(getStartedCalled, true);
  });

  testWidgets('displays Next button on first page', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('shows Get Started on last page', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Swipe to second page
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // Swipe to third page
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Get Started on last page calls onGetStarted', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Swipe to last page
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    expect(getStartedCalled, true);
  });
}
