import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

class FakeReceipt extends Fake implements Receipt {}

void main() {
  late MockImagePipelineService mockImagePipeline;
  late MockOcrService mockOcrService;
  late MockReceiptRepository mockReceiptRepo;

  const testImage = ImageData(
    id: 'img-1',
    localPath: '/tmp/receipt1.jpg',
    sizeBytes: 1024,
    mimeType: 'image/jpeg',
  );

  const testImage2 = ImageData(
    id: 'img-2',
    localPath: '/tmp/receipt2.jpg',
    sizeBytes: 2048,
    mimeType: 'image/jpeg',
  );

  const testCroppedImage = ImageData(
    id: 'img-1',
    localPath: '/tmp/receipt1_cropped.jpg',
    sizeBytes: 900,
    mimeType: 'image/jpeg',
  );

  const testOcrResult = OcrResult(
    rawText: 'Store ABC\n2024-01-15\nTotal: 49.99 EUR',
    extractedStoreName: 'Store ABC',
    extractedDate: '2024-01-15',
    extractedTotal: 49.99,
    extractedCurrency: 'EUR',
    confidence: 0.85,
  );

  setUp(() {
    mockImagePipeline = MockImagePipelineService();
    mockOcrService = MockOcrService();
    mockReceiptRepo = MockReceiptRepository();

    registerFallbackValue(FakeReceipt());
  });

  AddReceiptBloc buildBloc() => AddReceiptBloc(
        imagePipelineService: mockImagePipeline,
        ocrService: mockOcrService,
        receiptRepository: mockReceiptRepo,
      );

  group('AddReceiptBloc', () {
    // -------------------------------------------------------------------------
    // 1. Initial state
    // -------------------------------------------------------------------------
    test('initial state is AddReceiptInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const AddReceiptInitial());
      bloc.close();
    });

    // -------------------------------------------------------------------------
    // 2. CaptureFromCamera — success
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'CaptureFromCamera emits [Capturing, ImagesReady] on success',
      build: () {
        when(() => mockImagePipeline.captureFromCamera())
            .thenAnswer((_) async => testImage);
        when(() => mockImagePipeline.processImage(testImage))
            .thenAnswer((_) async => testImage);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CaptureFromCamera()),
      expect: () => [
        const AddReceiptCapturing(),
        const AddReceiptImagesReady([testImage]),
      ],
    );

    // -------------------------------------------------------------------------
    // 3. CaptureFromCamera — user cancels (null result)
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'CaptureFromCamera emits [Capturing, Initial] when user cancels',
      build: () {
        when(() => mockImagePipeline.captureFromCamera())
            .thenAnswer((_) async => null);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CaptureFromCamera()),
      expect: () => [
        const AddReceiptCapturing(),
        const AddReceiptInitial(),
      ],
    );

    // -------------------------------------------------------------------------
    // 4. CaptureFromCamera — failure
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'CaptureFromCamera emits [Capturing, Error] on failure',
      build: () {
        when(() => mockImagePipeline.captureFromCamera())
            .thenThrow(Exception('Camera unavailable'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CaptureFromCamera()),
      expect: () => [
        const AddReceiptCapturing(),
        isA<AddReceiptError>(),
      ],
    );

    // -------------------------------------------------------------------------
    // 5. ImportFromGallery — success
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'ImportFromGallery emits [Capturing, ImagesReady]',
      build: () {
        when(() => mockImagePipeline.pickFromGallery(maxImages: any(named: 'maxImages')))
            .thenAnswer((_) async => [testImage, testImage2]);
        when(() => mockImagePipeline.processImage(testImage))
            .thenAnswer((_) async => testImage);
        when(() => mockImagePipeline.processImage(testImage2))
            .thenAnswer((_) async => testImage2);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ImportFromGallery()),
      expect: () => [
        const AddReceiptCapturing(),
        const AddReceiptImagesReady([testImage, testImage2]),
      ],
    );

    // -------------------------------------------------------------------------
    // 6. ImportFromFiles — success
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'ImportFromFiles emits [Capturing, ImagesReady]',
      build: () {
        when(() => mockImagePipeline.pickFromFiles())
            .thenAnswer((_) async => [testImage]);
        when(() => mockImagePipeline.processImage(testImage))
            .thenAnswer((_) async => testImage);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ImportFromFiles()),
      expect: () => [
        const AddReceiptCapturing(),
        const AddReceiptImagesReady([testImage]),
      ],
    );

    // -------------------------------------------------------------------------
    // 7. CropImage — updates image in list
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'CropImage updates image in list',
      build: () {
        when(() => mockImagePipeline.cropImage(testImage))
            .thenAnswer((_) async => testCroppedImage);
        return buildBloc();
      },
      seed: () => const AddReceiptImagesReady([testImage, testImage2]),
      act: (bloc) => bloc.add(const CropImage(0)),
      expect: () => [
        const AddReceiptImagesReady([testCroppedImage, testImage2]),
      ],
    );

    // -------------------------------------------------------------------------
    // 8. RemoveImage — removes from list
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'RemoveImage removes from list',
      build: buildBloc,
      seed: () => const AddReceiptImagesReady([testImage, testImage2]),
      act: (bloc) => bloc.add(const RemoveImage(0)),
      expect: () => [
        const AddReceiptImagesReady([testImage2]),
      ],
    );

    // -------------------------------------------------------------------------
    // 9. RemoveImage — last image returns to Initial
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'RemoveImage on last image returns to Initial',
      build: buildBloc,
      seed: () => const AddReceiptImagesReady([testImage]),
      act: (bloc) => bloc.add(const RemoveImage(0)),
      expect: () => [
        const AddReceiptInitial(),
      ],
    );

    // -------------------------------------------------------------------------
    // 10. ProcessOcr — success
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'ProcessOcr emits [ProcessingOcr, FieldsReady] with extracted values',
      build: () {
        when(() => mockOcrService.recognizeMultipleImages(any()))
            .thenAnswer((_) async => testOcrResult);
        when(() => mockOcrService.parseRawText(any()))
            .thenReturn(testOcrResult);
        return buildBloc();
      },
      seed: () => const AddReceiptImagesReady([testImage]),
      act: (bloc) => bloc.add(const ProcessOcr()),
      expect: () => [
        const AddReceiptProcessingOcr([testImage]),
        const AddReceiptFieldsReady(
          images: [testImage],
          storeName: 'Store ABC',
          purchaseDate: '2024-01-15',
          totalAmount: 49.99,
          currency: 'EUR',
          ocrResult: testOcrResult,
        ),
      ],
    );

    // -------------------------------------------------------------------------
    // 11. ProcessOcr — failure
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'ProcessOcr emits [ProcessingOcr, Error] on failure',
      build: () {
        when(() => mockOcrService.recognizeMultipleImages(any()))
            .thenThrow(Exception('OCR engine failed'));
        return buildBloc();
      },
      seed: () => const AddReceiptImagesReady([testImage]),
      act: (bloc) => bloc.add(const ProcessOcr()),
      expect: () => [
        const AddReceiptProcessingOcr([testImage]),
        isA<AddReceiptError>(),
      ],
    );

    // -------------------------------------------------------------------------
    // 12. UpdateField — updates store name
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'UpdateField updates store name',
      build: buildBloc,
      seed: () => const AddReceiptFieldsReady(
        images: [testImage],
        storeName: 'Store ABC',
        ocrResult: testOcrResult,
      ),
      act: (bloc) => bloc.add(const UpdateField('storeName', 'New Store')),
      expect: () => [
        const AddReceiptFieldsReady(
          images: [testImage],
          storeName: 'New Store',
          ocrResult: testOcrResult,
        ),
      ],
    );

    // -------------------------------------------------------------------------
    // 13. SetCategory — updates category
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'SetCategory updates category',
      build: buildBloc,
      seed: () => const AddReceiptFieldsReady(
        images: [testImage],
        ocrResult: testOcrResult,
      ),
      act: (bloc) => bloc.add(const SetCategory('Electronics')),
      expect: () => [
        const AddReceiptFieldsReady(
          images: [testImage],
          category: 'Electronics',
          ocrResult: testOcrResult,
        ),
      ],
    );

    // -------------------------------------------------------------------------
    // 14. SetWarranty — updates warranty months
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'SetWarranty updates warranty months',
      build: buildBloc,
      seed: () => const AddReceiptFieldsReady(
        images: [testImage],
        ocrResult: testOcrResult,
      ),
      act: (bloc) => bloc.add(const SetWarranty(24)),
      expect: () => [
        const AddReceiptFieldsReady(
          images: [testImage],
          warrantyMonths: 24,
          ocrResult: testOcrResult,
        ),
      ],
    );

    // -------------------------------------------------------------------------
    // 15. SaveReceipt — success
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'SaveReceipt emits [Saving, Saved]',
      build: () {
        when(() => mockReceiptRepo.saveReceipt(any()))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const AddReceiptFieldsReady(
        images: [testImage],
        storeName: 'Store ABC',
        purchaseDate: '2024-01-15',
        totalAmount: 49.99,
        ocrResult: testOcrResult,
      ),
      act: (bloc) => bloc.add(const SaveReceipt('user-123')),
      expect: () => [
        const AddReceiptSaving([testImage]),
        isA<AddReceiptSaved>(),
      ],
    );

    // -------------------------------------------------------------------------
    // 16. SaveReceipt — failure
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'SaveReceipt emits [Saving, Error] on failure',
      build: () {
        when(() => mockReceiptRepo.saveReceipt(any()))
            .thenThrow(Exception('Database error'));
        return buildBloc();
      },
      seed: () => const AddReceiptFieldsReady(
        images: [testImage],
        storeName: 'Store ABC',
        ocrResult: testOcrResult,
      ),
      act: (bloc) => bloc.add(const SaveReceipt('user-123')),
      expect: () => [
        const AddReceiptSaving([testImage]),
        isA<AddReceiptError>(),
      ],
    );

    // -------------------------------------------------------------------------
    // 17. FastSave — success with default values
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'FastSave emits [Saving, Saved] with default values',
      build: () {
        when(() => mockReceiptRepo.saveReceipt(any()))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const AddReceiptImagesReady([testImage]),
      act: (bloc) => bloc.add(const FastSave('user-123')),
      expect: () => [
        const AddReceiptSaving([testImage]),
        isA<AddReceiptSaved>(),
      ],
    );

    // -------------------------------------------------------------------------
    // 18. ResetForm — returns to Initial
    // -------------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'ResetForm returns to Initial',
      build: buildBloc,
      seed: () => const AddReceiptFieldsReady(
        images: [testImage],
        storeName: 'Store ABC',
        ocrResult: testOcrResult,
      ),
      act: (bloc) => bloc.add(const ResetForm()),
      expect: () => [
        const AddReceiptInitial(),
      ],
    );
  });
}
