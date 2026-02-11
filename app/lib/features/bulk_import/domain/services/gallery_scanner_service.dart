import '../entities/gallery_candidate.dart';

/// Abstract service for scanning the device gallery for receipt-like images.
abstract class GalleryScannerService {
  /// Request photo library permission. Returns true if granted.
  Future<bool> requestPermission();

  /// Check if photo library permission is currently granted.
  Future<bool> hasPermission();

  /// Scan the gallery for images that look like receipts.
  ///
  /// Applies heuristics (aspect ratio, file size) to filter candidates.
  /// Returns results sorted by date (newest first).
  /// [maxMonths] limits how far back to scan (default 12 months).
  Future<List<GalleryCandidate>> scanForReceipts({int maxMonths = 12});
}
