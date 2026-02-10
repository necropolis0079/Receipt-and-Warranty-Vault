import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

/// Remote data source for categories, user profile, settings, and account operations.
class SettingsRemoteSource {
  SettingsRemoteSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  /// Get user categories and their version.
  Future<CategoriesResponse> getCategories() async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      ApiConfig.categories,
    );
    return CategoriesResponse.fromJson(data);
  }

  /// Update categories. Returns the updated categories and version.
  Future<CategoriesResponse> updateCategories(
    List<Map<String, dynamic>> categories,
    int version,
  ) async {
    final data = await _apiClient.put<Map<String, dynamic>>(
      ApiConfig.categories,
      data: {'categories': categories, 'version': version},
    );
    return CategoriesResponse.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  /// Get the current user profile.
  Future<Map<String, dynamic>> getUserProfile() async {
    return await _apiClient.get<Map<String, dynamic>>(ApiConfig.userProfile);
  }

  /// Update the user profile. Returns the updated profile.
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> data,
  ) async {
    return await _apiClient.put<Map<String, dynamic>>(
      ApiConfig.userProfile,
      data: data,
    );
  }

  // ---------------------------------------------------------------------------
  // User Settings
  // ---------------------------------------------------------------------------

  /// Get the current user settings.
  Future<Map<String, dynamic>> getUserSettings() async {
    return await _apiClient.get<Map<String, dynamic>>(ApiConfig.userSettings);
  }

  /// Update user settings. Returns the updated settings.
  Future<Map<String, dynamic>> updateUserSettings(
    Map<String, dynamic> data,
  ) async {
    return await _apiClient.put<Map<String, dynamic>>(
      ApiConfig.userSettings,
      data: data,
    );
  }

  // ---------------------------------------------------------------------------
  // Account Operations
  // ---------------------------------------------------------------------------

  /// Delete the user account (triggers cascade: Cognito, DynamoDB, S3).
  Future<void> deleteAccount() async {
    await _apiClient.delete<Map<String, dynamic>>(ApiConfig.userDelete);
  }

  /// Request a data export. Returns download URL, expiry, and receipt count.
  Future<ExportResponse> requestExport() async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.userExport,
    );
    return ExportResponse.fromJson(data);
  }
}

// ---------------------------------------------------------------------------
// Response data holders
// ---------------------------------------------------------------------------

/// Categories list with version for optimistic concurrency.
class CategoriesResponse {
  CategoriesResponse({required this.categories, required this.version});

  final List<Map<String, dynamic>> categories;
  final int version;

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>? ?? [])
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return CategoriesResponse(
      categories: cats,
      version: json['version'] as int? ?? 1,
    );
  }
}

/// Response from a data export request.
class ExportResponse {
  ExportResponse({
    required this.downloadUrl,
    required this.expiresAt,
    required this.receiptCount,
  });

  final String downloadUrl;
  final String expiresAt;
  final int receiptCount;

  factory ExportResponse.fromJson(Map<String, dynamic> json) {
    return ExportResponse(
      downloadUrl: json['downloadUrl'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      receiptCount: json['receiptCount'] as int? ?? 0,
    );
  }
}
