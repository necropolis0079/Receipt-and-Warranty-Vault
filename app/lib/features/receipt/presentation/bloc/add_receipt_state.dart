import 'package:equatable/equatable.dart';

import '../../domain/entities/image_data.dart';
import '../../domain/entities/ocr_result.dart';

sealed class AddReceiptState extends Equatable {
  const AddReceiptState();

  @override
  List<Object?> get props => [];
}

/// The type of permission that was denied.
enum PermissionType { camera, gallery }

/// A required permission was denied by the user.
class AddReceiptPermissionDenied extends AddReceiptState {
  const AddReceiptPermissionDenied(this.permissionType);
  final PermissionType permissionType;

  @override
  List<Object?> get props => [permissionType];
}

/// Initial state — no images captured yet.
class AddReceiptInitial extends AddReceiptState {
  const AddReceiptInitial();
}

/// Camera or picker is active, waiting for user to capture/select.
class AddReceiptCapturing extends AddReceiptState {
  const AddReceiptCapturing();
}

/// Images are ready for review before OCR.
class AddReceiptImagesReady extends AddReceiptState {
  const AddReceiptImagesReady(this.images);
  final List<ImageData> images;

  @override
  List<Object?> get props => [images];
}

/// OCR is running on the selected images.
class AddReceiptProcessingOcr extends AddReceiptState {
  const AddReceiptProcessingOcr(this.images);
  final List<ImageData> images;

  @override
  List<Object?> get props => [images];
}

/// OCR is complete — form fields are ready for review and editing.
class AddReceiptFieldsReady extends AddReceiptState {
  const AddReceiptFieldsReady({
    required this.images,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.currency = 'EUR',
    this.category,
    this.warrantyMonths = 0,
    this.notes,
    this.ocrResult,
    this.validationErrors = const {},
  });

  final List<ImageData> images;
  final String? storeName;
  final String? purchaseDate;
  final double? totalAmount;
  final String currency;
  final String? category;
  final int warrantyMonths;
  final String? notes;
  final OcrResult? ocrResult;
  final Map<String, String> validationErrors;

  AddReceiptFieldsReady copyWith({
    List<ImageData>? images,
    String? storeName,
    String? purchaseDate,
    double? totalAmount,
    String? currency,
    String? category,
    int? warrantyMonths,
    String? notes,
    OcrResult? ocrResult,
    Map<String, String>? validationErrors,
  }) {
    return AddReceiptFieldsReady(
      images: images ?? this.images,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      notes: notes ?? this.notes,
      ocrResult: ocrResult ?? this.ocrResult,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [
        images,
        storeName,
        purchaseDate,
        totalAmount,
        currency,
        category,
        warrantyMonths,
        notes,
        ocrResult,
        validationErrors,
      ];
}

/// Receipt is being persisted.
class AddReceiptSaving extends AddReceiptState {
  const AddReceiptSaving(this.images);
  final List<ImageData> images;

  @override
  List<Object?> get props => [images];
}

/// Receipt was saved successfully.
class AddReceiptSaved extends AddReceiptState {
  const AddReceiptSaved(this.receiptId);
  final String receiptId;

  @override
  List<Object?> get props => [receiptId];
}

/// An error occurred during any step.
class AddReceiptError extends AddReceiptState {
  const AddReceiptError(this.message, {this.previousState});
  final String message;
  final Object? previousState;

  @override
  List<Object?> get props => [message, previousState];
}
