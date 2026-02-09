import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/data/services/mock_image_pipeline_service.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';
import 'package:warrantyvault/features/receipt/domain/services/image_pipeline_service.dart';

void main() {
  late MockImagePipelineService service;

  setUp(() {
    service = MockImagePipelineService(simulatedDelayMs: 0);
  });

  group('MockImagePipelineService', () {
    test('implements ImagePipelineService', () {
      expect(service, isA<ImagePipelineService>());
    });

    group('captureFromCamera', () {
      test('returns ImageData with valid fields', () async {
        final result = await service.captureFromCamera();

        expect(result, isNotNull);
        expect(result!, isA<ImageData>());
        expect(result.id, isNotEmpty);
        expect(result.localPath, contains('/mock/images/'));
        expect(result.localPath, endsWith('.jpg'));
        expect(result.thumbnailPath, isNotNull);
        expect(result.thumbnailPath!, contains('/mock/thumbnails/'));
        expect(result.thumbnailPath!, endsWith('_thumb.jpg'));
        expect(result.width, 1200);
        expect(result.height, 1600);
        expect(result.sizeBytes, 150000);
        expect(result.mimeType, 'image/jpeg');
      });

      test('returns null when shouldFail is true', () async {
        final failService = MockImagePipelineService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.captureFromCamera();

        expect(result, isNull);
      });
    });

    group('pickFromGallery', () {
      test('returns list of ImageData', () async {
        final result = await service.pickFromGallery();

        expect(result, isA<List<ImageData>>());
        expect(result.length, 2);
        for (final image in result) {
          expect(image.id, isNotEmpty);
          expect(image.localPath, isNotEmpty);
          expect(image.mimeType, 'image/jpeg');
          expect(image.sizeBytes, greaterThan(0));
        }
      });

      test('returns empty list when shouldFail is true', () async {
        final failService = MockImagePipelineService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.pickFromGallery();

        expect(result, isEmpty);
      });

      test('returns unique image IDs', () async {
        final result = await service.pickFromGallery();

        final ids = result.map((img) => img.id).toSet();
        expect(ids.length, result.length);
      });
    });

    group('pickFromFiles', () {
      test('returns list of ImageData', () async {
        final result = await service.pickFromFiles();

        expect(result, isA<List<ImageData>>());
        expect(result.length, 1);
        expect(result.first.id, isNotEmpty);
        expect(result.first.localPath, isNotEmpty);
        expect(result.first.mimeType, 'image/jpeg');
      });

      test('returns empty list when shouldFail is true', () async {
        final failService = MockImagePipelineService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.pickFromFiles();

        expect(result, isEmpty);
      });
    });

    group('cropImage', () {
      test('returns modified ImageData with cropped dimensions', () async {
        const input = ImageData(
          id: 'test-id',
          localPath: '/test/image.jpg',
          width: 1200,
          height: 1600,
          sizeBytes: 150000,
          mimeType: 'image/jpeg',
        );

        final result = await service.cropImage(input);

        expect(result, isNotNull);
        expect(result!.id, 'test-id');
        expect(result.localPath, '/test/image.jpg');
        expect(result.width, 800);
        expect(result.height, 1000);
        expect(result.sizeBytes, 150000);
        expect(result.mimeType, 'image/jpeg');
      });

      test('returns null when shouldFail is true', () async {
        final failService = MockImagePipelineService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );
        const input = ImageData(
          id: 'test-id',
          localPath: '/test/image.jpg',
          sizeBytes: 150000,
          mimeType: 'image/jpeg',
        );

        final result = await failService.cropImage(input);

        expect(result, isNull);
      });
    });

    group('compressAndStripExif', () {
      test('returns ImageData with reduced size and preserves other fields',
          () async {
        const input = ImageData(
          id: 'test-id',
          localPath: '/test/image.jpg',
          width: 1200,
          height: 1600,
          sizeBytes: 100000,
          mimeType: 'image/jpeg',
        );

        final result = await service.compressAndStripExif(input);

        expect(result.id, 'test-id');
        expect(result.localPath, '/test/image.jpg');
        expect(result.sizeBytes, 70000); // 100000 * 0.7
        expect(result.mimeType, 'image/jpeg');
        expect(result.width, 1200);
        expect(result.height, 1600);
      });
    });

    group('generateThumbnail', () {
      test('returns ImageData with thumbnailPath set and thumbnail dimensions',
          () async {
        const input = ImageData(
          id: 'test-id',
          localPath: '/test/image.jpg',
          width: 1200,
          height: 1600,
          sizeBytes: 150000,
          mimeType: 'image/jpeg',
        );

        final result = await service.generateThumbnail(input);

        expect(result.id, 'test-id');
        expect(result.thumbnailPath, '/mock/thumbnails/test-id_thumb.jpg');
        expect(result.width, 200);
        expect(result.height, 300);
        expect(result.sizeBytes, 15000);
      });
    });

    group('processImage', () {
      test('chains compress and thumbnail operations', () async {
        const input = ImageData(
          id: 'process-id',
          localPath: '/test/image.jpg',
          width: 1200,
          height: 1600,
          sizeBytes: 200000,
          mimeType: 'image/jpeg',
        );

        final result = await service.processImage(input);

        // After compress: sizeBytes = 200000 * 0.7 = 140000
        // After thumbnail: sizeBytes = 15000, width = 200, height = 300
        expect(result.id, 'process-id');
        expect(result.thumbnailPath, '/mock/thumbnails/process-id_thumb.jpg');
        expect(result.width, 200);
        expect(result.height, 300);
        expect(result.sizeBytes, 15000);
      });
    });

    group('permissions', () {
      test('hasCameraPermission returns true when shouldFail is false',
          () async {
        final result = await service.hasCameraPermission();

        expect(result, isTrue);
      });

      test('hasCameraPermission returns false when shouldFail is true',
          () async {
        final failService = MockImagePipelineService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.hasCameraPermission();

        expect(result, isFalse);
      });

      test('requestCameraPermission returns true when shouldFail is false',
          () async {
        final result = await service.requestCameraPermission();

        expect(result, isTrue);
      });

      test('requestCameraPermission returns false when shouldFail is true',
          () async {
        final failService = MockImagePipelineService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.requestCameraPermission();

        expect(result, isFalse);
      });

      test('hasStoragePermission returns true when shouldFail is false',
          () async {
        final result = await service.hasStoragePermission();

        expect(result, isTrue);
      });

      test('requestStoragePermission returns true when shouldFail is false',
          () async {
        final result = await service.requestStoragePermission();

        expect(result, isTrue);
      });
    });
  });
}
