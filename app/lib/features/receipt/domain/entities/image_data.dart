import 'package:equatable/equatable.dart';

class ImageData extends Equatable {
  const ImageData({
    required this.id,
    required this.localPath,
    this.thumbnailPath,
    this.width,
    this.height,
    required this.sizeBytes,
    required this.mimeType,
  });

  final String id;
  final String localPath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final int sizeBytes;
  final String mimeType;

  ImageData copyWith({
    String? id,
    String? localPath,
    String? thumbnailPath,
    int? width,
    int? height,
    int? sizeBytes,
    String? mimeType,
  }) {
    return ImageData(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        localPath,
        thumbnailPath,
        width,
        height,
        sizeBytes,
        mimeType,
      ];
}
