import '../entities/image_data.dart';

/// Abstract service for image capture, processing, and management.
abstract class ImagePipelineService {
  /// Capture a photo from the device camera.
  Future<ImageData?> captureFromCamera();

  /// Pick one or more images from the device gallery.
  Future<List<ImageData>> pickFromGallery({int maxImages = 5});

  /// Pick files (images or PDFs) from the file system.
  Future<List<ImageData>> pickFromFiles();

  /// Crop and rotate an image interactively.
  Future<ImageData?> cropImage(ImageData image);

  /// Compress the image to JPEG 85% and strip GPS EXIF data.
  Future<ImageData> compressAndStripExif(ImageData image);

  /// Generate a 200x300 thumbnail at JPEG 70%.
  Future<ImageData> generateThumbnail(ImageData image);

  /// Full pipeline: compress + strip EXIF + generate thumbnail.
  Future<ImageData> processImage(ImageData image);

  /// Check if camera permission is granted.
  Future<bool> hasCameraPermission();

  /// Check if storage/gallery permission is granted.
  Future<bool> hasStoragePermission();

  /// Request camera permission. Returns true if granted.
  Future<bool> requestCameraPermission();

  /// Request storage/gallery permission. Returns true if granted.
  Future<bool> requestStoragePermission();
}
