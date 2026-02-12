import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/receipt_field_editors.dart';

void main() {
  Widget buildField(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  group('StoreNameField', () {
    testWidgets('renders with label', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildField(
        StoreNameField(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Store Name'), findsOneWidget);
      expect(find.byIcon(Icons.store_outlined), findsOneWidget);
    });
  });

  group('TotalAmountField', () {
    testWidgets('only allows digits and decimal separators', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildField(
        TotalAmountField(controller: controller),
      ));
      await tester.pumpAndSettle();

      // Enter valid numeric text
      await tester.enterText(find.byType(TextFormField), '12.34');
      expect(controller.text, '12.34');

      // Clear and try text with letters — they should be filtered out
      controller.clear();
      await tester.enterText(find.byType(TextFormField), '12abc.34');
      expect(controller.text, '12.34');

      // Commas should be allowed (European decimal separator)
      controller.clear();
      await tester.enterText(find.byType(TextFormField), '99,50');
      expect(controller.text, '99,50');
    });
  });

  group('CurrencySelector', () {
    testWidgets('shows EUR, USD, GBP options', (tester) async {
      String selected = 'EUR';
      await tester.pumpWidget(buildField(
        CurrencySelector(
          value: selected,
          onChanged: (v) => selected = v,
        ),
      ));
      await tester.pumpAndSettle();

      // The currently selected value should be visible
      expect(find.text('EUR'), findsOneWidget);

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // All three options should appear (in the dropdown overlay)
      expect(find.text('EUR'), findsWidgets);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);
    });
  });

  group('WarrantyEditor', () {
    testWidgets('shows warranty period options', (tester) async {
      int months = 0;
      await tester.pumpWidget(buildField(
        WarrantyEditor(
          months: months,
          onChanged: (v) => months = v,
        ),
      ));
      await tester.pumpAndSettle();

      // Should display the current selection label
      expect(find.text('No Warranty'), findsOneWidget);

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // All warranty period options should appear
      expect(find.text('No Warranty'), findsWidgets);
      expect(find.text('6 months'), findsOneWidget);
      expect(find.text('12 months'), findsOneWidget);
      expect(find.text('24 months'), findsOneWidget);
      expect(find.text('36 months'), findsOneWidget);
      expect(find.text('60 months'), findsOneWidget);
    });
  });

  group('NotesField', () {
    testWidgets('renders with multiline', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildField(
        NotesField(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.byIcon(Icons.notes_outlined), findsOneWidget);

      // Verify the underlying EditableText supports multiple lines
      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.maxLines, 3);
    });
  });
}
