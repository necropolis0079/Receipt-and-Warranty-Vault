import 'package:equatable/equatable.dart';

class GalleryCandidate extends Equatable {
  const GalleryCandidate({
    required this.id,
    required this.localPath,
    this.thumbnailPath,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String localPath;
  final String? thumbnailPath;
  final int width;
  final int height;
  final int sizeBytes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        localPath,
        thumbnailPath,
        width,
        height,
        sizeBytes,
        createdAt,
      ];
}
