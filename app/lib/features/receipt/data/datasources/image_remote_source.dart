import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

/// Remote data source for image upload/download via presigned URLs.
class ImageRemoteSource {
  ImageRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get a presigned URL for uploading an image.
  Future<PresignedUrlResponse> getUploadUrl(
    String receiptId,
    int imageIndex,
  ) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.presignedUrl,
      data: {
        'receiptId': receiptId,
        'imageIndex': imageIndex,
        'operation': 'upload',
      },
    );
    return PresignedUrlResponse.fromJson(data);
  }

  /// Get a presigned URL for downloading an image.
  Future<PresignedUrlResponse> getDownloadUrl(
    String receiptId,
    String imageKey,
  ) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.presignedUrl,
      data: {
        'receiptId': receiptId,
        'imageKey': imageKey,
        'operation': 'download',
      },
    );
    return PresignedUrlResponse.fromJson(data);
  }

  /// Upload image bytes directly to S3 via presigned URL.
  /// Uses a raw Dio instance to bypass the ApiClient's base URL and interceptors.
  Future<void> uploadImage(String presignedUrl, Uint8List imageData) async {
    await Dio().put(
      presignedUrl,
      data: Stream.fromIterable([imageData]),
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': imageData.length,
        },
      ),
    );
  }

  /// Download image bytes from S3 via presigned URL.
  /// Uses a raw Dio instance to bypass the ApiClient's base URL and interceptors.
  Future<Uint8List> downloadImage(String presignedUrl) async {
    final response = await Dio().get<List<int>>(
      presignedUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }
}

/// Presigned URL response from the API.
class PresignedUrlResponse {
  PresignedUrlResponse({required this.url, required this.key});

  final String url;
  final String key;

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      url: json['url'] as String,
      key: json['key'] as String,
    );
  }
}
