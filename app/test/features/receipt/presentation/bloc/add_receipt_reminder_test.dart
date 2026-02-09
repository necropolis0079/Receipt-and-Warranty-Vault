import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:warrantyvault/core/notifications/reminder_scheduler.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';
import 'package:warrantyvault/features/receipt/domain/entities/ocr_result.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/domain/services/image_pipeline_service.dart';
import 'package:warrantyvault/features/receipt/domain/services/ocr_service.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/add_receipt_bloc.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/add_receipt_event.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/add_receipt_state.dart';

class MockImagePipelineService extends Mock implements ImagePipelineService {}

class MockOcrService extends Mock implements OcrService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late MockImagePipelineService mockImagePipeline;
  late MockOcrService mockOcrService;
  late MockReceiptRepository mockReceiptRepository;
  late MockReminderScheduler mockReminderScheduler;

  const testImage = ImageData(
    id: 'img-1',
    localPath: '/tmp/receipt.jpg',
    sizeBytes: 1024,
    mimeType: 'image/jpeg',
  );

  const testOcrResult = OcrResult(
    rawText: 'Test Store\n2026-01-15\nTotal: 49.99 EUR',
    extractedStoreName: 'Test Store',
    extractedDate: '2026-01-15',
    extractedTotal: 49.99,
    extractedCurrency: 'EUR',
    confidence: 0.85,
  );

  setUp(() {
    mockImagePipeline = MockImagePipelineService();
    mockOcrService = MockOcrService();
    mockReceiptRepository = MockReceiptRepository();
    mockReminderScheduler = MockReminderScheduler();

    // Register fallback values for any() matchers.
    registerFallbackValue(Receipt(
      receiptId: 'fallback',
      userId: 'fallback',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ));
  });

  /// Helper that creates a bloc, sends ImagesSelected + ProcessOcr to reach
  /// AddReceiptFieldsReady, and then returns the bloc for further use.
  ///
  /// The caller should set up OCR mocks before invoking this.
  AddReceiptBloc buildBlocAtFieldsReady({
    ReminderScheduler? reminderScheduler,
  }) {
    return AddReceiptBloc(
      imagePipelineService: mockImagePipeline,
      ocrService: mockOcrService,
      receiptRepository: mockReceiptRepository,
      reminderScheduler: reminderScheduler,
    );
  }

  /// Sets up the standard OCR mocks that drive the bloc from ImagesReady
  /// to FieldsReady.
  void setUpOcrMocks({int warrantyMonths = 12}) {
    when(() => mockOcrService.recognizeMultipleImages(any()))
        .thenAnswer((_) async => testOcrResult);
    when(() => mockOcrService.parseRawText(any())).thenReturn(testOcrResult);
  }

  group('AddReceiptBloc reminder scheduling', () {
    blocTest<AddReceiptBloc, AddReceiptState>(
      'SaveReceipt with warrantyMonths > 0 calls '
      'reminderScheduler.scheduleForReceipt',
      setUp: () {
        setUpOcrMocks();
        when(() => mockReceiptRepository.saveReceipt(any()))
            .thenAnswer((_) async {});
        when(() => mockReminderScheduler.scheduleForReceipt(any()))
            .thenAnswer((_) async {});
      },
      build: () => buildBlocAtFieldsReady(
        reminderScheduler: mockReminderScheduler,
      ),
      act: (bloc) async {
        // Step 1: Select images.
        bloc.add(const ImagesSelected([testImage]));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 2: Process OCR to reach FieldsReady.
        bloc.add(const ProcessOcr());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Step 3: Set warranty duration.
        bloc.add(const SetWarranty(12));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 4: Save the receipt.
        bloc.add(const SaveReceipt('user-1'));
      },
      verify: (_) {
        verify(() => mockReminderScheduler.scheduleForReceipt(
              any(that: isA<Receipt>().having(
                    (r) => r.warrantyMonths,
                    'warrantyMonths',
                    equals(12),
                  )),
            )).called(1);
      },
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'SaveReceipt with warrantyMonths == 0 does NOT call '
      'reminderScheduler.scheduleForReceipt',
      setUp: () {
        setUpOcrMocks();
        when(() => mockReceiptRepository.saveReceipt(any()))
            .thenAnswer((_) async {});
        when(() => mockReminderScheduler.scheduleForReceipt(any()))
            .thenAnswer((_) async {});
      },
      build: () => buildBlocAtFieldsReady(
        reminderScheduler: mockReminderScheduler,
      ),
      act: (bloc) async {
        // Step 1: Select images.
        bloc.add(const ImagesSelected([testImage]));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 2: Process OCR to reach FieldsReady (warrantyMonths defaults to 0).
        bloc.add(const ProcessOcr());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Step 3: Save without setting warranty (stays at default 0).
        bloc.add(const SaveReceipt('user-1'));
      },
      verify: (_) {
        verifyNever(
            () => mockReminderScheduler.scheduleForReceipt(any()));
      },
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'FastSave with warrantyMonths > 0 calls '
      'reminderScheduler.scheduleForReceipt',
      setUp: () {
        setUpOcrMocks();
        when(() => mockReceiptRepository.saveReceipt(any()))
            .thenAnswer((_) async {});
        when(() => mockReminderScheduler.scheduleForReceipt(any()))
            .thenAnswer((_) async {});
      },
      build: () => buildBlocAtFieldsReady(
        reminderScheduler: mockReminderScheduler,
      ),
      act: (bloc) async {
        // Step 1: Select images.
        bloc.add(const ImagesSelected([testImage]));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 2: Process OCR to reach FieldsReady.
        bloc.add(const ProcessOcr());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Step 3: Set warranty duration.
        bloc.add(const SetWarranty(24));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 4: FastSave.
        bloc.add(const FastSave('user-1'));
      },
      verify: (_) {
        verify(() => mockReminderScheduler.scheduleForReceipt(
              any(that: isA<Receipt>().having(
                    (r) => r.warrantyMonths,
                    'warrantyMonths',
                    equals(24),
                  )),
            )).called(1);
      },
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'SaveReceipt without reminderScheduler (null) still saves successfully',
      setUp: () {
        setUpOcrMocks();
        when(() => mockReceiptRepository.saveReceipt(any()))
            .thenAnswer((_) async {});
      },
      build: () => buildBlocAtFieldsReady(
        reminderScheduler: null,
      ),
      act: (bloc) async {
        // Step 1: Select images.
        bloc.add(const ImagesSelected([testImage]));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 2: Process OCR to reach FieldsReady.
        bloc.add(const ProcessOcr());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Step 3: Set warranty duration.
        bloc.add(const SetWarranty(6));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Step 4: Save.
        bloc.add(const SaveReceipt('user-1'));
      },
      expect: () => [
        // ImagesSelected -> ImagesReady
        const AddReceiptImagesReady([testImage]),
        // ProcessOcr -> ProcessingOcr
        const AddReceiptProcessingOcr([testImage]),
        // ProcessOcr -> FieldsReady
        isA<AddReceiptFieldsReady>(),
        // SetWarranty -> FieldsReady with warrantyMonths=6
        isA<AddReceiptFieldsReady>()
            .having((s) => s.warrantyMonths, 'warrantyMonths', 6),
        // SaveReceipt -> Saving
        const AddReceiptSaving([testImage]),
        // SaveReceipt -> Saved
        isA<AddReceiptSaved>(),
      ],
      verify: (_) {
        // Receipt was saved despite no reminderScheduler.
        verify(() => mockReceiptRepository.saveReceipt(any())).called(1);
      },
    );
  });
}
