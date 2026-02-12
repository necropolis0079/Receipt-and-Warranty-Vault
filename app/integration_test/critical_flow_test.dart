import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/add_receipt_bloc.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/add_receipt_event.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/add_receipt_state.dart';
import 'package:warrantyvault/features/receipt/presentation/screens/add_receipt_screen.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestContext ctx;

  setUp(() async {
    ctx = await setUpTestContext();
  });

  tearDown(() async {
    await tearDownTestContext(ctx);
  });

  // ---------------------------------------------------------------------------
  // Scenario 1: Full capture → OCR → edit → save flow
  // ---------------------------------------------------------------------------
  group('Capture-to-Save Flow', () {
    testWidgets('capture image, run OCR, edit store name, save receipt',
        (tester) async {
      // Stub: camera returns image, OCR returns high confidence
      when(() => ctx.imagePipeline.captureFromCamera())
          .thenAnswer((_) async => testImage);
      when(() => ctx.imagePipeline.processImage(testImage))
          .thenAnswer((_) async => testImage);
      when(() => ctx.ocrService.recognizeMultipleImages(any()))
          .thenAnswer((_) async => highConfidenceOcr);
      when(() => ctx.ocrService.parseRawText(any()))
          .thenReturn(highConfidenceOcr);

      await tester.pumpWidget(buildTestApp(
        ctx,
        const AddReceiptScreen(),
      ));
      await tester.pumpAndSettle();

      // The screen should render. Choose camera capture.
      expect(find.text('Take Photo'), findsOneWidget);
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      // After capture, images are ready — proceed to OCR.
      expect(find.text('Scan Receipt'), findsOneWidget);
      await tester.tap(find.text('Scan Receipt'));
      await tester.pumpAndSettle();

      // After OCR, fields should be pre-filled.
      expect(find.text('Store ABC'), findsOneWidget);

      // Save the receipt.
      await tester.scrollUntilVisible(
        find.text('Save Receipt'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Receipt'));
      await tester.pumpAndSettle();

      // Verify save was called
      verify(() => ctx.receiptRepo.saveReceipt(any())).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Scenario 2: Low OCR confidence → banner → retry
  // ---------------------------------------------------------------------------
  group('Low OCR Confidence Flow', () {
    testWidgets('low confidence shows banner, retry runs OCR again',
        (tester) async {
      // Use bloc directly for this scenario since we want to control states
      final bloc = AddReceiptBloc(
        imagePipelineService: ctx.imagePipeline,
        ocrService: ctx.ocrService,
        receiptRepository: ctx.receiptRepo,
      );

      // First OCR → low confidence
      when(() => ctx.ocrService.recognizeMultipleImages(any()))
          .thenAnswer((_) async => lowConfidenceOcr);
      when(() => ctx.ocrService.parseRawText(any()))
          .thenReturn(lowConfidenceOcr);

      bloc.add(const ImagesSelected([testImage]));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProcessOcr());

      await expectLater(
        bloc.stream,
        emitsThrough(isA<AddReceiptFieldsReady>().having(
          (s) => s.ocrResult?.confidence,
          'confidence',
          lessThan(0.34),
        )),
      );

      // Now retry with better result
      when(() => ctx.ocrService.recognizeMultipleImages(any()))
          .thenAnswer((_) async => highConfidenceOcr);
      when(() => ctx.ocrService.parseRawText(any()))
          .thenReturn(highConfidenceOcr);

      bloc.add(const RetryOcr());

      await expectLater(
        bloc.stream,
        emitsThrough(isA<AddReceiptFieldsReady>().having(
          (s) => s.ocrResult?.confidence,
          'confidence',
          greaterThan(0.8),
        )),
      );

      await bloc.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Scenario 3: Permission denied → state → retry
  // ---------------------------------------------------------------------------
  group('Permission Denied Flow', () {
    testWidgets('camera permission denied emits state, then proceeds on retry',
        (tester) async {
      final bloc = AddReceiptBloc(
        imagePipelineService: ctx.imagePipeline,
        ocrService: ctx.ocrService,
        receiptRepository: ctx.receiptRepo,
      );

      // First attempt: permission denied
      when(() => ctx.imagePipeline.requestCameraPermission())
          .thenAnswer((_) async => false);

      bloc.add(const CaptureFromCamera());

      await expectLater(
        bloc.stream,
        emits(const AddReceiptPermissionDenied(PermissionType.camera)),
      );

      // Second attempt: permission granted
      when(() => ctx.imagePipeline.requestCameraPermission())
          .thenAnswer((_) async => true);
      when(() => ctx.imagePipeline.captureFromCamera())
          .thenAnswer((_) async => testImage);
      when(() => ctx.imagePipeline.processImage(testImage))
          .thenAnswer((_) async => testImage);

      bloc.add(const CaptureFromCamera());

      await expectLater(
        bloc.stream,
        emitsThrough(isA<AddReceiptImagesReady>()),
      );

      await bloc.close();
    });

    testWidgets('gallery permission denied emits state', (tester) async {
      final bloc = AddReceiptBloc(
        imagePipelineService: ctx.imagePipeline,
        ocrService: ctx.ocrService,
        receiptRepository: ctx.receiptRepo,
      );

      when(() => ctx.imagePipeline.requestStoragePermission())
          .thenAnswer((_) async => false);

      bloc.add(const ImportFromGallery());

      await expectLater(
        bloc.stream,
        emits(const AddReceiptPermissionDenied(PermissionType.gallery)),
      );

      await bloc.close();
    });
  });
}
