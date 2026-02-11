import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/bulk_import/domain/entities/gallery_candidate.dart';
import 'package:warrantyvault/features/bulk_import/domain/services/gallery_scanner_service.dart';
import 'package:warrantyvault/features/bulk_import/presentation/cubit/bulk_import_cubit.dart';
import 'package:warrantyvault/features/bulk_import/presentation/cubit/bulk_import_state.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/domain/services/image_pipeline_service.dart';
import 'package:warrantyvault/features/receipt/domain/services/ocr_service.dart';

class MockGalleryScannerService extends Mock
    implements GalleryScannerService {}

class MockImagePipelineService extends Mock implements ImagePipelineService {}

class MockOcrService extends Mock implements OcrService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class FakeImageData extends Fake implements ImageData {}

class FakeReceipt extends Fake implements Receipt {}

void main() {
  late MockGalleryScannerService mockScanner;
  late MockImagePipelineService mockPipeline;
  late MockOcrService mockOcr;
  late MockReceiptRepository mockRepo;

  final testCandidates = [
    GalleryCandidate(
      id: 'c-1',
      localPath: '/path/to/image1.jpg',
      thumbnailPath: '/path/to/thumb1.jpg',
      width: 600,
      height: 1000,
      sizeBytes: 500000,
      createdAt: DateTime(2026, 1, 15),
    ),
    GalleryCandidate(
      id: 'c-2',
      localPath: '/path/to/image2.jpg',
      thumbnailPath: '/path/to/thumb2.jpg',
      width: 500,
      height: 900,
      sizeBytes: 300000,
      createdAt: DateTime(2026, 1, 10),
    ),
    GalleryCandidate(
      id: 'c-3',
      localPath: '/path/to/image3.jpg',
      thumbnailPath: '/path/to/thumb3.jpg',
      width: 400,
      height: 800,
      sizeBytes: 250000,
      createdAt: DateTime(2026, 1, 5),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FakeImageData());
    registerFallbackValue(FakeReceipt());
  });

  setUp(() {
    mockScanner = MockGalleryScannerService();
    mockPipeline = MockImagePipelineService();
    mockOcr = MockOcrService();
    mockRepo = MockReceiptRepository();
  });

  BulkImportCubit buildCubit() => BulkImportCubit(
        galleryScannerService: mockScanner,
        imagePipelineService: mockPipeline,
        ocrService: mockOcr,
        receiptRepository: mockRepo,
      );

  group('BulkImportCubit', () {
    test('initial state is BulkImportInitial', () {
      final cubit = buildCubit();
      expect(cubit.state, const BulkImportInitial());
      cubit.close();
    });

    // --- scanGallery ---
    group('scanGallery', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, PermissionDenied] when permission denied',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => false);
          when(() => mockScanner.requestPermission())
              .thenAnswer((_) async => false);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          const BulkImportPermissionDenied(),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, CandidatesReady] with empty list when no receipts found',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(maxMonths: any(named: 'maxMonths')))
              .thenAnswer((_) async => []);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          const BulkImportCandidatesReady(
            candidates: [],
            selectedIds: {},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, CandidatesReady] with all selected when candidates found',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(maxMonths: any(named: 'maxMonths')))
              .thenAnswer((_) async => testCandidates);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          BulkImportCandidatesReady(
            candidates: testCandidates,
            selectedIds: {'c-1', 'c-2', 'c-3'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'requests permission when not already granted',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => false);
          when(() => mockScanner.requestPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(maxMonths: any(named: 'maxMonths')))
              .thenAnswer((_) async => testCandidates);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          BulkImportCandidatesReady(
            candidates: testCandidates,
            selectedIds: {'c-1', 'c-2', 'c-3'},
          ),
        ],
        verify: (_) {
          verify(() => mockScanner.requestPermission()).called(1);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, Error] when scanner throws',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(maxMonths: any(named: 'maxMonths')))
              .thenThrow(Exception('Storage error'));
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          isA<BulkImportError>(),
        ],
      );
    });

    // --- toggleSelection ---
    group('toggleSelection', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'removes id when already selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: testCandidates,
          selectedIds: {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) => cubit.toggleSelection('c-2'),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: testCandidates,
            selectedIds: {'c-1', 'c-3'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'adds id when not selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: testCandidates,
          selectedIds: {'c-1'},
        ),
        act: (cubit) => cubit.toggleSelection('c-2'),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: testCandidates,
            selectedIds: {'c-1', 'c-2'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is not CandidatesReady',
        build: () => buildCubit(),
        act: (cubit) => cubit.toggleSelection('c-1'),
        expect: () => [],
      );
    });

    // --- selectAll / deselectAll ---
    group('selectAll', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'selects all candidates',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: testCandidates,
          selectedIds: {'c-1'},
        ),
        act: (cubit) => cubit.selectAll(),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: testCandidates,
            selectedIds: {'c-1', 'c-2', 'c-3'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is not CandidatesReady',
        build: () => buildCubit(),
        act: (cubit) => cubit.selectAll(),
        expect: () => [],
      );
    });

    group('deselectAll', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'clears all selections',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: testCandidates,
          selectedIds: {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) => cubit.deselectAll(),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: testCandidates,
            selectedIds: const {},
          ),
        ],
      );
    });

    // --- importSelected ---
    group('importSelected', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is not CandidatesReady',
        build: () => buildCubit(),
        act: (cubit) => cubit.importSelected('user-1'),
        expect: () => [],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when no candidates are selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: testCandidates,
          selectedIds: const {},
        ),
        act: (cubit) => cubit.importSelected('user-1'),
        expect: () => [],
      );
    });
  });
}
