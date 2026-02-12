import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/auth/presentation/widgets/app_lock_prompt_dialog.dart';

void main() {
  Widget buildApp({required ValueChanged<bool> onResult}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final result = await AppLockPromptDialog.show(context);
                onResult(result);
              },
              child: const Text('Show Dialog'),
            ),
          );
        },
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
  }

  group('AppLockPromptDialog', () {
    testWidgets('renders title with lock icon', (tester) async {
      await tester.pumpWidget(buildApp(onResult: (_) {}));
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Secure Your Receipts'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders prompt message', (tester) async {
      await tester.pumpWidget(buildApp(onResult: (_) {}));
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.textContaining('biometric'), findsOneWidget);
    });

    testWidgets('renders Enable Now and Maybe Later buttons', (tester) async {
      await tester.pumpWidget(buildApp(onResult: (_) {}));
      await tester.pumpAndSettle();
      await openDialog(tester);

      expect(find.text('Enable Now'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
    });

    testWidgets('Enable Now returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(buildApp(onResult: (v) => result = v));
      await tester.pumpAndSettle();
      await openDialog(tester);

      await tester.tap(find.text('Enable Now'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Maybe Later returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(buildApp(onResult: (v) => result = v));
      await tester.pumpAndSettle();
      await openDialog(tester);

      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('dialog is not dismissible by tapping outside', (tester) async {
      await tester.pumpWidget(buildApp(onResult: (_) {}));
      await tester.pumpAndSettle();
      await openDialog(tester);

      // Tap outside the dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.text('Secure Your Receipts'), findsOneWidget);
    });
  });
}
