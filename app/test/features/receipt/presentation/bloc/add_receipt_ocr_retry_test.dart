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

  const testImage1 = ImageData(
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

  const lowConfidenceOcr = OcrResult(
    rawText: 'blurry text',
    confidence: 0.2,
  );

  const highConfidenceOcr = OcrResult(
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

  group('AddMoreImages', () {
    blocTest<AddReceiptBloc, AddReceiptState>(
      'appends new images to FieldsReady state',
      build: buildBloc,
      seed: () => const AddReceiptFieldsReady(
        images: [testImage1],
        ocrResult: lowConfidenceOcr,
      ),
      act: (bloc) => bloc.add(const AddMoreImages([testImage2])),
      expect: () => [
        const AddReceiptFieldsReady(
          images: [testImage1, testImage2],
          ocrResult: lowConfidenceOcr,
        ),
      ],
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'does nothing when not in FieldsReady state',
      build: buildBloc,
      seed: () => const AddReceiptInitial(),
      act: (bloc) => bloc.add(const AddMoreImages([testImage2])),
      expect: () => <AddReceiptState>[],
    );
  });

  group('RetryOcr', () {
    blocTest<AddReceiptBloc, AddReceiptState>(
      'reruns OCR on current images and emits [ProcessingOcr, FieldsReady]',
      build: () {
        when(() => mockOcrService.recognizeMultipleImages(any()))
            .thenAnswer((_) async => highConfidenceOcr);
        when(() => mockOcrService.parseRawText(any()))
            .thenReturn(highConfidenceOcr);
        return buildBloc();
      },
      seed: () => const AddReceiptFieldsReady(
        images: [testImage1, testImage2],
        ocrResult: lowConfidenceOcr,
      ),
      act: (bloc) => bloc.add(const RetryOcr()),
      expect: () => [
        const AddReceiptProcessingOcr([testImage1, testImage2]),
        const AddReceiptFieldsReady(
          images: [testImage1, testImage2],
          storeName: 'Store ABC',
          purchaseDate: '2024-01-15',
          totalAmount: 49.99,
          currency: 'EUR',
          ocrResult: highConfidenceOcr,
        ),
      ],
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'emits Error when OCR fails during retry',
      build: () {
        when(() => mockOcrService.recognizeMultipleImages(any()))
            .thenThrow(Exception('OCR engine failed'));
        return buildBloc();
      },
      seed: () => const AddReceiptFieldsReady(
        images: [testImage1],
        ocrResult: lowConfidenceOcr,
      ),
      act: (bloc) => bloc.add(const RetryOcr()),
      expect: () => [
        const AddReceiptProcessingOcr([testImage1]),
        isA<AddReceiptError>(),
      ],
    );
  });
}
