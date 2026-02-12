import 'package:equatable/equatable.dart';

import '../../domain/entities/image_data.dart';

sealed class AddReceiptEvent extends Equatable {
  const AddReceiptEvent();

  @override
  List<Object?> get props => [];
}

/// Launch the device camera to capture a receipt photo.
class CaptureFromCamera extends AddReceiptEvent {
  const CaptureFromCamera();
}

/// Open the device gallery to pick one or more receipt images.
class ImportFromGallery extends AddReceiptEvent {
  const ImportFromGallery();
}

/// Open the file picker to import images or PDFs.
class ImportFromFiles extends AddReceiptEvent {
  const ImportFromFiles();
}

/// Directly provide a list of already-selected images.
class ImagesSelected extends AddReceiptEvent {
  const ImagesSelected(this.images);
  final List<ImageData> images;

  @override
  List<Object?> get props => [images];
}

/// Crop/rotate the image at [index] in the current image list.
class CropImage extends AddReceiptEvent {
  const CropImage(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Remove the image at [index] from the current image list.
class RemoveImage extends AddReceiptEvent {
  const RemoveImage(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Run OCR on all current images to extract receipt fields.
class ProcessOcr extends AddReceiptEvent {
  const ProcessOcr();
}

/// Update a single form field by name.
class UpdateField extends AddReceiptEvent {
  const UpdateField(this.fieldName, this.value);
  final String fieldName;
  final dynamic value;

  @override
  List<Object?> get props => [fieldName, value];
}

/// Set the receipt category.
class SetCategory extends AddReceiptEvent {
  const SetCategory(this.category);
  final String category;

  @override
  List<Object?> get props => [category];
}

/// Set the warranty duration in months.
class SetWarranty extends AddReceiptEvent {
  const SetWarranty(this.months);
  final int months;

  @override
  List<Object?> get props => [months];
}

/// Validate fields and save the receipt.
class SaveReceipt extends AddReceiptEvent {
  const SaveReceipt(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Save the receipt immediately, skipping field review validation.
class FastSave extends AddReceiptEvent {
  const FastSave(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Append additional images to the current fields-ready state.
class AddMoreImages extends AddReceiptEvent {
  const AddMoreImages(this.images);
  final List<ImageData> images;

  @override
  List<Object?> get props => [images];
}

/// Re-run OCR on the current image set.
class RetryOcr extends AddReceiptEvent {
  const RetryOcr();
}

/// Reset the form to its initial state.
class ResetForm extends AddReceiptEvent {
  const ResetForm();
}
