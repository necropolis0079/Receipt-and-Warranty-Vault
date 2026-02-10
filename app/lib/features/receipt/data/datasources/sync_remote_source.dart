import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

/// Remote data source for sync operations (pull, push, full reconciliation).
class SyncRemoteSource {
  SyncRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Delta pull -- get items changed since [lastSyncTimestamp].
  Future<SyncPullResponse> pull(String lastSyncTimestamp) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.syncPull,
      data: {'lastSyncTimestamp': lastSyncTimestamp},
    );
    return SyncPullResponse.fromJson(data);
  }

  /// Batch push -- send local changes to server.
  Future<SyncPushResponse> push(List<Map<String, dynamic>> items) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.syncPush,
      data: {'items': items},
    );
    return SyncPushResponse.fromJson(data);
  }

  /// Full reconciliation -- compare client manifest with server state.
  Future<SyncFullResponse> fullReconciliation(
    List<Map<String, dynamic>> manifest,
  ) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      ApiConfig.syncFull,
      data: {'manifest': manifest},
    );
    return SyncFullResponse.fromJson(data);
  }
}

// ---------------------------------------------------------------------------
// Response data holders
// ---------------------------------------------------------------------------

/// Response from delta pull.
class SyncPullResponse {
  SyncPullResponse({
    required this.items,
    required this.serverTimestamp,
  });

  final List<Map<String, dynamic>> items;
  final String serverTimestamp;

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return SyncPullResponse(
      items: items,
      serverTimestamp: json['serverTimestamp'] as String? ?? '',
    );
  }
}

/// Per-item result from a push operation.
class SyncPushResult {
  SyncPushResult({
    required this.receiptId,
    required this.outcome,
    this.mergedItem,
  });

  final String receiptId;
  final String outcome;
  final Map<String, dynamic>? mergedItem;

  factory SyncPushResult.fromJson(Map<String, dynamic> json) {
    return SyncPushResult(
      receiptId: json['receiptId'] as String? ?? '',
      outcome: json['outcome'] as String? ?? '',
      mergedItem: json['mergedItem'] as Map<String, dynamic>?,
    );
  }
}

/// Response from batch push.
class SyncPushResponse {
  SyncPushResponse({required this.results});

  final List<SyncPushResult> results;

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? [])
        .map((r) => SyncPushResult.fromJson(r as Map<String, dynamic>))
        .toList();
    return SyncPushResponse(results: results);
  }
}

/// Response from full reconciliation.
class SyncFullResponse {
  SyncFullResponse({
    required this.toUpdate,
    required this.toDelete,
    required this.serverTimestamp,
  });

  final List<Map<String, dynamic>> toUpdate;
  final List<String> toDelete;
  final String serverTimestamp;

  factory SyncFullResponse.fromJson(Map<String, dynamic> json) {
    return SyncFullResponse(
      toUpdate: (json['toUpdate'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>(),
      toDelete:
          (json['toDelete'] as List<dynamic>? ?? []).cast<String>(),
      serverTimestamp: json['serverTimestamp'] as String? ?? '',
    );
  }
}
