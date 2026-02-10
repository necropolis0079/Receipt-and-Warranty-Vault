import 'dart:convert';

import '../../features/receipt/domain/entities/receipt.dart';

/// Result of a field-level merge between a local and server receipt.
class MergeResult {
  const MergeResult({
    required this.mergedReceipt,
    required this.changedFields,
    required this.hadConflict,
  });

  /// The merged receipt with all conflict-resolution tiers applied.
  final Receipt mergedReceipt;

  /// Names of fields whose values were changed during the merge.
  final List<String> changedFields;

  /// Whether any field values actually diverged between client and server.
  final bool hadConflict;
}

/// 3-tier field-level conflict resolver.
///
/// Resolution tiers (from CLAUDE.md):
/// - **Tier 1 (Server/LLM wins)**: LLM-extracted fields always take server value.
/// - **Tier 2 (Client/User wins)**: user-authored fields always keep client value.
/// - **Tier 3 (Conditional)**: if field is in [userEditedFields], client wins;
///   otherwise server wins.
///
/// All other metadata fields (version, updatedAt, syncStatus, etc.) follow
/// sensible defaults: server values for sync metadata, client values for
/// local-only fields.
class ConflictResolver {
  /// Tier 1 fields -- server/LLM always wins.
  static const tier1Fields = <String>{
    'extractedMerchantName',
    'extractedDate',
    'extractedTotal',
    'ocrRawText',
    'llmConfidence',
  };

  /// Tier 2 fields -- client/user always wins.
  static const tier2Fields = <String>{
    'userNotes',
    'userTags',
    'isFavorite',
  };

  /// Tier 3 fields -- conditional on [userEditedFields].
  static const tier3Fields = <String>{
    'storeName',
    'category',
    'warrantyMonths',
  };

  /// Merge a local [Receipt] with a server item represented as a JSON map.
  ///
  /// [localReceipt] -- the current version on the device.
  /// [serverItem]   -- the server version (from pull or push-conflict).
  /// [baseReceipt]  -- (optional) the last-synced version, for future
  ///                   three-way merge support. Currently unused.
  ///
  /// Returns a [MergeResult] containing the merged [Receipt], the list of
  /// fields that changed, and whether any conflict was detected.
  MergeResult resolve({
    required Receipt localReceipt,
    required Map<String, dynamic> serverItem,
    Receipt? baseReceipt,
  }) {
    final changedFields = <String>[];
    final userEdited = localReceipt.userEditedFields.toSet();

    // -----------------------------------------------------------------------
    // Helper: read a server field value, falling back to null.
    // -----------------------------------------------------------------------
    T? server<T>(String key) => serverItem[key] as T?;

    // -----------------------------------------------------------------------
    // Tier 1: Server/LLM wins
    // -----------------------------------------------------------------------
    final extractedMerchantName =
        server<String>('extractedMerchantName') ?? localReceipt.extractedMerchantName;
    if (extractedMerchantName != localReceipt.extractedMerchantName) {
      changedFields.add('extractedMerchantName');
    }

    final extractedDate =
        server<String>('extractedDate') ?? localReceipt.extractedDate;
    if (extractedDate != localReceipt.extractedDate) {
      changedFields.add('extractedDate');
    }

    final serverExtractedTotal = server<num>('extractedTotal')?.toDouble();
    final extractedTotal = serverExtractedTotal ?? localReceipt.extractedTotal;
    if (extractedTotal != localReceipt.extractedTotal) {
      changedFields.add('extractedTotal');
    }

    final ocrRawText =
        server<String>('ocrRawText') ?? localReceipt.ocrRawText;
    if (ocrRawText != localReceipt.ocrRawText) {
      changedFields.add('ocrRawText');
    }

    final llmConfidence =
        server<int>('llmConfidence') ?? localReceipt.llmConfidence;
    if (llmConfidence != localReceipt.llmConfidence) {
      changedFields.add('llmConfidence');
    }

    // -----------------------------------------------------------------------
    // Tier 2: Client/User wins -- keep local values
    // -----------------------------------------------------------------------
    final userNotes = localReceipt.userNotes;
    final serverUserNotes = server<String>('userNotes');
    if (serverUserNotes != null && serverUserNotes != userNotes) {
      changedFields.add('userNotes');
    }

    final userTags = localReceipt.userTags;
    final serverUserTags = _decodeStringList(serverItem['userTags']);
    if (_listsDiffer(serverUserTags, userTags)) {
      changedFields.add('userTags');
    }

    final isFavorite = localReceipt.isFavorite;
    final serverIsFavorite = server<bool>('isFavorite');
    if (serverIsFavorite != null && serverIsFavorite != isFavorite) {
      changedFields.add('isFavorite');
    }

    // -----------------------------------------------------------------------
    // Tier 3: Conditional -- client wins if user edited, else server wins
    // -----------------------------------------------------------------------
    final String? storeName;
    if (userEdited.contains('storeName')) {
      storeName = localReceipt.storeName;
      if (server<String>('storeName') != storeName) {
        changedFields.add('storeName');
      }
    } else {
      storeName = server<String>('storeName') ?? localReceipt.storeName;
      if (storeName != localReceipt.storeName) {
        changedFields.add('storeName');
      }
    }

    final String? category;
    if (userEdited.contains('category')) {
      category = localReceipt.category;
      if (server<String>('category') != category) {
        changedFields.add('category');
      }
    } else {
      category = server<String>('category') ?? localReceipt.category;
      if (category != localReceipt.category) {
        changedFields.add('category');
      }
    }

    final int warrantyMonths;
    if (userEdited.contains('warrantyMonths')) {
      warrantyMonths = localReceipt.warrantyMonths;
      if (server<int>('warrantyMonths') != warrantyMonths) {
        changedFields.add('warrantyMonths');
      }
    } else {
      warrantyMonths =
          server<int>('warrantyMonths') ?? localReceipt.warrantyMonths;
      if (warrantyMonths != localReceipt.warrantyMonths) {
        changedFields.add('warrantyMonths');
      }
    }

    // -----------------------------------------------------------------------
    // Metadata: server wins for sync fields, take higher version + increment
    // -----------------------------------------------------------------------
    final serverVersion = server<int>('version') ?? 1;
    final clientVersion = localReceipt.version;
    final mergedVersion =
        (serverVersion > clientVersion ? serverVersion : clientVersion) + 1;

    final updatedAt = server<String>('updatedAt') ??
        DateTime.now().toUtc().toIso8601String();

    final lastSyncedAt = DateTime.now().toUtc().toIso8601String();

    // Merge userEditedFields: union of client and server sets
    final serverEditedFields =
        _decodeStringList(serverItem['userEditedFields']).toSet();
    final mergedEditedFields =
        serverEditedFields.union(userEdited).toList()..sort();

    // Other fields: take server values for shared data, keep local-only fields
    final purchaseDate =
        server<String>('purchaseDate') ?? localReceipt.purchaseDate;
    final serverTotalAmount = server<num>('totalAmount')?.toDouble();
    final totalAmount = serverTotalAmount ?? localReceipt.totalAmount;
    final currency =
        server<String>('currency') ?? localReceipt.currency;
    final warrantyExpiryDate =
        server<String>('warrantyExpiryDate') ?? localReceipt.warrantyExpiryDate;
    final status = _parseStatus(
        server<String>('status') ?? localReceipt.status.name);
    final imageKeys = _decodeStringList(
        serverItem['imageKeys'] ?? localReceipt.imageKeys);
    final thumbnailKeys = _decodeStringList(
        serverItem['thumbnailKeys'] ?? localReceipt.thumbnailKeys);
    final deletedAt =
        server<String>('deletedAt') ?? localReceipt.deletedAt;
    final createdAt =
        server<String>('createdAt') ?? localReceipt.createdAt;

    // -----------------------------------------------------------------------
    // Build merged Receipt
    // -----------------------------------------------------------------------
    final mergedReceipt = Receipt(
      receiptId: localReceipt.receiptId,
      userId: localReceipt.userId,
      storeName: storeName,
      extractedMerchantName: extractedMerchantName,
      purchaseDate: purchaseDate,
      extractedDate: extractedDate,
      totalAmount: totalAmount,
      extractedTotal: extractedTotal,
      currency: currency,
      category: category,
      warrantyMonths: warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate,
      status: status,
      imageKeys: imageKeys,
      thumbnailKeys: thumbnailKeys,
      ocrRawText: ocrRawText,
      llmConfidence: llmConfidence,
      userNotes: userNotes,
      userTags: userTags,
      isFavorite: isFavorite,
      userEditedFields: mergedEditedFields,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: mergedVersion,
      deletedAt: deletedAt,
      syncStatus: SyncStatus.synced,
      lastSyncedAt: lastSyncedAt,
      localImagePaths: localReceipt.localImagePaths, // always keep local paths
    );

    return MergeResult(
      mergedReceipt: mergedReceipt,
      changedFields: changedFields,
      hadConflict: changedFields.isNotEmpty,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Parse a [ReceiptStatus] from a string name.
  static ReceiptStatus _parseStatus(String value) {
    return ReceiptStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReceiptStatus.active,
    );
  }

  /// Decode a value that may be a JSON-encoded string list, a raw List, or null.
  static List<String> _decodeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {
        // Not valid JSON -- return empty
      }
    }
    return [];
  }

  /// Compare two string lists for inequality (order-insensitive).
  static bool _listsDiffer(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    final setA = a.toSet();
    final setB = b.toSet();
    return !setA.containsAll(setB) || !setB.containsAll(setA);
  }
}
