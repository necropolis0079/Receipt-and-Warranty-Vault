import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/capture_option_sheet.dart';

void main() {
  CaptureOption? selectedOption;

  Widget buildSheet() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: CaptureOptionSheet(
          onSelected: (option) => selectedOption = option,
        ),
      ),
    );
  }

  setUp(() {
    selectedOption = null;
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pump(); // Allow l10n delegates to resolve
  }

  group('CaptureOptionSheet', () {
    testWidgets('renders all three capture options', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Import Files'), findsOneWidget);
    });

    testWidgets('shows Take Photo option', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Capture receipt with camera'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('shows Choose from Gallery option', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Select existing photos'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('shows Import Files option', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Import Files'), findsOneWidget);
      expect(find.text('Images or PDF documents'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('calls onSelected with camera when Take Photo tapped',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Take Photo'));
      expect(selectedOption, CaptureOption.camera);
    });

    testWidgets('calls onSelected with gallery when Gallery tapped',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Choose from Gallery'));
      expect(selectedOption, CaptureOption.gallery);
    });

    testWidgets('calls onSelected with files when Import tapped',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Import Files'));
      expect(selectedOption, CaptureOption.files);
    });
  });
}
