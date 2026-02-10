import 'dart:developer' as dev;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/receipt/data/datasources/image_remote_source.dart';
import '../../features/receipt/data/models/receipt_mapper.dart';
import '../database/daos/receipts_dao.dart';
import 'sync_config.dart';

/// Service for syncing receipt images to/from S3 via presigned URLs.
///
/// Handles two directions:
/// - **Upload**: local images that have no corresponding S3 key yet.
/// - **Download**: S3 keys that have no local cached file yet.
///
/// Uses [ImageRemoteSource] to obtain presigned URLs and perform the actual
/// HTTP transfers. Updates the local Drift DB with the resulting S3 keys or
/// local cache paths.
class ImageSyncService {
  ImageSyncService({
    required ImageRemoteSource imageRemoteSource,
    required ReceiptsDao receiptsDao,
  })  : _imageRemoteSource = imageRemoteSource,
        _receiptsDao = receiptsDao;

  final ImageRemoteSource _imageRemoteSource;
  final ReceiptsDao _receiptsDao;

  // =========================================================================
  // Upload
  // =========================================================================

  /// Upload all local images that are not yet backed up to S3.
  ///
  /// Iterates over receipts that have [localImagePaths] but whose [imageKeys]
  /// list is shorter (i.e., some images have not been uploaded). For each
  /// un-uploaded image:
  /// 1. Read bytes from the local file.
  /// 2. Request a presigned upload URL from the API.
  /// 3. PUT the bytes to S3 via the presigned URL.
  /// 4. Append the returned S3 key to the receipt's [imageKeys].
  ///
  /// Returns the total number of images successfully uploaded.
  Future<int> uploadPendingImages(String userId) async {
    int totalUploaded = 0;

    try {
      final pendingReceipts = await _receiptsDao.getPendingSync(userId);

      for (final entry in pendingReceipts) {
        final receipt = ReceiptMapper.toReceipt(entry);

        // Skip receipts that have no local images to upload
        if (receipt.localImagePaths.isEmpty) continue;

        // Determine which images still need uploading.
        // Convention: imageKeys[i] corresponds to localImagePaths[i].
        // If imageKeys is shorter, the trailing localImagePaths need upload.
        final alreadyUploaded = receipt.imageKeys.length;
        if (alreadyUploaded >= receipt.localImagePaths.length) continue;

        final newKeys = List<String>.from(receipt.imageKeys);

        for (int i = alreadyUploaded; i < receipt.localImagePaths.length; i++) {
          final localPath = receipt.localImagePaths[i];
          try {
            final file = File(localPath);
            if (!await file.exists()) {
              dev.log(
                'Image file not found: $localPath (receipt ${receipt.receiptId})',
                name: 'ImageSync',
              );
              continue;
            }

            final fileSize = await file.length();
            if (fileSize > SyncConfig.imageUploadMaxSize) {
              dev.log(
                'Image too large (${fileSize}B > ${SyncConfig.imageUploadMaxSize}B): '
                '$localPath',
                name: 'ImageSync',
              );
              continue;
            }

            final imageBytes = await file.readAsBytes();

            // Get presigned upload URL
            final urlResponse = await _imageRemoteSource.getUploadUrl(
              receipt.receiptId,
              i,
            );

            // Upload to S3
            await _imageRemoteSource.uploadImage(
              urlResponse.url,
              imageBytes,
            );

            newKeys.add(urlResponse.key);
            totalUploaded++;

            dev.log(
              'Uploaded image $i for receipt ${receipt.receiptId} -> ${urlResponse.key}',
              name: 'ImageSync',
            );
          } catch (e) {
            dev.log(
              'Failed to upload image $i for receipt ${receipt.receiptId}: $e',
              name: 'ImageSync',
            );
            // Continue with next image — don't fail the whole batch
          }
        }

        // If we uploaded anything, update the receipt's imageKeys
        if (newKeys.length > receipt.imageKeys.length) {
          final updated = receipt.copyWith(imageKeys: newKeys);
          await _receiptsDao.updateReceipt(ReceiptMapper.toCompanion(updated));
        }
      }
    } catch (e, st) {
      dev.log(
        'uploadPendingImages failed: $e',
        name: 'ImageSync',
        error: e,
        stackTrace: st,
      );
    }

    dev.log('Upload complete: $totalUploaded images uploaded', name: 'ImageSync');
    return totalUploaded;
  }

  // =========================================================================
  // Download
  // =========================================================================

  /// Download images from S3 for receipts that have [imageKeys] but are missing
  /// local cached copies.
  ///
  /// For each receipt where `imageKeys.length > localImagePaths.length`:
  /// 1. Request a presigned download URL for each missing key.
  /// 2. GET the bytes from S3.
  /// 3. Save to the app's local cache directory.
  /// 4. Update the receipt's [localImagePaths].
  ///
  /// Returns the total number of images successfully downloaded.
  Future<int> downloadMissingImages(String userId) async {
    int totalDownloaded = 0;

    try {
      // Get all active receipts to check for missing local images.
      // watchUserReceipts returns active receipts as a stream — take first.
      final entries = await _receiptsDao.watchUserReceipts(userId).first;

      for (final entry in entries) {
        final receipt = ReceiptMapper.toReceipt(entry);

        // Skip if no server images or all already cached locally
        if (receipt.imageKeys.isEmpty) continue;
        if (receipt.localImagePaths.length >= receipt.imageKeys.length) continue;

        final newPaths = List<String>.from(receipt.localImagePaths);
        final startIndex = newPaths.length;

        for (int i = startIndex; i < receipt.imageKeys.length; i++) {
          final imageKey = receipt.imageKeys[i];
          try {
            final localPath = await _downloadAndCacheImage(
              receiptId: receipt.receiptId,
              imageKey: imageKey,
            );

            if (localPath != null) {
              newPaths.add(localPath);
              totalDownloaded++;
            }
          } catch (e) {
            dev.log(
              'Failed to download image $imageKey for receipt ${receipt.receiptId}: $e',
              name: 'ImageSync',
            );
          }
        }

        // Update local paths if we downloaded anything
        if (newPaths.length > receipt.localImagePaths.length) {
          final updated = receipt.copyWith(localImagePaths: newPaths);
          await _receiptsDao.updateReceipt(ReceiptMapper.toCompanion(updated));
        }
      }
    } catch (e, st) {
      dev.log(
        'downloadMissingImages failed: $e',
        name: 'ImageSync',
        error: e,
        stackTrace: st,
      );
    }

    dev.log(
      'Download complete: $totalDownloaded images downloaded',
      name: 'ImageSync',
    );
    return totalDownloaded;
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  /// Download a single image from S3 and save it to the local cache directory.
  ///
  /// Returns the local file path on success, or null on failure.
  Future<String?> _downloadAndCacheImage({
    required String receiptId,
    required String imageKey,
  }) async {
    try {
      // Get presigned download URL
      final urlResponse = await _imageRemoteSource.getDownloadUrl(
        receiptId,
        imageKey,
      );

      // Download from S3
      final bytes = await _imageRemoteSource.downloadImage(urlResponse.url);

      // Build local cache path
      final cacheDir = await getApplicationDocumentsDirectory();
      final fileName = imageKey.split('/').last;
      final localPath = p.join(cacheDir.path, 'images', receiptId, fileName);

      // Ensure directory exists
      final dir = Directory(p.dirname(localPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Write to disk
      await File(localPath).writeAsBytes(bytes);

      dev.log('Downloaded $imageKey -> $localPath', name: 'ImageSync');
      return localPath;
    } catch (e) {
      dev.log('Failed to download/cache $imageKey: $e', name: 'ImageSync');
      return null;
    }
  }
}
