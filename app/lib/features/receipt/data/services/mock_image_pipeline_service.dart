import 'package:uuid/uuid.dart';

import '../../domain/entities/image_data.dart';
import '../../domain/services/image_pipeline_service.dart';

/// Mock implementation of [ImagePipelineService] for dev/tests.
///
/// Returns fake [ImageData] objects with simulated delays. No real file I/O.
class MockImagePipelineService implements ImagePipelineService {
  MockImagePipelineService({
    this.shouldFail = false,
    this.simulatedDelayMs = 100,
  });

  final bool shouldFail;
  final int simulatedDelayMs;
  final _uuid = const Uuid();

  Future<void> _simulateDelay() async {
    await Future.delayed(Duration(milliseconds: simulatedDelayMs));
  }

  ImageData _fakeImageData({String? id, String? localPath}) {
    final imageId = id ?? _uuid.v4();
    return ImageData(
      id: imageId,
      localPath: localPath ?? '/mock/images/$imageId.jpg',
      thumbnailPath: '/mock/thumbnails/${imageId}_thumb.jpg',
      width: 1200,
      height: 1600,
      sizeBytes: 150000,
      mimeType: 'image/jpeg',
    );
  }

  @override
  Future<ImageData?> captureFromCamera() async {
    await _simulateDelay();
    if (shouldFail) return null;
    return _fakeImageData();
  }

  @override
  Future<List<ImageData>> pickFromGallery({int maxImages = 5}) async {
    await _simulateDelay();
    if (shouldFail) return [];
    return List.generate(2, (_) => _fakeImageData());
  }

  @override
  Future<List<ImageData>> pickFromFiles() async {
    await _simulateDelay();
    if (shouldFail) return [];
    return [_fakeImageData()];
  }

  @override
  Future<ImageData?> cropImage(ImageData image) async {
    await _simulateDelay();
    if (shouldFail) return null;
    return image.copyWith(width: 800, height: 1000);
  }

  @override
  Future<ImageData> compressAndStripExif(ImageData image) async {
    await _simulateDelay();
    return image.copyWith(sizeBytes: (image.sizeBytes * 0.7).round());
  }

  @override
  Future<ImageData> generateThumbnail(ImageData image) async {
    await _simulateDelay();
    return image.copyWith(
      thumbnailPath: '/mock/thumbnails/${image.id}_thumb.jpg',
      width: 200,
      height: 300,
      sizeBytes: 15000,
    );
  }

  @override
  Future<ImageData> processImage(ImageData image) async {
    final compressed = await compressAndStripExif(image);
    final withThumb = await generateThumbnail(compressed);
    return withThumb;
  }

  @override
  Future<bool> hasCameraPermission() async => !shouldFail;

  @override
  Future<bool> hasStoragePermission() async => !shouldFail;

  @override
  Future<bool> requestCameraPermission() async => !shouldFail;

  @override
  Future<bool> requestStoragePermission() async => !shouldFail;
}
