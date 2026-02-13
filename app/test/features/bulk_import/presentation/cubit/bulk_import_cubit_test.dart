import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/bulk_import/domain/entities/gallery_candidate.dart';
import 'package:warrantyvault/features/bulk_import/domain/services/gallery_scanner_service.dart';
import 'package:warrantyvault/features/bulk_import/presentation/cubit/bulk_import_cubit.dart';
import 'package:warrantyvault/features/bulk_import/presentation/cubit/bulk_import_state.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';
import 'package:warrantyvault/features/receipt/domain/entities/ocr_result.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/domain/services/image_pipeline_service.dart';
import 'package:warrantyvault/features/receipt/domain/services/ocr_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGalleryScannerService extends Mock
    implements GalleryScannerService {}

class MockImagePipelineService extends Mock implements ImagePipelineService {}

class MockOcrService extends Mock implements OcrService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class FakeImageData extends Fake implements ImageData {}

class FakeReceipt extends Fake implements Receipt {}

class MockFile extends Mock implements File {}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _testCandidates = [
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

const _testOcrResult = OcrResult(
  rawText: 'Store ABC\n2024-01-15\nTotal: 49.99 EUR',
  extractedStoreName: 'Store ABC',
  extractedDate: '2024-01-15',
  extractedTotal: 49.99,
  extractedCurrency: 'EUR',
  confidence: 0.85,
);

const _processedImage = ImageData(
  id: 'processed-1',
  localPath: '/processed/image1.jpg',
  thumbnailPath: '/processed/thumb1.jpg',
  sizeBytes: 200000,
  mimeType: 'image/jpeg',
  width: 600,
  height: 1000,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockGalleryScannerService mockScanner;
  late MockImagePipelineService mockPipeline;
  late MockOcrService mockOcr;
  late MockReceiptRepository mockRepo;

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

  /// Creates a MockFile whose length() returns [sizeBytes].
  MockFile buildMockFile({int sizeBytes = 500000}) {
    final file = MockFile();
    when(() => file.length()).thenAnswer((_) async => sizeBytes);
    return file;
  }

  /// Sets up the standard stubs required for a successful single-item import
  /// pipeline (File.length, processImage, recognizeText, saveReceipt).
  void stubSuccessfulImportPipeline() {
    when(() => mockPipeline.processImage(any()))
        .thenAnswer((_) async => _processedImage);
    when(() => mockOcr.recognizeText(any()))
        .thenAnswer((_) async => _testOcrResult);
    when(() => mockRepo.saveReceipt(any())).thenAnswer((_) async {});
  }

  // =========================================================================
  // State equality tests
  // =========================================================================
  group('BulkImportState equality', () {
    test('BulkImportInitial instances are equal', () {
      expect(const BulkImportInitial(), equals(const BulkImportInitial()));
    });

    test('BulkImportScanning instances are equal', () {
      expect(const BulkImportScanning(), equals(const BulkImportScanning()));
    });

    test('BulkImportPermissionDenied instances are equal', () {
      expect(
        const BulkImportPermissionDenied(),
        equals(const BulkImportPermissionDenied()),
      );
    });

    test('BulkImportCandidatesReady equality depends on candidates and selectedIds', () {
      final stateA = BulkImportCandidatesReady(
        candidates: _testCandidates,
        selectedIds: const {'c-1', 'c-2'},
      );
      final stateB = BulkImportCandidatesReady(
        candidates: _testCandidates,
        selectedIds: const {'c-1', 'c-2'},
      );
      final stateC = BulkImportCandidatesReady(
        candidates: _testCandidates,
        selectedIds: const {'c-1'},
      );

      expect(stateA, equals(stateB));
      expect(stateA, isNot(equals(stateC)));
    });

    test('BulkImportCandidatesReady with different candidates are not equal', () {
      final stateA = BulkImportCandidatesReady(
        candidates: [_testCandidates[0]],
        selectedIds: const {'c-1'},
      );
      final stateB = BulkImportCandidatesReady(
        candidates: [_testCandidates[1]],
        selectedIds: const {'c-1'},
      );

      expect(stateA, isNot(equals(stateB)));
    });

    test('BulkImportProcessing equality depends on current and total', () {
      const stateA = BulkImportProcessing(current: 1, total: 3);
      const stateB = BulkImportProcessing(current: 1, total: 3);
      const stateC = BulkImportProcessing(current: 2, total: 3);

      expect(stateA, equals(stateB));
      expect(stateA, isNot(equals(stateC)));
    });

    test('BulkImportComplete equality depends on count and failedCount', () {
      const stateA = BulkImportComplete(count: 3, failedCount: 0);
      const stateB = BulkImportComplete(count: 3, failedCount: 0);
      const stateC = BulkImportComplete(count: 3, failedCount: 1);
      const stateD = BulkImportComplete(count: 2, failedCount: 0);

      expect(stateA, equals(stateB));
      expect(stateA, isNot(equals(stateC)));
      expect(stateA, isNot(equals(stateD)));
    });

    test('BulkImportComplete default failedCount is 0', () {
      const state = BulkImportComplete(count: 5);
      expect(state.failedCount, equals(0));
    });

    test('BulkImportError equality depends on message', () {
      const stateA = BulkImportError(message: 'error A');
      const stateB = BulkImportError(message: 'error A');
      const stateC = BulkImportError(message: 'error B');

      expect(stateA, equals(stateB));
      expect(stateA, isNot(equals(stateC)));
    });

    test('different state types are not equal', () {
      expect(
        const BulkImportInitial(),
        isNot(equals(const BulkImportScanning())),
      );
      expect(
        const BulkImportComplete(count: 0),
        isNot(equals(const BulkImportError(message: ''))),
      );
    });
  });

  // =========================================================================
  // Cubit tests
  // =========================================================================
  group('BulkImportCubit', () {
    test('initial state is BulkImportInitial', () {
      final cubit = buildCubit();
      expect(cubit.state, const BulkImportInitial());
      cubit.close();
    });

    // -----------------------------------------------------------------------
    // scanGallery
    // -----------------------------------------------------------------------
    group('scanGallery', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, PermissionDenied] when permission not granted and request denied',
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
        'does not call scanForReceipts when permission denied',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => false);
          when(() => mockScanner.requestPermission())
              .thenAnswer((_) async => false);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        verify: (_) {
          verifyNever(
            () => mockScanner.scanForReceipts(
                maxMonths: any(named: 'maxMonths')),
          );
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, CandidatesReady] with all selected when permission already granted',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(
                  maxMonths: any(named: 'maxMonths')))
              .thenAnswer((_) async => _testCandidates);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {'c-1', 'c-2', 'c-3'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'skips requestPermission when already granted',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(
                  maxMonths: any(named: 'maxMonths')))
              .thenAnswer((_) async => _testCandidates);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        verify: (_) {
          verifyNever(() => mockScanner.requestPermission());
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'requests permission when not already granted, proceeds on approval',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => false);
          when(() => mockScanner.requestPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(
                  maxMonths: any(named: 'maxMonths')))
              .thenAnswer((_) async => _testCandidates);
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {'c-1', 'c-2', 'c-3'},
          ),
        ],
        verify: (_) {
          verify(() => mockScanner.requestPermission()).called(1);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, CandidatesReady] with empty list when no receipts found',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(
                  maxMonths: any(named: 'maxMonths')))
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
        'emits [Scanning, Error] when hasPermission throws',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenThrow(Exception('Platform error'));
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          isA<BulkImportError>().having(
            (e) => e.message,
            'message',
            contains('Platform error'),
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, Error] when scanForReceipts throws',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockScanner.scanForReceipts(
                  maxMonths: any(named: 'maxMonths')))
              .thenThrow(Exception('Storage error'));
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          isA<BulkImportError>().having(
            (e) => e.message,
            'message',
            contains('Storage error'),
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits [Scanning, Error] when requestPermission throws',
        build: () {
          when(() => mockScanner.hasPermission())
              .thenAnswer((_) async => false);
          when(() => mockScanner.requestPermission())
              .thenThrow(Exception('Permission API crash'));
          return buildCubit();
        },
        act: (cubit) => cubit.scanGallery(),
        expect: () => [
          const BulkImportScanning(),
          isA<BulkImportError>().having(
            (e) => e.message,
            'message',
            contains('Permission API crash'),
          ),
        ],
      );
    });

    // -----------------------------------------------------------------------
    // toggleSelection
    // -----------------------------------------------------------------------
    group('toggleSelection', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'removes id when already selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) => cubit.toggleSelection('c-2'),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {'c-1', 'c-3'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'adds id when not selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1'},
        ),
        act: (cubit) => cubit.toggleSelection('c-2'),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {'c-1', 'c-2'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'can toggle last selected off (empty set)',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1'},
        ),
        act: (cubit) => cubit.toggleSelection('c-1'),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is BulkImportInitial',
        build: () => buildCubit(),
        act: (cubit) => cubit.toggleSelection('c-1'),
        expect: () => [],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is BulkImportScanning',
        build: () => buildCubit(),
        seed: () => const BulkImportScanning(),
        act: (cubit) => cubit.toggleSelection('c-1'),
        expect: () => [],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is BulkImportProcessing',
        build: () => buildCubit(),
        seed: () => const BulkImportProcessing(current: 1, total: 3),
        act: (cubit) => cubit.toggleSelection('c-1'),
        expect: () => [],
      );
    });

    // -----------------------------------------------------------------------
    // selectAll
    // -----------------------------------------------------------------------
    group('selectAll', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'selects all candidates when only some are selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1'},
        ),
        act: (cubit) => cubit.selectAll(),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {'c-1', 'c-2', 'c-3'},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'selects all candidates when none are selected',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {},
        ),
        act: (cubit) => cubit.selectAll(),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {'c-1', 'c-2', 'c-3'},
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

    // -----------------------------------------------------------------------
    // deselectAll
    // -----------------------------------------------------------------------
    group('deselectAll', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'clears all selections',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) => cubit.deselectAll(),
        expect: () => [
          BulkImportCandidatesReady(
            candidates: _testCandidates,
            selectedIds: const {},
          ),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits empty set even if already empty (state re-emitted)',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {},
        ),
        act: (cubit) => cubit.deselectAll(),
        // Equatable deduplication means no emission if the set was already empty
        expect: () => [],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is not CandidatesReady',
        build: () => buildCubit(),
        seed: () => const BulkImportProcessing(current: 1, total: 2),
        act: (cubit) => cubit.deselectAll(),
        expect: () => [],
      );
    });

    // -----------------------------------------------------------------------
    // importSelected
    // -----------------------------------------------------------------------
    group('importSelected', () {
      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when state is not CandidatesReady',
        build: () => buildCubit(),
        act: (cubit) => cubit.importSelected('user-1'),
        expect: () => [],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'does nothing when no candidates are selected (empty selection)',
        build: () => buildCubit(),
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {},
        ),
        act: (cubit) => cubit.importSelected('user-1'),
        expect: () => [],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits Processing states then Complete when all items succeed',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(sizeBytes: 500000),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 3),
          const BulkImportProcessing(current: 2, total: 3),
          const BulkImportProcessing(current: 3, total: 3),
          const BulkImportComplete(count: 3, failedCount: 0),
        ],
        verify: (_) {
          verify(() => mockPipeline.processImage(any())).called(3);
          verify(() => mockOcr.recognizeText(any())).called(3);
          verify(() => mockRepo.saveReceipt(any())).called(3);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'emits Processing then Complete for a single selected item',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-2'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(sizeBytes: 300000),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 1),
          const BulkImportComplete(count: 1, failedCount: 0),
        ],
        verify: (_) {
          verify(() => mockPipeline.processImage(any())).called(1);
          verify(() => mockOcr.recognizeText(any())).called(1);
          verify(() => mockRepo.saveReceipt(any())).called(1);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'partial failures: reports successful count and failedCount correctly',
        build: () {
          // First call succeeds, second throws, third succeeds
          var processCallCount = 0;
          when(() => mockPipeline.processImage(any())).thenAnswer((_) async {
            processCallCount++;
            if (processCallCount == 2) {
              throw Exception('OCR pipeline failure for item 2');
            }
            return _processedImage;
          });
          when(() => mockOcr.recognizeText(any()))
              .thenAnswer((_) async => _testOcrResult);
          when(() => mockRepo.saveReceipt(any())).thenAnswer((_) async {});
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 3),
          const BulkImportProcessing(current: 2, total: 3),
          const BulkImportProcessing(current: 3, total: 3),
          const BulkImportComplete(count: 2, failedCount: 1),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'partial failures in OCR: count reflects only successful imports',
        build: () {
          when(() => mockPipeline.processImage(any()))
              .thenAnswer((_) async => _processedImage);

          // OCR fails on the first item
          var ocrCallCount = 0;
          when(() => mockOcr.recognizeText(any())).thenAnswer((_) async {
            ocrCallCount++;
            if (ocrCallCount == 1) {
              throw Exception('OCR recognition failure');
            }
            return _testOcrResult;
          });
          when(() => mockRepo.saveReceipt(any())).thenAnswer((_) async {});
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 3),
          const BulkImportProcessing(current: 2, total: 3),
          const BulkImportProcessing(current: 3, total: 3),
          const BulkImportComplete(count: 2, failedCount: 1),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'partial failures in saveReceipt: failedCount reflects save errors',
        build: () {
          when(() => mockPipeline.processImage(any()))
              .thenAnswer((_) async => _processedImage);
          when(() => mockOcr.recognizeText(any()))
              .thenAnswer((_) async => _testOcrResult);

          // saveReceipt fails on second call
          var saveCallCount = 0;
          when(() => mockRepo.saveReceipt(any())).thenAnswer((_) async {
            saveCallCount++;
            if (saveCallCount == 2) {
              throw Exception('DB write failure');
            }
          });
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 3),
          const BulkImportProcessing(current: 2, total: 3),
          const BulkImportProcessing(current: 3, total: 3),
          const BulkImportComplete(count: 2, failedCount: 1),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'all items fail: count=0, failedCount=total',
        build: () {
          // Every item fails at the pipeline stage
          when(() => mockPipeline.processImage(any()))
              .thenThrow(Exception('Pipeline crash'));
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 3),
          const BulkImportProcessing(current: 2, total: 3),
          const BulkImportProcessing(current: 3, total: 3),
          const BulkImportComplete(count: 0, failedCount: 3),
        ],
        verify: (_) {
          // Pipeline was attempted for all 3, but OCR and save never called
          verify(() => mockPipeline.processImage(any())).called(3);
          verifyNever(() => mockOcr.recognizeText(any()));
          verifyNever(() => mockRepo.saveReceipt(any()));
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'all items fail at File.length: count=0, failedCount=total',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-2', 'c-3'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) {
              final file = MockFile();
              when(() => file.length())
                  .thenThrow(const FileSystemException('File not found'));
              return file;
            },
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 3),
          const BulkImportProcessing(current: 2, total: 3),
          const BulkImportProcessing(current: 3, total: 3),
          const BulkImportComplete(count: 0, failedCount: 3),
        ],
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'imports only selected subset of candidates',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: _testCandidates,
          selectedIds: const {'c-1', 'c-3'}, // c-2 not selected
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        expect: () => [
          const BulkImportProcessing(current: 1, total: 2),
          const BulkImportProcessing(current: 2, total: 2),
          const BulkImportComplete(count: 2, failedCount: 0),
        ],
        verify: (_) {
          verify(() => mockPipeline.processImage(any())).called(2);
          verify(() => mockOcr.recognizeText(any())).called(2);
          verify(() => mockRepo.saveReceipt(any())).called(2);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'passes processed image path to OCR recognizeText',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: [_testCandidates[0]],
          selectedIds: const {'c-1'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        verify: (_) {
          // Verify that OCR receives the processed image path, not the original
          verify(() => mockOcr.recognizeText(_processedImage.localPath))
              .called(1);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'creates receipt with correct fields from OCR result',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: [_testCandidates[0]],
          selectedIds: const {'c-1'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        verify: (_) {
          final captured = verify(() => mockRepo.saveReceipt(captureAny()))
              .captured
              .first as Receipt;
          expect(captured.userId, 'user-1');
          expect(captured.storeName, _testOcrResult.extractedStoreName);
          expect(captured.extractedMerchantName,
              _testOcrResult.extractedStoreName);
          expect(captured.purchaseDate, _testOcrResult.extractedDate);
          expect(captured.extractedDate, _testOcrResult.extractedDate);
          expect(captured.totalAmount, _testOcrResult.extractedTotal);
          expect(captured.extractedTotal, _testOcrResult.extractedTotal);
          expect(captured.currency, _testOcrResult.extractedCurrency);
          expect(captured.ocrRawText, _testOcrResult.rawText);
          expect(
            captured.localImagePaths,
            [_processedImage.localPath],
          );
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'uses EUR as default currency when OCR returns null currency',
        build: () {
          when(() => mockPipeline.processImage(any()))
              .thenAnswer((_) async => _processedImage);
          when(() => mockOcr.recognizeText(any())).thenAnswer(
            (_) async => const OcrResult(
              rawText: 'Some text',
              extractedCurrency: null,
            ),
          );
          when(() => mockRepo.saveReceipt(any())).thenAnswer((_) async {});
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: [_testCandidates[0]],
          selectedIds: const {'c-1'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        verify: (_) {
          final captured = verify(() => mockRepo.saveReceipt(captureAny()))
              .captured
              .first as Receipt;
          expect(captured.currency, 'EUR');
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'sets thumbnailKeys from processed image thumbnailPath',
        build: () {
          stubSuccessfulImportPipeline();
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: [_testCandidates[0]],
          selectedIds: const {'c-1'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        verify: (_) {
          final captured = verify(() => mockRepo.saveReceipt(captureAny()))
              .captured
              .first as Receipt;
          // _processedImage has thumbnailPath = '/processed/thumb1.jpg'
          expect(captured.thumbnailKeys, [_processedImage.thumbnailPath]);
        },
      );

      blocTest<BulkImportCubit, BulkImportState>(
        'sets empty thumbnailKeys when processed image has no thumbnailPath',
        build: () {
          const noThumbImage = ImageData(
            id: 'processed-no-thumb',
            localPath: '/processed/image.jpg',
            thumbnailPath: null,
            sizeBytes: 200000,
            mimeType: 'image/jpeg',
          );
          when(() => mockPipeline.processImage(any()))
              .thenAnswer((_) async => noThumbImage);
          when(() => mockOcr.recognizeText(any()))
              .thenAnswer((_) async => _testOcrResult);
          when(() => mockRepo.saveReceipt(any())).thenAnswer((_) async {});
          return buildCubit();
        },
        seed: () => BulkImportCandidatesReady(
          candidates: [_testCandidates[0]],
          selectedIds: const {'c-1'},
        ),
        act: (cubit) async {
          await IOOverrides.runZoned(
            () => cubit.importSelected('user-1'),
            createFile: (path) => buildMockFile(),
          );
        },
        verify: (_) {
          final captured = verify(() => mockRepo.saveReceipt(captureAny()))
              .captured
              .first as Receipt;
          expect(captured.thumbnailKeys, isEmpty);
        },
      );
    });
  });
}
