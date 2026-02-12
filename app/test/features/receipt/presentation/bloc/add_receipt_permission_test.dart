import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';
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

  group('Permission denial handling', () {
    // -----------------------------------------------------------------------
    // Camera permission denied
    // -----------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'CaptureFromCamera emits PermissionDenied(camera) when denied',
      build: () {
        when(() => mockImagePipeline.requestCameraPermission())
            .thenAnswer((_) async => false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CaptureFromCamera()),
      expect: () => [
        const AddReceiptPermissionDenied(PermissionType.camera),
      ],
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'CaptureFromCamera proceeds when camera permission granted',
      build: () {
        when(() => mockImagePipeline.requestCameraPermission())
            .thenAnswer((_) async => true);
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

    // -----------------------------------------------------------------------
    // Gallery permission denied
    // -----------------------------------------------------------------------
    blocTest<AddReceiptBloc, AddReceiptState>(
      'ImportFromGallery emits PermissionDenied(gallery) when denied',
      build: () {
        when(() => mockImagePipeline.requestStoragePermission())
            .thenAnswer((_) async => false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ImportFromGallery()),
      expect: () => [
        const AddReceiptPermissionDenied(PermissionType.gallery),
      ],
    );

    blocTest<AddReceiptBloc, AddReceiptState>(
      'ImportFromGallery proceeds when storage permission granted',
      build: () {
        when(() => mockImagePipeline.requestStoragePermission())
            .thenAnswer((_) async => true);
        when(() => mockImagePipeline.pickFromGallery(
                maxImages: any(named: 'maxImages')))
            .thenAnswer((_) async => [testImage]);
        when(() => mockImagePipeline.processImage(testImage))
            .thenAnswer((_) async => testImage);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ImportFromGallery()),
      expect: () => [
        const AddReceiptCapturing(),
        const AddReceiptImagesReady([testImage]),
      ],
    );

    // -----------------------------------------------------------------------
    // PermissionType enum & state equality
    // -----------------------------------------------------------------------
    test('PermissionDenied states with same type are equal', () {
      const a = AddReceiptPermissionDenied(PermissionType.camera);
      const b = AddReceiptPermissionDenied(PermissionType.camera);
      expect(a, equals(b));
    });

    test('PermissionDenied states with different types are not equal', () {
      const camera = AddReceiptPermissionDenied(PermissionType.camera);
      const gallery = AddReceiptPermissionDenied(PermissionType.gallery);
      expect(camera, isNot(equals(gallery)));
    });
  });
}
