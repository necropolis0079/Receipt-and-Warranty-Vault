import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../../domain/entities/gallery_candidate.dart';
import '../../domain/services/gallery_scanner_service.dart';

/// Implementation of [GalleryScannerService] using [photo_manager].
///
/// Scans the device gallery for recent photos that match receipt-like
/// heuristics: portrait aspect ratio (0.4–0.85) and file size 50KB–20MB.
class DeviceGalleryScannerService implements GalleryScannerService {
  @override
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  @override
  Future<bool> hasPermission() async {
    final result = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    return result.isAuth;
  }

  @override
  Future<List<GalleryCandidate>> scanForReceipts({int maxMonths = 12}) async {
    final cutoff = DateTime.now().subtract(Duration(days: maxMonths * 30));

    // Fetch all image-type albums
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(
            minWidth: 200,
            minHeight: 200,
          ),
        ),
        createTimeCond: DateTimeCond(
          min: cutoff,
          max: DateTime.now(),
        ),
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
    );

    final candidates = <GalleryCandidate>[];

    for (final album in albums) {
      final assetCount = await album.assetCountAsync;
      if (assetCount == 0) continue;

      // Process in pages of 100
      int page = 0;
      const pageSize = 100;

      while (true) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        if (assets.isEmpty) break;

        for (final asset in assets) {
          // Skip non-image assets
          if (asset.type != AssetType.image) continue;

          // Heuristic: receipt-like aspect ratio (portrait, tall & narrow)
          final width = asset.width;
          final height = asset.height;
          if (width <= 0 || height <= 0) continue;

          final aspectRatio = width / height;
          if (aspectRatio < 0.4 || aspectRatio > 0.85) continue;

          // Get the file to check size
          final file = await asset.file;
          if (file == null) continue;

          final sizeBytes = await file.length();

          // Heuristic: file size between 50KB and 20MB
          if (sizeBytes < 50 * 1024 || sizeBytes > 20 * 1024 * 1024) continue;

          // Generate thumbnail path
          final thumbData = await asset.thumbnailDataWithSize(
            const ThumbnailSize(200, 300),
            quality: 70,
          );

          String? thumbnailPath;
          if (thumbData != null) {
            final thumbFile = File(
              '${file.parent.path}/.thumb_${asset.id.replaceAll('/', '_')}.jpg',
            );
            await thumbFile.writeAsBytes(thumbData);
            thumbnailPath = thumbFile.path;
          }

          candidates.add(GalleryCandidate(
            id: asset.id,
            localPath: file.path,
            thumbnailPath: thumbnailPath,
            width: width,
            height: height,
            sizeBytes: sizeBytes,
            createdAt: asset.createDateTime,
          ));
        }

        if (assets.length < pageSize) break;
        page++;
      }
    }

    // Sort by date (newest first) — already sorted by filter, but ensure
    candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return candidates;
  }
}
