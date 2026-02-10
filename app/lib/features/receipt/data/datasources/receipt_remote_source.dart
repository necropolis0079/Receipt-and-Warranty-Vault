import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/receipt.dart';

/// Remote data source for receipt CRUD operations and warranty queries via API.
class ReceiptRemoteSource {
  ReceiptRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// List receipts with optional cursor-based pagination.
  Future<ReceiptListResponse> listReceipts({String? cursor}) async {
    final params = <String, dynamic>{};
    if (cursor != null) params['cursor'] = cursor;

    final data = await _apiClient.get<Map<String, dynamic>>(
      ApiConfig.receipts,
      queryParameters: params,
    );

    final items = (data['receipts'] as List<dynamic>? ?? [])
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();

    return ReceiptListResponse(
      receipts: items,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  /// Get a single receipt by ID.
  Future<Receipt> getReceipt(String id) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      ApiConfig.receipt.replaceFirst('{id}', id),
    );
    return _fromJson(data);
  }

  /// Create a new receipt. Returns the server-enriched receipt.
  Future<Receipt> createReceipt(Receipt receipt) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.receipts,
      data: _toJson(receipt),
    );
    return _fromJson(data);
  }

  /// Update an existing receipt. Returns the updated receipt.
  Future<Receipt> updateReceipt(String id, Receipt receipt) async {
    final data = await _apiClient.put<Map<String, dynamic>>(
      ApiConfig.receipt.replaceFirst('{id}', id),
      data: _toJson(receipt),
    );
    return _fromJson(data);
  }

  /// Soft-delete a receipt.
  Future<void> deleteReceipt(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      ApiConfig.receipt.replaceFirst('{id}', id),
    );
  }

  /// Restore a soft-deleted receipt.
  Future<void> restoreReceipt(String id) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.receiptRestore.replaceFirst('{id}', id),
    );
  }

  /// Trigger LLM OCR refinement for a receipt.
  Future<void> triggerRefinement(String id) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.refinement.replaceFirst('{id}', id),
    );
  }

  /// Get warranties expiring within the default window.
  Future<List<Receipt>> getExpiringWarranties() async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      ApiConfig.warranties,
    );
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // JSON helpers
  // ---------------------------------------------------------------------------

  /// Parse a JSON map into a [Receipt], handling null fields gracefully.
  static Receipt _fromJson(Map<String, dynamic> json) {
    return Receipt(
      receiptId: json['receiptId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      storeName: json['storeName'] as String?,
      extractedMerchantName: json['extractedMerchantName'] as String?,
      purchaseDate: json['purchaseDate'] as String?,
      extractedDate: json['extractedDate'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      extractedTotal: (json['extractedTotal'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      category: json['category'] as String?,
      warrantyMonths: json['warrantyMonths'] as int? ?? 0,
      warrantyExpiryDate: json['warrantyExpiryDate'] as String?,
      status: _parseReceiptStatus(json['status'] as String?),
      imageKeys: _parseStringList(json['imageKeys']),
      thumbnailKeys: _parseStringList(json['thumbnailKeys']),
      ocrRawText: json['ocrRawText'] as String?,
      llmConfidence: json['llmConfidence'] as int? ?? 0,
      userNotes: json['userNotes'] as String?,
      userTags: _parseStringList(json['userTags']),
      isFavorite: json['isFavorite'] as bool? ?? false,
      userEditedFields: _parseStringList(json['userEditedFields']),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      deletedAt: json['deletedAt'] as String?,
      syncStatus: _parseSyncStatus(json['syncStatus'] as String?),
      lastSyncedAt: json['lastSyncedAt'] as String?,
      localImagePaths: _parseStringList(json['localImagePaths']),
    );
  }

  /// Convert a [Receipt] to a JSON map for API requests.
  static Map<String, dynamic> _toJson(Receipt r) {
    return {
      'receiptId': r.receiptId,
      'userId': r.userId,
      'storeName': r.storeName,
      'extractedMerchantName': r.extractedMerchantName,
      'purchaseDate': r.purchaseDate,
      'extractedDate': r.extractedDate,
      'totalAmount': r.totalAmount,
      'extractedTotal': r.extractedTotal,
      'currency': r.currency,
      'category': r.category,
      'warrantyMonths': r.warrantyMonths,
      'warrantyExpiryDate': r.warrantyExpiryDate,
      'status': r.status.name,
      'imageKeys': r.imageKeys,
      'thumbnailKeys': r.thumbnailKeys,
      'ocrRawText': r.ocrRawText,
      'llmConfidence': r.llmConfidence,
      'userNotes': r.userNotes,
      'userTags': r.userTags,
      'isFavorite': r.isFavorite,
      'userEditedFields': r.userEditedFields,
      'createdAt': r.createdAt,
      'updatedAt': r.updatedAt,
      'version': r.version,
      'deletedAt': r.deletedAt,
      'syncStatus': r.syncStatus.name,
      'lastSyncedAt': r.lastSyncedAt,
    };
  }

  static ReceiptStatus _parseReceiptStatus(String? value) {
    if (value == null) return ReceiptStatus.active;
    return ReceiptStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReceiptStatus.active,
    );
  }

  static SyncStatus _parseSyncStatus(String? value) {
    if (value == null) return SyncStatus.pending;
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.cast<String>();
    return const [];
  }
}

/// Paginated response for receipt listing.
class ReceiptListResponse {
  ReceiptListResponse({required this.receipts, this.nextCursor});

  final List<Receipt> receipts;
  final String? nextCursor;
}
