import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/presentation/widgets/ocr_feedback_banner.dart';

void main() {
  bool addPhotoPressed = false;
  bool fillManuallyPressed = false;

  Widget buildBanner() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: OcrFeedbackBanner(
          onAddBetterPhoto: () => addPhotoPressed = true,
          onFillManually: () => fillManuallyPressed = true,
        ),
      ),
    );
  }

  setUp(() {
    addPhotoPressed = false;
    fillManuallyPressed = false;
  });

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(buildBanner());
    await tester.pumpAndSettle();
  }

  group('OcrFeedbackBanner', () {
    testWidgets('renders warning icon', (tester) async {
      await pumpBanner(tester);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders low-confidence title', (tester) async {
      await pumpBanner(tester);
      expect(find.text('Low Recognition Quality'), findsOneWidget);
    });

    testWidgets('renders low-confidence message', (tester) async {
      await pumpBanner(tester);
      expect(find.textContaining("couldn't read"), findsOneWidget);
    });

    testWidgets('renders Add Better Photo button with camera icon',
        (tester) async {
      await pumpBanner(tester);
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.text('Add Better Photo'), findsOneWidget);
    });

    testWidgets('renders Fill Manually button', (tester) async {
      await pumpBanner(tester);
      expect(find.text('Fill Manually'), findsOneWidget);
    });

    testWidgets('tapping Add Better Photo calls onAddBetterPhoto',
        (tester) async {
      await pumpBanner(tester);
      await tester.tap(find.text('Add Better Photo'));
      expect(addPhotoPressed, isTrue);
    });

    testWidgets('tapping Fill Manually calls onFillManually', (tester) async {
      await pumpBanner(tester);
      await tester.tap(find.text('Fill Manually'));
      expect(fillManuallyPressed, isTrue);
    });
  });
}
