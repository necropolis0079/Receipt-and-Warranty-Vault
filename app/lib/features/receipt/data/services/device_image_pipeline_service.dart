import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/image_data.dart';
import '../../domain/services/image_pipeline_service.dart';

/// Real [ImagePipelineService] wrapping native plugins.
///
/// Only runs on devices — unit tests use [MockImagePipelineService].
class DeviceImagePipelineService implements ImagePipelineService {
  DeviceImagePipelineService();

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  @override
  Future<ImageData?> captureFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (xFile == null) return null;
    return _xFileToImageData(xFile);
  }

  @override
  Future<List<ImageData>> pickFromGallery({int maxImages = 5}) async {
    final xFiles = await _picker.pickMultiImage(
      imageQuality: 95,
      limit: maxImages,
    );
    return Future.wait(xFiles.map(_xFileToImageData));
  }

  @override
  Future<List<ImageData>> pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'heic'],
      allowMultiple: true,
    );
    if (result == null) return [];
    final images = <ImageData>[];
    for (final file in result.files) {
      if (file.path == null) continue;
      images.add(await _fileToImageData(file.path!));
    }
    return images;
  }

  @override
  Future<ImageData?> cropImage(ImageData image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.localPath,
      compressQuality: 90,
    );
    if (croppedFile == null) return null;
    final file = File(croppedFile.path);
    final bytes = await file.length();
    return image.copyWith(
      localPath: croppedFile.path,
      sizeBytes: bytes,
    );
  }

  @override
  Future<ImageData> compressAndStripExif(ImageData image) async {
    final dir = await _getProcessingDir();
    final targetPath = p.join(dir.path, '${image.id}_compressed.jpg');

    // Compress to JPEG 85% (compression also strips EXIF GPS data)
    final result = await FlutterImageCompress.compressWithFile(
      image.localPath,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      final outFile = File(targetPath);
      await outFile.writeAsBytes(result);
      return image.copyWith(
        localPath: targetPath,
        sizeBytes: result.length,
        mimeType: 'image/jpeg',
      );
    }
    return image;
  }

  @override
  Future<ImageData> generateThumbnail(ImageData image) async {
    final dir = await _getProcessingDir();
    final thumbPath = p.join(dir.path, '${image.id}_thumb.jpg');

    final result = await FlutterImageCompress.compressWithFile(
      image.localPath,
      minWidth: 200,
      minHeight: 300,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      final outFile = File(thumbPath);
      await outFile.writeAsBytes(result);
      return image.copyWith(thumbnailPath: thumbPath);
    }
    return image;
  }

  @override
  Future<ImageData> processImage(ImageData image) async {
    final compressed = await compressAndStripExif(image);
    final withThumb = await generateThumbnail(compressed);
    return withThumb;
  }

  @override
  Future<bool> hasCameraPermission() async {
    return Permission.camera.isGranted;
  }

  @override
  Future<bool> hasStoragePermission() async {
    return Permission.photos.isGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestStoragePermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // --- Helpers ---

  Future<ImageData> _xFileToImageData(XFile xFile) async {
    final id = _uuid.v4();
    final file = File(xFile.path);
    final bytes = await file.length();
    return ImageData(
      id: id,
      localPath: xFile.path,
      sizeBytes: bytes,
      mimeType: xFile.mimeType ?? 'image/jpeg',
    );
  }

  Future<ImageData> _fileToImageData(String path) async {
    final id = _uuid.v4();
    final file = File(path);
    final bytes = await file.length();
    final ext = p.extension(path).toLowerCase();
    final mimeType = switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.heic' => 'image/heic',
      _ => 'image/jpeg',
    };
    return ImageData(
      id: id,
      localPath: path,
      sizeBytes: bytes,
      mimeType: mimeType,
    );
  }

  Future<Directory> _getProcessingDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final processingDir = Directory(p.join(appDir.path, 'receipt_images'));
    if (!await processingDir.exists()) {
      await processingDir.create(recursive: true);
    }
    return processingDir;
  }
}
