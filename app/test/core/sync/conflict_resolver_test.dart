import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/sync/conflict_resolver.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';

void main() {
  late ConflictResolver resolver;

  setUp(() {
    resolver = ConflictResolver();
  });

  // ---------------------------------------------------------------------------
  // Helper: build a Receipt with sensible defaults for testing.
  // ---------------------------------------------------------------------------
  Receipt buildReceipt({
    String receiptId = 'r-test-001',
    String userId = 'u-test-001',
    String? storeName = 'Local Store',
    String? extractedMerchantName = 'Local Merchant',
    String? purchaseDate = '2026-01-15',
    String? extractedDate = '2026-01-15',
    double? totalAmount = 99.99,
    double? extractedTotal = 99.99,
    String currency = 'EUR',
    String? category = 'Electronics',
    int warrantyMonths = 12,
    String? warrantyExpiryDate = '2027-01-15',
    ReceiptStatus status = ReceiptStatus.active,
    List<String> imageKeys = const ['img-001.jpg'],
    List<String> thumbnailKeys = const ['thumb-001.jpg'],
    String? ocrRawText = 'local ocr text',
    int llmConfidence = 85,
    String? userNotes = 'my local note',
    List<String> userTags = const ['tag-local'],
    bool isFavorite = false,
    List<String> userEditedFields = const [],
    String createdAt = '2026-01-15T10:00:00.000Z',
    String updatedAt = '2026-02-01T12:00:00.000Z',
    int version = 3,
    String? deletedAt,
    SyncStatus syncStatus = SyncStatus.pending,
    String? lastSyncedAt = '2026-02-01T11:00:00.000Z',
    List<String> localImagePaths = const ['/local/path/img-001.jpg'],
  }) {
    return Receipt(
      receiptId: receiptId,
      userId: userId,
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
      userEditedFields: userEditedFields,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      deletedAt: deletedAt,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      localImagePaths: localImagePaths,
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: build a server item map that mirrors a Receipt exactly, so that
  // when used with buildReceipt() defaults, there is zero divergence.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> buildServerItem({
    String? storeName = 'Local Store',
    String? extractedMerchantName = 'Local Merchant',
    String? purchaseDate = '2026-01-15',
    String? extractedDate = '2026-01-15',
    double? totalAmount = 99.99,
    double? extractedTotal = 99.99,
    String currency = 'EUR',
    String? category = 'Electronics',
    int warrantyMonths = 12,
    String? warrantyExpiryDate = '2027-01-15',
    String status = 'active',
    List<String> imageKeys = const ['img-001.jpg'],
    List<String> thumbnailKeys = const ['thumb-001.jpg'],
    String? ocrRawText = 'local ocr text',
    int llmConfidence = 85,
    String? userNotes = 'my local note',
    List<String> userTags = const ['tag-local'],
    bool isFavorite = false,
    List<String> userEditedFields = const [],
    String createdAt = '2026-01-15T10:00:00.000Z',
    String updatedAt = '2026-02-01T12:00:00.000Z',
    int version = 3,
    String? deletedAt,
  }) {
    return <String, dynamic>{
      'storeName': storeName,
      'extractedMerchantName': extractedMerchantName,
      'purchaseDate': purchaseDate,
      'extractedDate': extractedDate,
      'totalAmount': totalAmount,
      'extractedTotal': extractedTotal,
      'currency': currency,
      'category': category,
      'warrantyMonths': warrantyMonths,
      'warrantyExpiryDate': warrantyExpiryDate,
      'status': status,
      'imageKeys': imageKeys,
      'thumbnailKeys': thumbnailKeys,
      'ocrRawText': ocrRawText,
      'llmConfidence': llmConfidence,
      'userNotes': userNotes,
      'userTags': userTags,
      'isFavorite': isFavorite,
      'userEditedFields': userEditedFields,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': version,
      if (deletedAt != null) 'deletedAt': deletedAt,
    };
  }

  // ===========================================================================
  // 1. No conflict: identical local and server
  // ===========================================================================
  group('No conflict (identical local and server)', () {
    test('hadConflict is false and changedFields is empty', () {
      final local = buildReceipt();
      final server = buildServerItem();

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.hadConflict, isFalse);
      expect(result.changedFields, isEmpty);
    });

    test('merged receipt preserves all original field values', () {
      final local = buildReceipt();
      final server = buildServerItem();

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      final m = result.mergedReceipt;
      expect(m.receiptId, local.receiptId);
      expect(m.userId, local.userId);
      expect(m.storeName, local.storeName);
      expect(m.extractedMerchantName, local.extractedMerchantName);
      expect(m.extractedDate, local.extractedDate);
      expect(m.extractedTotal, local.extractedTotal);
      expect(m.ocrRawText, local.ocrRawText);
      expect(m.llmConfidence, local.llmConfidence);
      expect(m.userNotes, local.userNotes);
      expect(m.userTags, local.userTags);
      expect(m.isFavorite, local.isFavorite);
      expect(m.category, local.category);
      expect(m.warrantyMonths, local.warrantyMonths);
    });

    test('syncStatus is always set to synced', () {
      final local = buildReceipt(syncStatus: SyncStatus.conflict);
      final server = buildServerItem();

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.syncStatus, SyncStatus.synced);
    });
  });

  // ===========================================================================
  // 2. Tier 1: Server/LLM wins
  // ===========================================================================
  group('Tier 1 - Server/LLM wins', () {
    test('server extractedMerchantName overrides local', () {
      final local = buildReceipt(extractedMerchantName: 'Local Merchant');
      final server = buildServerItem(extractedMerchantName: 'Server Merchant');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedMerchantName, 'Server Merchant');
      expect(result.changedFields, contains('extractedMerchantName'));
      expect(result.hadConflict, isTrue);
    });

    test('server extractedDate overrides local', () {
      final local = buildReceipt(extractedDate: '2026-01-15');
      final server = buildServerItem(extractedDate: '2026-01-20');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedDate, '2026-01-20');
      expect(result.changedFields, contains('extractedDate'));
    });

    test('server extractedTotal overrides local', () {
      final local = buildReceipt(extractedTotal: 50.0);
      final server = buildServerItem(extractedTotal: 75.50);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedTotal, 75.50);
      expect(result.changedFields, contains('extractedTotal'));
    });

    test('server ocrRawText overrides local', () {
      final local = buildReceipt(ocrRawText: 'old ocr');
      final server = buildServerItem(ocrRawText: 'refined ocr output');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.ocrRawText, 'refined ocr output');
      expect(result.changedFields, contains('ocrRawText'));
    });

    test('server llmConfidence overrides local', () {
      final local = buildReceipt(llmConfidence: 70);
      final server = buildServerItem(llmConfidence: 95);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.llmConfidence, 95);
      expect(result.changedFields, contains('llmConfidence'));
    });

    test('all tier 1 fields changed are tracked in changedFields', () {
      final local = buildReceipt(
        extractedMerchantName: 'A',
        extractedDate: '2026-01-01',
        extractedTotal: 10.0,
        ocrRawText: 'old',
        llmConfidence: 50,
      );
      final server = buildServerItem(
        extractedMerchantName: 'B',
        extractedDate: '2026-02-02',
        extractedTotal: 20.0,
        ocrRawText: 'new',
        llmConfidence: 90,
      );

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.changedFields, containsAll([
        'extractedMerchantName',
        'extractedDate',
        'extractedTotal',
        'ocrRawText',
        'llmConfidence',
      ]));
    });
  });

  // ===========================================================================
  // 3. Tier 2: Client/User wins
  // ===========================================================================
  group('Tier 2 - Client/User wins', () {
    test('local userNotes kept even when server differs', () {
      final local = buildReceipt(userNotes: 'my local note');
      final server = buildServerItem(userNotes: 'server note override');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.userNotes, 'my local note');
      expect(result.changedFields, contains('userNotes'));
      expect(result.hadConflict, isTrue);
    });

    test('local userTags kept even when server differs', () {
      final local = buildReceipt(userTags: ['local-tag-1', 'local-tag-2']);
      final server = buildServerItem(userTags: ['server-tag']);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.userTags, ['local-tag-1', 'local-tag-2']);
      expect(result.changedFields, contains('userTags'));
    });

    test('local isFavorite kept even when server differs', () {
      final local = buildReceipt(isFavorite: true);
      final server = buildServerItem(isFavorite: false);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.isFavorite, isTrue);
      expect(result.changedFields, contains('isFavorite'));
    });
  });

  // ===========================================================================
  // 4. Tier 3: user-edited field -> client wins
  // ===========================================================================
  group('Tier 3 - user-edited field (client wins)', () {
    test('storeName in userEditedFields keeps local value', () {
      final local = buildReceipt(
        storeName: 'User Edited Store',
        userEditedFields: ['storeName'],
      );
      final server = buildServerItem(storeName: 'Server Store');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.storeName, 'User Edited Store');
      expect(result.changedFields, contains('storeName'));
    });

    test('category in userEditedFields keeps local value', () {
      final local = buildReceipt(
        category: 'User Category',
        userEditedFields: ['category'],
      );
      final server = buildServerItem(category: 'Server Category');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.category, 'User Category');
      expect(result.changedFields, contains('category'));
    });

    test('warrantyMonths in userEditedFields keeps local value', () {
      final local = buildReceipt(
        warrantyMonths: 24,
        userEditedFields: ['warrantyMonths'],
      );
      final server = buildServerItem(warrantyMonths: 6);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.warrantyMonths, 24);
      expect(result.changedFields, contains('warrantyMonths'));
    });
  });

  // ===========================================================================
  // 5. Tier 3: NOT user-edited -> server wins
  // ===========================================================================
  group('Tier 3 - not user-edited (server wins)', () {
    test('storeName NOT in userEditedFields takes server value', () {
      final local = buildReceipt(
        storeName: 'Local Store',
        userEditedFields: [],
      );
      final server = buildServerItem(storeName: 'Server Store');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.storeName, 'Server Store');
      expect(result.changedFields, contains('storeName'));
    });

    test('category NOT in userEditedFields takes server value', () {
      final local = buildReceipt(
        category: 'Local Category',
        userEditedFields: [],
      );
      final server = buildServerItem(category: 'Server Category');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.category, 'Server Category');
    });

    test('warrantyMonths NOT in userEditedFields takes server value', () {
      final local = buildReceipt(
        warrantyMonths: 12,
        userEditedFields: [],
      );
      final server = buildServerItem(warrantyMonths: 36);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.warrantyMonths, 36);
    });
  });

  // ===========================================================================
  // 6. Tier 3: mixed — some user-edited, some not
  // ===========================================================================
  group('Tier 3 - mixed user-edited and non-edited', () {
    test('category user-edited (client wins) + warrantyMonths not edited (server wins)', () {
      final local = buildReceipt(
        category: 'My Custom Category',
        warrantyMonths: 12,
        storeName: 'Local Store Name',
        userEditedFields: ['category'],
      );
      final server = buildServerItem(
        category: 'Server Category',
        warrantyMonths: 36,
        storeName: 'Server Store Name',
      );

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      // category: user-edited -> client wins
      expect(result.mergedReceipt.category, 'My Custom Category');
      // warrantyMonths: not user-edited -> server wins
      expect(result.mergedReceipt.warrantyMonths, 36);
      // storeName: not user-edited -> server wins
      expect(result.mergedReceipt.storeName, 'Server Store Name');

      expect(result.changedFields, contains('category'));
      expect(result.changedFields, contains('warrantyMonths'));
      expect(result.changedFields, contains('storeName'));
    });

    test('storeName + warrantyMonths user-edited, category not', () {
      final local = buildReceipt(
        storeName: 'User Store',
        warrantyMonths: 24,
        category: 'Local Cat',
        userEditedFields: ['storeName', 'warrantyMonths'],
      );
      final server = buildServerItem(
        storeName: 'Server Store',
        warrantyMonths: 6,
        category: 'Server Cat',
      );

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      // storeName: user-edited -> client wins
      expect(result.mergedReceipt.storeName, 'User Store');
      // warrantyMonths: user-edited -> client wins
      expect(result.mergedReceipt.warrantyMonths, 24);
      // category: not user-edited -> server wins
      expect(result.mergedReceipt.category, 'Server Cat');
    });
  });

  // ===========================================================================
  // 7. Version merge: max(server, client) + 1
  // ===========================================================================
  group('Version merge', () {
    test('max(server=5, client=3) + 1 = 6', () {
      final local = buildReceipt(version: 3);
      final server = buildServerItem(version: 5);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.version, 6);
    });

    test('max(server=2, client=7) + 1 = 8', () {
      final local = buildReceipt(version: 7);
      final server = buildServerItem(version: 2);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.version, 8);
    });

    test('max(server=4, client=4) + 1 = 5 when versions equal', () {
      final local = buildReceipt(version: 4);
      final server = buildServerItem(version: 4);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.version, 5);
    });

    test('server version defaults to 1 when missing', () {
      final local = buildReceipt(version: 3);
      final server = buildServerItem();
      server.remove('version');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      // max(1, 3) + 1 = 4
      expect(result.mergedReceipt.version, 4);
    });
  });

  // ===========================================================================
  // 8. userEditedFields union
  // ===========================================================================
  group('userEditedFields union', () {
    test('client [storeName] + server [category] = both', () {
      final local = buildReceipt(userEditedFields: ['storeName']);
      final server = buildServerItem(userEditedFields: ['category']);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(
        result.mergedReceipt.userEditedFields,
        containsAll(['storeName', 'category']),
      );
      expect(result.mergedReceipt.userEditedFields.length, 2);
    });

    test('overlapping fields are not duplicated', () {
      final local = buildReceipt(
        userEditedFields: ['storeName', 'category'],
      );
      final server = buildServerItem(
        userEditedFields: ['category', 'warrantyMonths'],
      );

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      final merged = result.mergedReceipt.userEditedFields;
      expect(merged, containsAll(['storeName', 'category', 'warrantyMonths']));
      expect(merged.length, 3);
      // Verify sorted (implementation sorts the result)
      expect(merged, orderedEquals(['category', 'storeName', 'warrantyMonths']));
    });

    test('both empty produces empty', () {
      final local = buildReceipt(userEditedFields: []);
      final server = buildServerItem(userEditedFields: []);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.userEditedFields, isEmpty);
    });

    test('server userEditedFields as JSON-encoded string', () {
      final local = buildReceipt(userEditedFields: ['storeName']);
      final server = buildServerItem();
      // Simulate DynamoDB returning a JSON-encoded string list
      server['userEditedFields'] = '["category"]';

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(
        result.mergedReceipt.userEditedFields,
        containsAll(['storeName', 'category']),
      );
    });
  });

  // ===========================================================================
  // 9. changedFields tracking
  // ===========================================================================
  group('changedFields tracking', () {
    test('only divergent fields appear in changedFields', () {
      final local = buildReceipt(
        extractedMerchantName: 'Old Merchant',
        userNotes: 'my note',
        storeName: 'Same Store',
        userEditedFields: [],
      );
      final server = buildServerItem(
        extractedMerchantName: 'New Merchant', // Tier 1 diverges
        userNotes: 'my note',                  // Tier 2 identical
        storeName: 'Same Store',               // Tier 3 identical
      );

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.changedFields, ['extractedMerchantName']);
      expect(result.hadConflict, isTrue);
    });

    test('tier 2 divergence is tracked even though client wins', () {
      final local = buildReceipt(userNotes: 'client note');
      final server = buildServerItem(userNotes: 'server note');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.changedFields, contains('userNotes'));
    });

    test('tier 3 user-edited divergence is tracked', () {
      final local = buildReceipt(
        storeName: 'User Store',
        userEditedFields: ['storeName'],
      );
      final server = buildServerItem(storeName: 'Server Store');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.changedFields, contains('storeName'));
    });

    test('no divergence means empty changedFields', () {
      final local = buildReceipt();
      final server = buildServerItem();

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.changedFields, isEmpty);
      expect(result.hadConflict, isFalse);
    });
  });

  // ===========================================================================
  // 10. Null server fields fall back to local value
  // ===========================================================================
  group('Null server fields fall back to local value', () {
    test('null server extractedMerchantName falls back to local', () {
      final local = buildReceipt(extractedMerchantName: 'Local Merchant');
      final server = buildServerItem(extractedMerchantName: null);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedMerchantName, 'Local Merchant');
      expect(result.changedFields, isNot(contains('extractedMerchantName')));
    });

    test('null server extractedTotal falls back to local', () {
      final local = buildReceipt(extractedTotal: 42.50);
      final server = buildServerItem(extractedTotal: null);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedTotal, 42.50);
      expect(result.changedFields, isNot(contains('extractedTotal')));
    });

    test('null server ocrRawText falls back to local', () {
      final local = buildReceipt(ocrRawText: 'local ocr');
      final server = buildServerItem(ocrRawText: null);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.ocrRawText, 'local ocr');
    });

    test('null server llmConfidence falls back to local', () {
      final local = buildReceipt(llmConfidence: 80);
      final server = buildServerItem();
      server['llmConfidence'] = null;

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.llmConfidence, 80);
    });

    test('null server storeName (not user-edited) falls back to local', () {
      final local = buildReceipt(
        storeName: 'Fallback Store',
        userEditedFields: [],
      );
      final server = buildServerItem(storeName: null);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.storeName, 'Fallback Store');
      expect(result.changedFields, isNot(contains('storeName')));
    });

    test('null server category (not user-edited) falls back to local', () {
      final local = buildReceipt(
        category: 'Local Category',
        userEditedFields: [],
      );
      final server = buildServerItem(category: null);

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.category, 'Local Category');
    });

    test('null server warrantyMonths (not user-edited) falls back to local', () {
      final local = buildReceipt(
        warrantyMonths: 24,
        userEditedFields: [],
      );
      final server = buildServerItem();
      server['warrantyMonths'] = null;

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.warrantyMonths, 24);
    });

    test('missing server field key falls back to local', () {
      final local = buildReceipt(extractedMerchantName: 'Local Merchant');
      final server = buildServerItem();
      server.remove('extractedMerchantName');

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedMerchantName, 'Local Merchant');
    });
  });

  // ===========================================================================
  // Additional: localImagePaths always kept from local
  // ===========================================================================
  group('localImagePaths always kept from local', () {
    test('merged receipt keeps local image paths regardless of server', () {
      final local = buildReceipt(
        localImagePaths: ['/device/img1.jpg', '/device/img2.jpg'],
      );
      final server = buildServerItem();

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(
        result.mergedReceipt.localImagePaths,
        ['/device/img1.jpg', '/device/img2.jpg'],
      );
    });
  });

  // ===========================================================================
  // Additional: syncStatus always set to synced
  // ===========================================================================
  group('syncStatus always synced', () {
    test('merged receipt has SyncStatus.synced regardless of local status', () {
      for (final localStatus in SyncStatus.values) {
        final local = buildReceipt(syncStatus: localStatus);
        final server = buildServerItem();

        final result = resolver.resolve(
          localReceipt: local,
          serverItem: server,
        );

        expect(result.mergedReceipt.syncStatus, SyncStatus.synced);
      }
    });
  });

  // ===========================================================================
  // Additional: extractedTotal from server as int (num.toDouble)
  // ===========================================================================
  group('Server numeric coercion', () {
    test('server extractedTotal as int is coerced to double', () {
      final local = buildReceipt(extractedTotal: 50.0);
      final server = buildServerItem();
      server['extractedTotal'] = 75; // int, not double

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.extractedTotal, 75.0);
      expect(result.mergedReceipt.extractedTotal, isA<double>());
    });

    test('server totalAmount as int is coerced to double', () {
      final local = buildReceipt(totalAmount: 100.0);
      final server = buildServerItem();
      server['totalAmount'] = 200; // int, not double

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      expect(result.mergedReceipt.totalAmount, 200.0);
      expect(result.mergedReceipt.totalAmount, isA<double>());
    });
  });

  // ===========================================================================
  // Additional: complex integration scenario
  // ===========================================================================
  group('Integration scenario', () {
    test('multi-tier conflict with version merge and field union', () {
      final local = buildReceipt(
        // Tier 1 fields (server should win)
        extractedMerchantName: 'Local Merchant',
        extractedTotal: 10.0,
        llmConfidence: 70,
        // Tier 2 fields (client should win)
        userNotes: 'Important purchase',
        isFavorite: true,
        userTags: ['electronics', 'warranty'],
        // Tier 3 fields
        storeName: 'My Custom Store',     // user-edited -> client wins
        category: 'Auto-detected Cat',     // not user-edited -> server wins
        warrantyMonths: 12,                // user-edited -> client wins
        userEditedFields: ['storeName', 'warrantyMonths'],
        version: 5,
        localImagePaths: ['/sdcard/receipt-001.jpg'],
      );

      final server = buildServerItem(
        extractedMerchantName: 'LLM Refined Merchant',
        extractedTotal: 15.50,
        llmConfidence: 95,
        userNotes: 'Server overwrote note',
        isFavorite: false,
        userTags: ['server-tag'],
        storeName: 'Server Store Name',
        category: 'Server Category',
        warrantyMonths: 24,
        userEditedFields: ['category'],
        version: 8,
      );

      final result = resolver.resolve(
        localReceipt: local,
        serverItem: server,
      );

      final m = result.mergedReceipt;

      // Tier 1: server wins
      expect(m.extractedMerchantName, 'LLM Refined Merchant');
      expect(m.extractedTotal, 15.50);
      expect(m.llmConfidence, 95);

      // Tier 2: client wins
      expect(m.userNotes, 'Important purchase');
      expect(m.isFavorite, isTrue);
      expect(m.userTags, ['electronics', 'warranty']);

      // Tier 3: storeName user-edited -> client wins
      expect(m.storeName, 'My Custom Store');
      // Tier 3: category NOT in local userEditedFields -> server wins
      expect(m.category, 'Server Category');
      // Tier 3: warrantyMonths user-edited -> client wins
      expect(m.warrantyMonths, 12);

      // Version: max(8, 5) + 1 = 9
      expect(m.version, 9);

      // userEditedFields: union(['storeName', 'warrantyMonths'], ['category'])
      expect(
        m.userEditedFields,
        containsAll(['storeName', 'warrantyMonths', 'category']),
      );
      expect(m.userEditedFields.length, 3);

      // Always synced
      expect(m.syncStatus, SyncStatus.synced);

      // Local image paths preserved
      expect(m.localImagePaths, ['/sdcard/receipt-001.jpg']);

      // hadConflict is true (many fields diverged)
      expect(result.hadConflict, isTrue);
      expect(result.changedFields, isNotEmpty);

      // Verify specific changed fields
      expect(result.changedFields, containsAll([
        'extractedMerchantName',
        'extractedTotal',
        'llmConfidence',
        'userNotes',
        'userTags',
        'isFavorite',
        'storeName',
        'category',
        'warrantyMonths',
      ]));
    });
  });
}
