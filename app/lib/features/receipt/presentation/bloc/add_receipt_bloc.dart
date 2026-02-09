import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/image_data.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/services/image_pipeline_service.dart';
import '../../domain/services/ocr_service.dart';
import 'add_receipt_event.dart';
import 'add_receipt_state.dart';

class AddReceiptBloc extends Bloc<AddReceiptEvent, AddReceiptState> {
  AddReceiptBloc({
    required ImagePipelineService imagePipelineService,
    required OcrService ocrService,
    required ReceiptRepository receiptRepository,
    Uuid? uuid,
  })  : _imagePipeline = imagePipelineService,
        _ocrService = ocrService,
        _receiptRepository = receiptRepository,
        _uuid = uuid ?? const Uuid(),
        super(const AddReceiptInitial()) {
    on<CaptureFromCamera>(_onCaptureFromCamera);
    on<ImportFromGallery>(_onImportFromGallery);
    on<ImportFromFiles>(_onImportFromFiles);
    on<ImagesSelected>(_onImagesSelected);
    on<CropImage>(_onCropImage);
    on<RemoveImage>(_onRemoveImage);
    on<ProcessOcr>(_onProcessOcr);
    on<UpdateField>(_onUpdateField);
    on<SetCategory>(_onSetCategory);
    on<SetWarranty>(_onSetWarranty);
    on<SaveReceipt>(_onSaveReceipt);
    on<FastSave>(_onFastSave);
    on<ResetForm>(_onResetForm);
  }

  final ImagePipelineService _imagePipeline;
  final OcrService _ocrService;
  final ReceiptRepository _receiptRepository;
  final Uuid _uuid;

  Future<void> _onCaptureFromCamera(
    CaptureFromCamera event,
    Emitter<AddReceiptState> emit,
  ) async {
    emit(const AddReceiptCapturing());
    try {
      final image = await _imagePipeline.captureFromCamera();
      if (image == null) {
        emit(const AddReceiptInitial());
        return;
      }
      final processed = await _imagePipeline.processImage(image);
      emit(AddReceiptImagesReady([processed]));
    } catch (e) {
      emit(AddReceiptError(e.toString()));
    }
  }

  Future<void> _onImportFromGallery(
    ImportFromGallery event,
    Emitter<AddReceiptState> emit,
  ) async {
    emit(const AddReceiptCapturing());
    try {
      final images = await _imagePipeline.pickFromGallery();
      if (images.isEmpty) {
        emit(const AddReceiptInitial());
        return;
      }
      final processed = <ImageData>[];
      for (final img in images) {
        processed.add(await _imagePipeline.processImage(img));
      }
      emit(AddReceiptImagesReady(processed));
    } catch (e) {
      emit(AddReceiptError(e.toString()));
    }
  }

  Future<void> _onImportFromFiles(
    ImportFromFiles event,
    Emitter<AddReceiptState> emit,
  ) async {
    emit(const AddReceiptCapturing());
    try {
      final images = await _imagePipeline.pickFromFiles();
      if (images.isEmpty) {
        emit(const AddReceiptInitial());
        return;
      }
      final processed = <ImageData>[];
      for (final img in images) {
        processed.add(await _imagePipeline.processImage(img));
      }
      emit(AddReceiptImagesReady(processed));
    } catch (e) {
      emit(AddReceiptError(e.toString()));
    }
  }

  void _onImagesSelected(
    ImagesSelected event,
    Emitter<AddReceiptState> emit,
  ) {
    emit(AddReceiptImagesReady(event.images));
  }

  Future<void> _onCropImage(
    CropImage event,
    Emitter<AddReceiptState> emit,
  ) async {
    final currentImages = _currentImages;
    if (currentImages == null || event.index >= currentImages.length) return;

    try {
      final cropped =
          await _imagePipeline.cropImage(currentImages[event.index]);
      if (cropped == null) return;
      final updatedList = List<ImageData>.from(currentImages);
      updatedList[event.index] = cropped;
      emit(AddReceiptImagesReady(updatedList));
    } catch (e) {
      emit(AddReceiptError(e.toString(), previousState: state));
    }
  }

  void _onRemoveImage(
    RemoveImage event,
    Emitter<AddReceiptState> emit,
  ) {
    final currentImages = _currentImages;
    if (currentImages == null || event.index >= currentImages.length) return;

    final updatedList = List<ImageData>.from(currentImages)
      ..removeAt(event.index);
    if (updatedList.isEmpty) {
      emit(const AddReceiptInitial());
    } else {
      emit(AddReceiptImagesReady(updatedList));
    }
  }

  Future<void> _onProcessOcr(
    ProcessOcr event,
    Emitter<AddReceiptState> emit,
  ) async {
    final currentImages = _currentImages;
    if (currentImages == null || currentImages.isEmpty) return;

    emit(AddReceiptProcessingOcr(currentImages));
    try {
      final imagePaths = currentImages.map((img) => img.localPath).toList();
      final ocrResult = await _ocrService.recognizeMultipleImages(imagePaths);
      final parsed = _ocrService.parseRawText(ocrResult.rawText);

      emit(AddReceiptFieldsReady(
        images: currentImages,
        storeName: parsed.extractedStoreName,
        purchaseDate: parsed.extractedDate,
        totalAmount: parsed.extractedTotal,
        currency: parsed.extractedCurrency ?? 'EUR',
        ocrResult: parsed,
      ));
    } catch (e) {
      emit(AddReceiptError(e.toString(), previousState: state));
    }
  }

  void _onUpdateField(
    UpdateField event,
    Emitter<AddReceiptState> emit,
  ) {
    final currentState = state;
    if (currentState is! AddReceiptFieldsReady) return;

    switch (event.fieldName) {
      case 'storeName':
        emit(currentState.copyWith(storeName: event.value as String));
      case 'purchaseDate':
        emit(currentState.copyWith(purchaseDate: event.value as String));
      case 'totalAmount':
        emit(currentState.copyWith(totalAmount: event.value as double));
      case 'currency':
        emit(currentState.copyWith(currency: event.value as String));
      case 'category':
        emit(currentState.copyWith(category: event.value as String));
      case 'warrantyMonths':
        emit(currentState.copyWith(warrantyMonths: event.value as int));
      case 'notes':
        emit(currentState.copyWith(notes: event.value as String));
    }
  }

  void _onSetCategory(
    SetCategory event,
    Emitter<AddReceiptState> emit,
  ) {
    final currentState = state;
    if (currentState is! AddReceiptFieldsReady) return;
    emit(currentState.copyWith(category: event.category));
  }

  void _onSetWarranty(
    SetWarranty event,
    Emitter<AddReceiptState> emit,
  ) {
    final currentState = state;
    if (currentState is! AddReceiptFieldsReady) return;
    emit(currentState.copyWith(warrantyMonths: event.months));
  }

  Future<void> _onSaveReceipt(
    SaveReceipt event,
    Emitter<AddReceiptState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AddReceiptFieldsReady) return;

    // Validate required fields
    final errors = <String, String>{};
    if (currentState.images.isEmpty) {
      errors['images'] = 'At least one image is required';
    }

    if (errors.isNotEmpty) {
      emit(currentState.copyWith(validationErrors: errors));
      return;
    }

    emit(AddReceiptSaving(currentState.images));
    try {
      final receipt = _buildReceipt(
        userId: event.userId,
        fieldsState: currentState,
      );
      await _receiptRepository.saveReceipt(receipt);
      emit(AddReceiptSaved(receipt.receiptId));
    } catch (e) {
      emit(AddReceiptError(e.toString(), previousState: currentState));
    }
  }

  Future<void> _onFastSave(
    FastSave event,
    Emitter<AddReceiptState> emit,
  ) async {
    final currentImages = _currentImages;
    if (currentImages == null || currentImages.isEmpty) return;

    // Build a minimal FieldsReady state for building the receipt
    final fieldsState = state is AddReceiptFieldsReady
        ? state as AddReceiptFieldsReady
        : AddReceiptFieldsReady(images: currentImages);

    emit(AddReceiptSaving(currentImages));
    try {
      final receipt = _buildReceipt(
        userId: event.userId,
        fieldsState: fieldsState,
      );
      await _receiptRepository.saveReceipt(receipt);
      emit(AddReceiptSaved(receipt.receiptId));
    } catch (e) {
      emit(AddReceiptError(e.toString(), previousState: fieldsState));
    }
  }

  void _onResetForm(
    ResetForm event,
    Emitter<AddReceiptState> emit,
  ) {
    emit(const AddReceiptInitial());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extract the current image list from whatever state we are in.
  List<ImageData>? get _currentImages {
    final s = state;
    if (s is AddReceiptImagesReady) return s.images;
    if (s is AddReceiptProcessingOcr) return s.images;
    if (s is AddReceiptFieldsReady) return s.images;
    if (s is AddReceiptSaving) return s.images;
    return null;
  }

  /// Build a [Receipt] entity from the current field state.
  Receipt _buildReceipt({
    required String userId,
    required AddReceiptFieldsReady fieldsState,
  }) {
    final now = DateTime.now().toIso8601String();
    final receiptId = _uuid.v4();

    String? warrantyExpiryDate;
    if (fieldsState.warrantyMonths > 0 && fieldsState.purchaseDate != null) {
      final purchaseDateTime = DateTime.tryParse(fieldsState.purchaseDate!);
      if (purchaseDateTime != null) {
        final expiryDate = DateTime(
          purchaseDateTime.year,
          purchaseDateTime.month + fieldsState.warrantyMonths,
          purchaseDateTime.day,
        );
        warrantyExpiryDate = expiryDate.toIso8601String().split('T').first;
      }
    }

    return Receipt(
      receiptId: receiptId,
      userId: userId,
      storeName: fieldsState.storeName,
      purchaseDate: fieldsState.purchaseDate,
      totalAmount: fieldsState.totalAmount,
      currency: fieldsState.currency,
      category: fieldsState.category,
      warrantyMonths: fieldsState.warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate,
      ocrRawText: fieldsState.ocrResult?.rawText,
      userNotes: fieldsState.notes,
      localImagePaths:
          fieldsState.images.map((img) => img.localPath).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }
}
