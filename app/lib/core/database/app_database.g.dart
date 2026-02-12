// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReceiptsTable extends Receipts
    with TableInfo<$ReceiptsTable, ReceiptEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _receiptIdMeta =
      const VerificationMeta('receiptId');
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
      'receipt_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storeNameMeta =
      const VerificationMeta('storeName');
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
      'store_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extractedMerchantNameMeta =
      const VerificationMeta('extractedMerchantName');
  @override
  late final GeneratedColumn<String> extractedMerchantName =
      GeneratedColumn<String>('extracted_merchant_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _purchaseDateMeta =
      const VerificationMeta('purchaseDate');
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
      'purchase_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extractedDateMeta =
      const VerificationMeta('extractedDate');
  @override
  late final GeneratedColumn<String> extractedDate = GeneratedColumn<String>(
      'extracted_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _extractedTotalMeta =
      const VerificationMeta('extractedTotal');
  @override
  late final GeneratedColumn<double> extractedTotal = GeneratedColumn<double>(
      'extracted_total', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('EUR'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _warrantyMonthsMeta =
      const VerificationMeta('warrantyMonths');
  @override
  late final GeneratedColumn<int> warrantyMonths = GeneratedColumn<int>(
      'warranty_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _warrantyExpiryDateMeta =
      const VerificationMeta('warrantyExpiryDate');
  @override
  late final GeneratedColumn<String> warrantyExpiryDate =
      GeneratedColumn<String>('warranty_expiry_date', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _imageKeysMeta =
      const VerificationMeta('imageKeys');
  @override
  late final GeneratedColumn<String> imageKeys = GeneratedColumn<String>(
      'image_keys', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailKeysMeta =
      const VerificationMeta('thumbnailKeys');
  @override
  late final GeneratedColumn<String> thumbnailKeys = GeneratedColumn<String>(
      'thumbnail_keys', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrRawTextMeta =
      const VerificationMeta('ocrRawText');
  @override
  late final GeneratedColumn<String> ocrRawText = GeneratedColumn<String>(
      'ocr_raw_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _llmConfidenceMeta =
      const VerificationMeta('llmConfidence');
  @override
  late final GeneratedColumn<int> llmConfidence = GeneratedColumn<int>(
      'llm_confidence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _userNotesMeta =
      const VerificationMeta('userNotes');
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
      'user_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userTagsMeta =
      const VerificationMeta('userTags');
  @override
  late final GeneratedColumn<String> userTags = GeneratedColumn<String>(
      'user_tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _userEditedFieldsMeta =
      const VerificationMeta('userEditedFields');
  @override
  late final GeneratedColumn<String> userEditedFields = GeneratedColumn<String>(
      'user_edited_fields', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<String> lastSyncedAt = GeneratedColumn<String>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localImagePathsMeta =
      const VerificationMeta('localImagePaths');
  @override
  late final GeneratedColumn<String> localImagePaths = GeneratedColumn<String>(
      'local_image_paths', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        receiptId,
        userId,
        storeName,
        extractedMerchantName,
        purchaseDate,
        extractedDate,
        totalAmount,
        extractedTotal,
        currency,
        category,
        warrantyMonths,
        warrantyExpiryDate,
        status,
        imageKeys,
        thumbnailKeys,
        ocrRawText,
        llmConfidence,
        userNotes,
        userTags,
        isFavorite,
        userEditedFields,
        createdAt,
        updatedAt,
        version,
        deletedAt,
        syncStatus,
        lastSyncedAt,
        localImagePaths
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(Insertable<ReceiptEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('receipt_id')) {
      context.handle(_receiptIdMeta,
          receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta));
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(_storeNameMeta,
          storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta));
    }
    if (data.containsKey('extracted_merchant_name')) {
      context.handle(
          _extractedMerchantNameMeta,
          extractedMerchantName.isAcceptableOrUnknown(
              data['extracted_merchant_name']!, _extractedMerchantNameMeta));
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
          _purchaseDateMeta,
          purchaseDate.isAcceptableOrUnknown(
              data['purchase_date']!, _purchaseDateMeta));
    }
    if (data.containsKey('extracted_date')) {
      context.handle(
          _extractedDateMeta,
          extractedDate.isAcceptableOrUnknown(
              data['extracted_date']!, _extractedDateMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    }
    if (data.containsKey('extracted_total')) {
      context.handle(
          _extractedTotalMeta,
          extractedTotal.isAcceptableOrUnknown(
              data['extracted_total']!, _extractedTotalMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('warranty_months')) {
      context.handle(
          _warrantyMonthsMeta,
          warrantyMonths.isAcceptableOrUnknown(
              data['warranty_months']!, _warrantyMonthsMeta));
    }
    if (data.containsKey('warranty_expiry_date')) {
      context.handle(
          _warrantyExpiryDateMeta,
          warrantyExpiryDate.isAcceptableOrUnknown(
              data['warranty_expiry_date']!, _warrantyExpiryDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('image_keys')) {
      context.handle(_imageKeysMeta,
          imageKeys.isAcceptableOrUnknown(data['image_keys']!, _imageKeysMeta));
    }
    if (data.containsKey('thumbnail_keys')) {
      context.handle(
          _thumbnailKeysMeta,
          thumbnailKeys.isAcceptableOrUnknown(
              data['thumbnail_keys']!, _thumbnailKeysMeta));
    }
    if (data.containsKey('ocr_raw_text')) {
      context.handle(
          _ocrRawTextMeta,
          ocrRawText.isAcceptableOrUnknown(
              data['ocr_raw_text']!, _ocrRawTextMeta));
    }
    if (data.containsKey('llm_confidence')) {
      context.handle(
          _llmConfidenceMeta,
          llmConfidence.isAcceptableOrUnknown(
              data['llm_confidence']!, _llmConfidenceMeta));
    }
    if (data.containsKey('user_notes')) {
      context.handle(_userNotesMeta,
          userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta));
    }
    if (data.containsKey('user_tags')) {
      context.handle(_userTagsMeta,
          userTags.isAcceptableOrUnknown(data['user_tags']!, _userTagsMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('user_edited_fields')) {
      context.handle(
          _userEditedFieldsMeta,
          userEditedFields.isAcceptableOrUnknown(
              data['user_edited_fields']!, _userEditedFieldsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('local_image_paths')) {
      context.handle(
          _localImagePathsMeta,
          localImagePaths.isAcceptableOrUnknown(
              data['local_image_paths']!, _localImagePathsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {receiptId};
  @override
  ReceiptEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptEntry(
      receiptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      storeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store_name']),
      extractedMerchantName: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}extracted_merchant_name']),
      purchaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purchase_date']),
      extractedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extracted_date']),
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount']),
      extractedTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}extracted_total']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      warrantyMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}warranty_months'])!,
      warrantyExpiryDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}warranty_expiry_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      imageKeys: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_keys']),
      thumbnailKeys: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_keys']),
      ocrRawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_raw_text']),
      llmConfidence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}llm_confidence'])!,
      userNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_notes']),
      userTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_tags']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      userEditedFields: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}user_edited_fields']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      lastSyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_synced_at']),
      localImagePaths: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_image_paths']),
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class ReceiptEntry extends DataClass implements Insertable<ReceiptEntry> {
  final String receiptId;
  final String userId;
  final String? storeName;
  final String? extractedMerchantName;

  /// ISO 8601 date (YYYY-MM-DD).
  final String? purchaseDate;

  /// Raw LLM extraction of date.
  final String? extractedDate;
  final double? totalAmount;
  final double? extractedTotal;

  /// ISO 4217 currency code. Defaults to EUR.
  final String currency;
  final String? category;

  /// Duration in months. 0 means no warranty.
  final int warrantyMonths;

  /// Calculated: purchaseDate + warrantyMonths. ISO 8601 date.
  final String? warrantyExpiryDate;

  /// One of: active, returned, deleted.
  final String status;

  /// JSON list of S3 object keys for originals.
  final String? imageKeys;

  /// JSON list of S3 object keys for thumbnails.
  final String? thumbnailKeys;

  /// Raw OCR output from ML Kit + Tesseract.
  final String? ocrRawText;

  /// LLM confidence score (0-100).
  final int llmConfidence;
  final String? userNotes;

  /// JSON list of tag strings.
  final String? userTags;

  /// Boolean stored as 0/1.
  final bool isFavorite;

  /// JSON list of field names the user has manually edited.
  final String? userEditedFields;

  /// ISO 8601 datetime. Set once at creation, never modified.
  final String createdAt;

  /// ISO 8601 datetime. Updated on every write.
  final String updatedAt;

  /// Optimistic concurrency version, starts at 1.
  final int version;

  /// ISO 8601 datetime. Set on soft delete.
  final String? deletedAt;

  /// Unused — retained to avoid DB migration.
  final String syncStatus;

  /// Unused — retained to avoid DB migration.
  final String? lastSyncedAt;

  /// JSON list of local file paths for cached/captured images.
  final String? localImagePaths;
  const ReceiptEntry(
      {required this.receiptId,
      required this.userId,
      this.storeName,
      this.extractedMerchantName,
      this.purchaseDate,
      this.extractedDate,
      this.totalAmount,
      this.extractedTotal,
      required this.currency,
      this.category,
      required this.warrantyMonths,
      this.warrantyExpiryDate,
      required this.status,
      this.imageKeys,
      this.thumbnailKeys,
      this.ocrRawText,
      required this.llmConfidence,
      this.userNotes,
      this.userTags,
      required this.isFavorite,
      this.userEditedFields,
      required this.createdAt,
      required this.updatedAt,
      required this.version,
      this.deletedAt,
      required this.syncStatus,
      this.lastSyncedAt,
      this.localImagePaths});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['receipt_id'] = Variable<String>(receiptId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || extractedMerchantName != null) {
      map['extracted_merchant_name'] = Variable<String>(extractedMerchantName);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<String>(purchaseDate);
    }
    if (!nullToAbsent || extractedDate != null) {
      map['extracted_date'] = Variable<String>(extractedDate);
    }
    if (!nullToAbsent || totalAmount != null) {
      map['total_amount'] = Variable<double>(totalAmount);
    }
    if (!nullToAbsent || extractedTotal != null) {
      map['extracted_total'] = Variable<double>(extractedTotal);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['warranty_months'] = Variable<int>(warrantyMonths);
    if (!nullToAbsent || warrantyExpiryDate != null) {
      map['warranty_expiry_date'] = Variable<String>(warrantyExpiryDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || imageKeys != null) {
      map['image_keys'] = Variable<String>(imageKeys);
    }
    if (!nullToAbsent || thumbnailKeys != null) {
      map['thumbnail_keys'] = Variable<String>(thumbnailKeys);
    }
    if (!nullToAbsent || ocrRawText != null) {
      map['ocr_raw_text'] = Variable<String>(ocrRawText);
    }
    map['llm_confidence'] = Variable<int>(llmConfidence);
    if (!nullToAbsent || userNotes != null) {
      map['user_notes'] = Variable<String>(userNotes);
    }
    if (!nullToAbsent || userTags != null) {
      map['user_tags'] = Variable<String>(userTags);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || userEditedFields != null) {
      map['user_edited_fields'] = Variable<String>(userEditedFields);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<String>(lastSyncedAt);
    }
    if (!nullToAbsent || localImagePaths != null) {
      map['local_image_paths'] = Variable<String>(localImagePaths);
    }
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      receiptId: Value(receiptId),
      userId: Value(userId),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      extractedMerchantName: extractedMerchantName == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedMerchantName),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      extractedDate: extractedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedDate),
      totalAmount: totalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmount),
      extractedTotal: extractedTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedTotal),
      currency: Value(currency),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      warrantyMonths: Value(warrantyMonths),
      warrantyExpiryDate: warrantyExpiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyExpiryDate),
      status: Value(status),
      imageKeys: imageKeys == null && nullToAbsent
          ? const Value.absent()
          : Value(imageKeys),
      thumbnailKeys: thumbnailKeys == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailKeys),
      ocrRawText: ocrRawText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrRawText),
      llmConfidence: Value(llmConfidence),
      userNotes: userNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(userNotes),
      userTags: userTags == null && nullToAbsent
          ? const Value.absent()
          : Value(userTags),
      isFavorite: Value(isFavorite),
      userEditedFields: userEditedFields == null && nullToAbsent
          ? const Value.absent()
          : Value(userEditedFields),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      localImagePaths: localImagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePaths),
    );
  }

  factory ReceiptEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptEntry(
      receiptId: serializer.fromJson<String>(json['receiptId']),
      userId: serializer.fromJson<String>(json['userId']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      extractedMerchantName:
          serializer.fromJson<String?>(json['extractedMerchantName']),
      purchaseDate: serializer.fromJson<String?>(json['purchaseDate']),
      extractedDate: serializer.fromJson<String?>(json['extractedDate']),
      totalAmount: serializer.fromJson<double?>(json['totalAmount']),
      extractedTotal: serializer.fromJson<double?>(json['extractedTotal']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String?>(json['category']),
      warrantyMonths: serializer.fromJson<int>(json['warrantyMonths']),
      warrantyExpiryDate:
          serializer.fromJson<String?>(json['warrantyExpiryDate']),
      status: serializer.fromJson<String>(json['status']),
      imageKeys: serializer.fromJson<String?>(json['imageKeys']),
      thumbnailKeys: serializer.fromJson<String?>(json['thumbnailKeys']),
      ocrRawText: serializer.fromJson<String?>(json['ocrRawText']),
      llmConfidence: serializer.fromJson<int>(json['llmConfidence']),
      userNotes: serializer.fromJson<String?>(json['userNotes']),
      userTags: serializer.fromJson<String?>(json['userTags']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      userEditedFields: serializer.fromJson<String?>(json['userEditedFields']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<String?>(json['lastSyncedAt']),
      localImagePaths: serializer.fromJson<String?>(json['localImagePaths']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'receiptId': serializer.toJson<String>(receiptId),
      'userId': serializer.toJson<String>(userId),
      'storeName': serializer.toJson<String?>(storeName),
      'extractedMerchantName':
          serializer.toJson<String?>(extractedMerchantName),
      'purchaseDate': serializer.toJson<String?>(purchaseDate),
      'extractedDate': serializer.toJson<String?>(extractedDate),
      'totalAmount': serializer.toJson<double?>(totalAmount),
      'extractedTotal': serializer.toJson<double?>(extractedTotal),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String?>(category),
      'warrantyMonths': serializer.toJson<int>(warrantyMonths),
      'warrantyExpiryDate': serializer.toJson<String?>(warrantyExpiryDate),
      'status': serializer.toJson<String>(status),
      'imageKeys': serializer.toJson<String?>(imageKeys),
      'thumbnailKeys': serializer.toJson<String?>(thumbnailKeys),
      'ocrRawText': serializer.toJson<String?>(ocrRawText),
      'llmConfidence': serializer.toJson<int>(llmConfidence),
      'userNotes': serializer.toJson<String?>(userNotes),
      'userTags': serializer.toJson<String?>(userTags),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'userEditedFields': serializer.toJson<String?>(userEditedFields),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<String?>(lastSyncedAt),
      'localImagePaths': serializer.toJson<String?>(localImagePaths),
    };
  }

  ReceiptEntry copyWith(
          {String? receiptId,
          String? userId,
          Value<String?> storeName = const Value.absent(),
          Value<String?> extractedMerchantName = const Value.absent(),
          Value<String?> purchaseDate = const Value.absent(),
          Value<String?> extractedDate = const Value.absent(),
          Value<double?> totalAmount = const Value.absent(),
          Value<double?> extractedTotal = const Value.absent(),
          String? currency,
          Value<String?> category = const Value.absent(),
          int? warrantyMonths,
          Value<String?> warrantyExpiryDate = const Value.absent(),
          String? status,
          Value<String?> imageKeys = const Value.absent(),
          Value<String?> thumbnailKeys = const Value.absent(),
          Value<String?> ocrRawText = const Value.absent(),
          int? llmConfidence,
          Value<String?> userNotes = const Value.absent(),
          Value<String?> userTags = const Value.absent(),
          bool? isFavorite,
          Value<String?> userEditedFields = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          int? version,
          Value<String?> deletedAt = const Value.absent(),
          String? syncStatus,
          Value<String?> lastSyncedAt = const Value.absent(),
          Value<String?> localImagePaths = const Value.absent()}) =>
      ReceiptEntry(
        receiptId: receiptId ?? this.receiptId,
        userId: userId ?? this.userId,
        storeName: storeName.present ? storeName.value : this.storeName,
        extractedMerchantName: extractedMerchantName.present
            ? extractedMerchantName.value
            : this.extractedMerchantName,
        purchaseDate:
            purchaseDate.present ? purchaseDate.value : this.purchaseDate,
        extractedDate:
            extractedDate.present ? extractedDate.value : this.extractedDate,
        totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
        extractedTotal:
            extractedTotal.present ? extractedTotal.value : this.extractedTotal,
        currency: currency ?? this.currency,
        category: category.present ? category.value : this.category,
        warrantyMonths: warrantyMonths ?? this.warrantyMonths,
        warrantyExpiryDate: warrantyExpiryDate.present
            ? warrantyExpiryDate.value
            : this.warrantyExpiryDate,
        status: status ?? this.status,
        imageKeys: imageKeys.present ? imageKeys.value : this.imageKeys,
        thumbnailKeys:
            thumbnailKeys.present ? thumbnailKeys.value : this.thumbnailKeys,
        ocrRawText: ocrRawText.present ? ocrRawText.value : this.ocrRawText,
        llmConfidence: llmConfidence ?? this.llmConfidence,
        userNotes: userNotes.present ? userNotes.value : this.userNotes,
        userTags: userTags.present ? userTags.value : this.userTags,
        isFavorite: isFavorite ?? this.isFavorite,
        userEditedFields: userEditedFields.present
            ? userEditedFields.value
            : this.userEditedFields,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        localImagePaths: localImagePaths.present
            ? localImagePaths.value
            : this.localImagePaths,
      );
  ReceiptEntry copyWithCompanion(ReceiptsCompanion data) {
    return ReceiptEntry(
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      userId: data.userId.present ? data.userId.value : this.userId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      extractedMerchantName: data.extractedMerchantName.present
          ? data.extractedMerchantName.value
          : this.extractedMerchantName,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      extractedDate: data.extractedDate.present
          ? data.extractedDate.value
          : this.extractedDate,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      extractedTotal: data.extractedTotal.present
          ? data.extractedTotal.value
          : this.extractedTotal,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      warrantyMonths: data.warrantyMonths.present
          ? data.warrantyMonths.value
          : this.warrantyMonths,
      warrantyExpiryDate: data.warrantyExpiryDate.present
          ? data.warrantyExpiryDate.value
          : this.warrantyExpiryDate,
      status: data.status.present ? data.status.value : this.status,
      imageKeys: data.imageKeys.present ? data.imageKeys.value : this.imageKeys,
      thumbnailKeys: data.thumbnailKeys.present
          ? data.thumbnailKeys.value
          : this.thumbnailKeys,
      ocrRawText:
          data.ocrRawText.present ? data.ocrRawText.value : this.ocrRawText,
      llmConfidence: data.llmConfidence.present
          ? data.llmConfidence.value
          : this.llmConfidence,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      userTags: data.userTags.present ? data.userTags.value : this.userTags,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      userEditedFields: data.userEditedFields.present
          ? data.userEditedFields.value
          : this.userEditedFields,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      localImagePaths: data.localImagePaths.present
          ? data.localImagePaths.value
          : this.localImagePaths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptEntry(')
          ..write('receiptId: $receiptId, ')
          ..write('userId: $userId, ')
          ..write('storeName: $storeName, ')
          ..write('extractedMerchantName: $extractedMerchantName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('extractedDate: $extractedDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('extractedTotal: $extractedTotal, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('warrantyExpiryDate: $warrantyExpiryDate, ')
          ..write('status: $status, ')
          ..write('imageKeys: $imageKeys, ')
          ..write('thumbnailKeys: $thumbnailKeys, ')
          ..write('ocrRawText: $ocrRawText, ')
          ..write('llmConfidence: $llmConfidence, ')
          ..write('userNotes: $userNotes, ')
          ..write('userTags: $userTags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('userEditedFields: $userEditedFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('localImagePaths: $localImagePaths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        receiptId,
        userId,
        storeName,
        extractedMerchantName,
        purchaseDate,
        extractedDate,
        totalAmount,
        extractedTotal,
        currency,
        category,
        warrantyMonths,
        warrantyExpiryDate,
        status,
        imageKeys,
        thumbnailKeys,
        ocrRawText,
        llmConfidence,
        userNotes,
        userTags,
        isFavorite,
        userEditedFields,
        createdAt,
        updatedAt,
        version,
        deletedAt,
        syncStatus,
        lastSyncedAt,
        localImagePaths
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptEntry &&
          other.receiptId == this.receiptId &&
          other.userId == this.userId &&
          other.storeName == this.storeName &&
          other.extractedMerchantName == this.extractedMerchantName &&
          other.purchaseDate == this.purchaseDate &&
          other.extractedDate == this.extractedDate &&
          other.totalAmount == this.totalAmount &&
          other.extractedTotal == this.extractedTotal &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.warrantyMonths == this.warrantyMonths &&
          other.warrantyExpiryDate == this.warrantyExpiryDate &&
          other.status == this.status &&
          other.imageKeys == this.imageKeys &&
          other.thumbnailKeys == this.thumbnailKeys &&
          other.ocrRawText == this.ocrRawText &&
          other.llmConfidence == this.llmConfidence &&
          other.userNotes == this.userNotes &&
          other.userTags == this.userTags &&
          other.isFavorite == this.isFavorite &&
          other.userEditedFields == this.userEditedFields &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.localImagePaths == this.localImagePaths);
}

class ReceiptsCompanion extends UpdateCompanion<ReceiptEntry> {
  final Value<String> receiptId;
  final Value<String> userId;
  final Value<String?> storeName;
  final Value<String?> extractedMerchantName;
  final Value<String?> purchaseDate;
  final Value<String?> extractedDate;
  final Value<double?> totalAmount;
  final Value<double?> extractedTotal;
  final Value<String> currency;
  final Value<String?> category;
  final Value<int> warrantyMonths;
  final Value<String?> warrantyExpiryDate;
  final Value<String> status;
  final Value<String?> imageKeys;
  final Value<String?> thumbnailKeys;
  final Value<String?> ocrRawText;
  final Value<int> llmConfidence;
  final Value<String?> userNotes;
  final Value<String?> userTags;
  final Value<bool> isFavorite;
  final Value<String?> userEditedFields;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> version;
  final Value<String?> deletedAt;
  final Value<String> syncStatus;
  final Value<String?> lastSyncedAt;
  final Value<String?> localImagePaths;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.receiptId = const Value.absent(),
    this.userId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.extractedMerchantName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.extractedDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.extractedTotal = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.warrantyExpiryDate = const Value.absent(),
    this.status = const Value.absent(),
    this.imageKeys = const Value.absent(),
    this.thumbnailKeys = const Value.absent(),
    this.ocrRawText = const Value.absent(),
    this.llmConfidence = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.userTags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.userEditedFields = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.localImagePaths = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String receiptId,
    required String userId,
    this.storeName = const Value.absent(),
    this.extractedMerchantName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.extractedDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.extractedTotal = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.warrantyExpiryDate = const Value.absent(),
    this.status = const Value.absent(),
    this.imageKeys = const Value.absent(),
    this.thumbnailKeys = const Value.absent(),
    this.ocrRawText = const Value.absent(),
    this.llmConfidence = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.userTags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.userEditedFields = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.localImagePaths = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : receiptId = Value(receiptId),
        userId = Value(userId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ReceiptEntry> custom({
    Expression<String>? receiptId,
    Expression<String>? userId,
    Expression<String>? storeName,
    Expression<String>? extractedMerchantName,
    Expression<String>? purchaseDate,
    Expression<String>? extractedDate,
    Expression<double>? totalAmount,
    Expression<double>? extractedTotal,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<int>? warrantyMonths,
    Expression<String>? warrantyExpiryDate,
    Expression<String>? status,
    Expression<String>? imageKeys,
    Expression<String>? thumbnailKeys,
    Expression<String>? ocrRawText,
    Expression<int>? llmConfidence,
    Expression<String>? userNotes,
    Expression<String>? userTags,
    Expression<bool>? isFavorite,
    Expression<String>? userEditedFields,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? version,
    Expression<String>? deletedAt,
    Expression<String>? syncStatus,
    Expression<String>? lastSyncedAt,
    Expression<String>? localImagePaths,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (receiptId != null) 'receipt_id': receiptId,
      if (userId != null) 'user_id': userId,
      if (storeName != null) 'store_name': storeName,
      if (extractedMerchantName != null)
        'extracted_merchant_name': extractedMerchantName,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (extractedDate != null) 'extracted_date': extractedDate,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (extractedTotal != null) 'extracted_total': extractedTotal,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (warrantyMonths != null) 'warranty_months': warrantyMonths,
      if (warrantyExpiryDate != null)
        'warranty_expiry_date': warrantyExpiryDate,
      if (status != null) 'status': status,
      if (imageKeys != null) 'image_keys': imageKeys,
      if (thumbnailKeys != null) 'thumbnail_keys': thumbnailKeys,
      if (ocrRawText != null) 'ocr_raw_text': ocrRawText,
      if (llmConfidence != null) 'llm_confidence': llmConfidence,
      if (userNotes != null) 'user_notes': userNotes,
      if (userTags != null) 'user_tags': userTags,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (userEditedFields != null) 'user_edited_fields': userEditedFields,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (localImagePaths != null) 'local_image_paths': localImagePaths,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith(
      {Value<String>? receiptId,
      Value<String>? userId,
      Value<String?>? storeName,
      Value<String?>? extractedMerchantName,
      Value<String?>? purchaseDate,
      Value<String?>? extractedDate,
      Value<double?>? totalAmount,
      Value<double?>? extractedTotal,
      Value<String>? currency,
      Value<String?>? category,
      Value<int>? warrantyMonths,
      Value<String?>? warrantyExpiryDate,
      Value<String>? status,
      Value<String?>? imageKeys,
      Value<String?>? thumbnailKeys,
      Value<String?>? ocrRawText,
      Value<int>? llmConfidence,
      Value<String?>? userNotes,
      Value<String?>? userTags,
      Value<bool>? isFavorite,
      Value<String?>? userEditedFields,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? version,
      Value<String?>? deletedAt,
      Value<String>? syncStatus,
      Value<String?>? lastSyncedAt,
      Value<String?>? localImagePaths,
      Value<int>? rowid}) {
    return ReceiptsCompanion(
      receiptId: receiptId ?? this.receiptId,
      userId: userId ?? this.userId,
      storeName: storeName ?? this.storeName,
      extractedMerchantName:
          extractedMerchantName ?? this.extractedMerchantName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      extractedDate: extractedDate ?? this.extractedDate,
      totalAmount: totalAmount ?? this.totalAmount,
      extractedTotal: extractedTotal ?? this.extractedTotal,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      status: status ?? this.status,
      imageKeys: imageKeys ?? this.imageKeys,
      thumbnailKeys: thumbnailKeys ?? this.thumbnailKeys,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      llmConfidence: llmConfidence ?? this.llmConfidence,
      userNotes: userNotes ?? this.userNotes,
      userTags: userTags ?? this.userTags,
      isFavorite: isFavorite ?? this.isFavorite,
      userEditedFields: userEditedFields ?? this.userEditedFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (extractedMerchantName.present) {
      map['extracted_merchant_name'] =
          Variable<String>(extractedMerchantName.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (extractedDate.present) {
      map['extracted_date'] = Variable<String>(extractedDate.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (extractedTotal.present) {
      map['extracted_total'] = Variable<double>(extractedTotal.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (warrantyMonths.present) {
      map['warranty_months'] = Variable<int>(warrantyMonths.value);
    }
    if (warrantyExpiryDate.present) {
      map['warranty_expiry_date'] = Variable<String>(warrantyExpiryDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (imageKeys.present) {
      map['image_keys'] = Variable<String>(imageKeys.value);
    }
    if (thumbnailKeys.present) {
      map['thumbnail_keys'] = Variable<String>(thumbnailKeys.value);
    }
    if (ocrRawText.present) {
      map['ocr_raw_text'] = Variable<String>(ocrRawText.value);
    }
    if (llmConfidence.present) {
      map['llm_confidence'] = Variable<int>(llmConfidence.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (userTags.present) {
      map['user_tags'] = Variable<String>(userTags.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (userEditedFields.present) {
      map['user_edited_fields'] = Variable<String>(userEditedFields.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<String>(lastSyncedAt.value);
    }
    if (localImagePaths.present) {
      map['local_image_paths'] = Variable<String>(localImagePaths.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('receiptId: $receiptId, ')
          ..write('userId: $userId, ')
          ..write('storeName: $storeName, ')
          ..write('extractedMerchantName: $extractedMerchantName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('extractedDate: $extractedDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('extractedTotal: $extractedTotal, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('warrantyExpiryDate: $warrantyExpiryDate, ')
          ..write('status: $status, ')
          ..write('imageKeys: $imageKeys, ')
          ..write('thumbnailKeys: $thumbnailKeys, ')
          ..write('ocrRawText: $ocrRawText, ')
          ..write('llmConfidence: $llmConfidence, ')
          ..write('userNotes: $userNotes, ')
          ..write('userTags: $userTags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('userEditedFields: $userEditedFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('localImagePaths: $localImagePaths, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isHiddenMeta =
      const VerificationMeta('isHidden');
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
      'is_hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, isDefault, isHidden, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('is_hidden')) {
      context.handle(_isHiddenMeta,
          isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isHidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hidden'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryEntry extends DataClass implements Insertable<CategoryEntry> {
  /// Auto-incrementing local primary key.
  final int id;

  /// Category display name. Must be unique.
  final String name;

  /// Icon identifier that maps to a Flutter icon in the UI.
  final String icon;

  /// Whether this is one of the 10 built-in default categories.
  /// Default categories cannot be deleted, only hidden.
  final bool isDefault;

  /// Whether the user has hidden this category from the picker.
  /// Hidden categories still exist for receipts already assigned to them.
  final bool isHidden;

  /// Display order in the category picker UI.
  final int sortOrder;
  const CategoryEntry(
      {required this.id,
      required this.name,
      required this.icon,
      required this.isDefault,
      required this.isHidden,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      isDefault: Value(isDefault),
      isHidden: Value(isHidden),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isHidden': serializer.toJson<bool>(isHidden),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryEntry copyWith(
          {int? id,
          String? name,
          String? icon,
          bool? isDefault,
          bool? isHidden,
          int? sortOrder}) =>
      CategoryEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        isDefault: isDefault ?? this.isDefault,
        isHidden: isHidden ?? this.isHidden,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  CategoryEntry copyWithCompanion(CategoriesCompanion data) {
    return CategoryEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, isDefault, isHidden, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.isDefault == this.isDefault &&
          other.isHidden == this.isHidden &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<bool> isDefault;
  final Value<bool> isHidden;
  final Value<int> sortOrder;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CategoryEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<bool>? isDefault,
    Expression<bool>? isHidden,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (isDefault != null) 'is_default': isDefault,
      if (isHidden != null) 'is_hidden': isHidden,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<bool>? isDefault,
      Value<bool>? isHidden,
      Value<int>? sortOrder}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _receiptIdMeta =
      const VerificationMeta('receiptId');
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
      'receipt_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        receiptId,
        operation,
        payload,
        createdAt,
        retryCount,
        lastError,
        priority
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(_receiptIdMeta,
          receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta));
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      receiptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  /// Auto-incrementing local primary key.
  final int id;

  /// The receipt this operation applies to.
  final String receiptId;

  /// Operation type: create, update, delete, upload_image, or refine_ocr.
  final String operation;

  /// JSON-encoded operation payload.
  /// - For create/update: full receipt data.
  /// - For upload_image: local file path.
  /// - For delete: null (receipt_id is sufficient).
  final String? payload;

  /// ISO 8601 datetime when the operation was queued.
  final String createdAt;

  /// Number of failed sync attempts. Abandoned after 10 retries.
  final int retryCount;

  /// Error message from the most recent failed attempt.
  final String? lastError;

  /// Processing priority. Higher values are processed first.
  /// Image uploads have lower priority than data sync.
  final int priority;
  const SyncQueueEntry(
      {required this.id,
      required this.receiptId,
      required this.operation,
      this.payload,
      required this.createdAt,
      required this.retryCount,
      this.lastError,
      required this.priority});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['priority'] = Variable<int>(priority);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      operation: Value(operation),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      priority: Value(priority),
    );
  }

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<String>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'priority': serializer.toJson<int>(priority),
    };
  }

  SyncQueueEntry copyWith(
          {int? id,
          String? receiptId,
          String? operation,
          Value<String?> payload = const Value.absent(),
          String? createdAt,
          int? retryCount,
          Value<String?> lastError = const Value.absent(),
          int? priority}) =>
      SyncQueueEntry(
        id: id ?? this.id,
        receiptId: receiptId ?? this.receiptId,
        operation: operation ?? this.operation,
        payload: payload.present ? payload.value : this.payload,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        priority: priority ?? this.priority,
      );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, receiptId, operation, payload, createdAt,
      retryCount, lastError, priority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.priority == this.priority);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> receiptId;
  final Value<String> operation;
  final Value<String?> payload;
  final Value<String> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> priority;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.priority = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String receiptId,
    required String operation,
    this.payload = const Value.absent(),
    required String createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.priority = const Value.absent(),
  })  : receiptId = Value(receiptId),
        operation = Value(operation),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? receiptId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (priority != null) 'priority': priority,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? receiptId,
      Value<String>? operation,
      Value<String?>? payload,
      Value<String>? createdAt,
      Value<int>? retryCount,
      Value<String?>? lastError,
      Value<int>? priority}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  /// Setting identifier. Primary key.
  final String key;

  /// Setting value, stored as a string.
  final String? value;
  const SettingEntry({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory SettingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  SettingEntry copyWith(
          {String? key, Value<String?> value = const Value.absent()}) =>
      SettingEntry(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  SettingEntry copyWithCompanion(SettingsCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final ReceiptsDao receiptsDao = ReceiptsDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [receipts, categories, syncQueue, settings];
}

typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  required String receiptId,
  required String userId,
  Value<String?> storeName,
  Value<String?> extractedMerchantName,
  Value<String?> purchaseDate,
  Value<String?> extractedDate,
  Value<double?> totalAmount,
  Value<double?> extractedTotal,
  Value<String> currency,
  Value<String?> category,
  Value<int> warrantyMonths,
  Value<String?> warrantyExpiryDate,
  Value<String> status,
  Value<String?> imageKeys,
  Value<String?> thumbnailKeys,
  Value<String?> ocrRawText,
  Value<int> llmConfidence,
  Value<String?> userNotes,
  Value<String?> userTags,
  Value<bool> isFavorite,
  Value<String?> userEditedFields,
  required String createdAt,
  required String updatedAt,
  Value<int> version,
  Value<String?> deletedAt,
  Value<String> syncStatus,
  Value<String?> lastSyncedAt,
  Value<String?> localImagePaths,
  Value<int> rowid,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<String> receiptId,
  Value<String> userId,
  Value<String?> storeName,
  Value<String?> extractedMerchantName,
  Value<String?> purchaseDate,
  Value<String?> extractedDate,
  Value<double?> totalAmount,
  Value<double?> extractedTotal,
  Value<String> currency,
  Value<String?> category,
  Value<int> warrantyMonths,
  Value<String?> warrantyExpiryDate,
  Value<String> status,
  Value<String?> imageKeys,
  Value<String?> thumbnailKeys,
  Value<String?> ocrRawText,
  Value<int> llmConfidence,
  Value<String?> userNotes,
  Value<String?> userTags,
  Value<bool> isFavorite,
  Value<String?> userEditedFields,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> version,
  Value<String?> deletedAt,
  Value<String> syncStatus,
  Value<String?> lastSyncedAt,
  Value<String?> localImagePaths,
  Value<int> rowid,
});

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storeName => $composableBuilder(
      column: $table.storeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractedMerchantName => $composableBuilder(
      column: $table.extractedMerchantName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractedDate => $composableBuilder(
      column: $table.extractedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get extractedTotal => $composableBuilder(
      column: $table.extractedTotal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get warrantyMonths => $composableBuilder(
      column: $table.warrantyMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get warrantyExpiryDate => $composableBuilder(
      column: $table.warrantyExpiryDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageKeys => $composableBuilder(
      column: $table.imageKeys, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailKeys => $composableBuilder(
      column: $table.thumbnailKeys, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrRawText => $composableBuilder(
      column: $table.ocrRawText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get llmConfidence => $composableBuilder(
      column: $table.llmConfidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userTags => $composableBuilder(
      column: $table.userTags, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userEditedFields => $composableBuilder(
      column: $table.userEditedFields,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localImagePaths => $composableBuilder(
      column: $table.localImagePaths,
      builder: (column) => ColumnFilters(column));
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storeName => $composableBuilder(
      column: $table.storeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractedMerchantName => $composableBuilder(
      column: $table.extractedMerchantName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractedDate => $composableBuilder(
      column: $table.extractedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get extractedTotal => $composableBuilder(
      column: $table.extractedTotal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get warrantyMonths => $composableBuilder(
      column: $table.warrantyMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get warrantyExpiryDate => $composableBuilder(
      column: $table.warrantyExpiryDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageKeys => $composableBuilder(
      column: $table.imageKeys, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailKeys => $composableBuilder(
      column: $table.thumbnailKeys,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrRawText => $composableBuilder(
      column: $table.ocrRawText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get llmConfidence => $composableBuilder(
      column: $table.llmConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userTags => $composableBuilder(
      column: $table.userTags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userEditedFields => $composableBuilder(
      column: $table.userEditedFields,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localImagePaths => $composableBuilder(
      column: $table.localImagePaths,
      builder: (column) => ColumnOrderings(column));
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get extractedMerchantName => $composableBuilder(
      column: $table.extractedMerchantName, builder: (column) => column);

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate, builder: (column) => column);

  GeneratedColumn<String> get extractedDate => $composableBuilder(
      column: $table.extractedDate, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get extractedTotal => $composableBuilder(
      column: $table.extractedTotal, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get warrantyMonths => $composableBuilder(
      column: $table.warrantyMonths, builder: (column) => column);

  GeneratedColumn<String> get warrantyExpiryDate => $composableBuilder(
      column: $table.warrantyExpiryDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get imageKeys =>
      $composableBuilder(column: $table.imageKeys, builder: (column) => column);

  GeneratedColumn<String> get thumbnailKeys => $composableBuilder(
      column: $table.thumbnailKeys, builder: (column) => column);

  GeneratedColumn<String> get ocrRawText => $composableBuilder(
      column: $table.ocrRawText, builder: (column) => column);

  GeneratedColumn<int> get llmConfidence => $composableBuilder(
      column: $table.llmConfidence, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<String> get userTags =>
      $composableBuilder(column: $table.userTags, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get userEditedFields => $composableBuilder(
      column: $table.userEditedFields, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<String> get localImagePaths => $composableBuilder(
      column: $table.localImagePaths, builder: (column) => column);
}

class $$ReceiptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReceiptsTable,
    ReceiptEntry,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (ReceiptEntry, BaseReferences<_$AppDatabase, $ReceiptsTable, ReceiptEntry>),
    ReceiptEntry,
    PrefetchHooks Function()> {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> receiptId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> storeName = const Value.absent(),
            Value<String?> extractedMerchantName = const Value.absent(),
            Value<String?> purchaseDate = const Value.absent(),
            Value<String?> extractedDate = const Value.absent(),
            Value<double?> totalAmount = const Value.absent(),
            Value<double?> extractedTotal = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> warrantyMonths = const Value.absent(),
            Value<String?> warrantyExpiryDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> imageKeys = const Value.absent(),
            Value<String?> thumbnailKeys = const Value.absent(),
            Value<String?> ocrRawText = const Value.absent(),
            Value<int> llmConfidence = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<String?> userTags = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String?> userEditedFields = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> lastSyncedAt = const Value.absent(),
            Value<String?> localImagePaths = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion(
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
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String receiptId,
            required String userId,
            Value<String?> storeName = const Value.absent(),
            Value<String?> extractedMerchantName = const Value.absent(),
            Value<String?> purchaseDate = const Value.absent(),
            Value<String?> extractedDate = const Value.absent(),
            Value<double?> totalAmount = const Value.absent(),
            Value<double?> extractedTotal = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> warrantyMonths = const Value.absent(),
            Value<String?> warrantyExpiryDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> imageKeys = const Value.absent(),
            Value<String?> thumbnailKeys = const Value.absent(),
            Value<String?> ocrRawText = const Value.absent(),
            Value<int> llmConfidence = const Value.absent(),
            Value<String?> userNotes = const Value.absent(),
            Value<String?> userTags = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String?> userEditedFields = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> version = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String?> lastSyncedAt = const Value.absent(),
            Value<String?> localImagePaths = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion.insert(
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
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReceiptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReceiptsTable,
    ReceiptEntry,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (ReceiptEntry, BaseReferences<_$AppDatabase, $ReceiptsTable, ReceiptEntry>),
    ReceiptEntry,
    PrefetchHooks Function()>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  Value<bool> isDefault,
  Value<bool> isHidden,
  Value<int> sortOrder,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<bool> isDefault,
  Value<bool> isHidden,
  Value<int> sortOrder,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHidden => $composableBuilder(
      column: $table.isHidden, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHidden => $composableBuilder(
      column: $table.isHidden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryEntry,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (
      CategoryEntry,
      BaseReferences<_$AppDatabase, $CategoriesTable, CategoryEntry>
    ),
    CategoryEntry,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            icon: icon,
            isDefault: isDefault,
            isHidden: isHidden,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> icon = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            isDefault: isDefault,
            isHidden: isHidden,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryEntry,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (
      CategoryEntry,
      BaseReferences<_$AppDatabase, $CategoriesTable, CategoryEntry>
    ),
    CategoryEntry,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String receiptId,
  required String operation,
  Value<String?> payload,
  required String createdAt,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<int> priority,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> receiptId,
  Value<String> operation,
  Value<String?> payload,
  Value<String> createdAt,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<int> priority,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueEntry,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueEntry,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>
    ),
    SyncQueueEntry,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> receiptId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> priority = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            receiptId: receiptId,
            operation: operation,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            lastError: lastError,
            priority: priority,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String receiptId,
            required String operation,
            Value<String?> payload = const Value.absent(),
            required String createdAt,
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> priority = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            receiptId: receiptId,
            operation: operation,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            lastError: lastError,
            priority: priority,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueEntry,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueEntry,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>
    ),
    SyncQueueEntry,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingEntry,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingEntry, BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>),
    SettingEntry,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingEntry,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingEntry, BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>),
    SettingEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
