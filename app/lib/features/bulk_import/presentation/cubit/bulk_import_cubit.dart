import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../receipt/domain/entities/image_data.dart';
import '../../../receipt/domain/entities/receipt.dart';
import '../../../receipt/domain/repositories/receipt_repository.dart';
import '../../../receipt/domain/services/image_pipeline_service.dart';
import '../../../receipt/domain/services/ocr_service.dart';
import '../../domain/services/gallery_scanner_service.dart';
import 'bulk_import_state.dart';

class BulkImportCubit extends Cubit<BulkImportState> {
  BulkImportCubit({
    required GalleryScannerService galleryScannerService,
    required ImagePipelineService imagePipelineService,
    required OcrService ocrService,
    required ReceiptRepository receiptRepository,
  })  : _galleryScannerService = galleryScannerService,
        _imagePipelineService = imagePipelineService,
        _ocrService = ocrService,
        _receiptRepository = receiptRepository,
        super(const BulkImportInitial());

  final GalleryScannerService _galleryScannerService;
  final ImagePipelineService _imagePipelineService;
  final OcrService _ocrService;
  final ReceiptRepository _receiptRepository;

  Future<void> scanGallery() async {
    emit(const BulkImportScanning());

    try {
      final hasPermission = await _galleryScannerService.hasPermission();
      if (!hasPermission) {
        final granted = await _galleryScannerService.requestPermission();
        if (!granted) {
          emit(const BulkImportPermissionDenied());
          return;
        }
      }

      final candidates = await _galleryScannerService.scanForReceipts();

      emit(BulkImportCandidatesReady(
        candidates: candidates,
        selectedIds: candidates.map((c) => c.id).toSet(),
      ));
    } catch (e) {
      emit(BulkImportError(message: e.toString()));
    }
  }

  void toggleSelection(String id) {
    final currentState = state;
    if (currentState is! BulkImportCandidatesReady) return;

    final updatedIds = Set<String>.from(currentState.selectedIds);
    if (updatedIds.contains(id)) {
      updatedIds.remove(id);
    } else {
      updatedIds.add(id);
    }

    emit(BulkImportCandidatesReady(
      candidates: currentState.candidates,
      selectedIds: updatedIds,
    ));
  }

  void selectAll() {
    final currentState = state;
    if (currentState is! BulkImportCandidatesReady) return;

    emit(BulkImportCandidatesReady(
      candidates: currentState.candidates,
      selectedIds: currentState.candidates.map((c) => c.id).toSet(),
    ));
  }

  void deselectAll() {
    final currentState = state;
    if (currentState is! BulkImportCandidatesReady) return;

    emit(BulkImportCandidatesReady(
      candidates: currentState.candidates,
      selectedIds: const {},
    ));
  }

  Future<void> importSelected(String userId) async {
    final currentState = state;
    if (currentState is! BulkImportCandidatesReady) return;

    final selectedCandidates = currentState.candidates
        .where((c) => currentState.selectedIds.contains(c.id))
        .toList();

    if (selectedCandidates.isEmpty) return;

    final total = selectedCandidates.length;
    const uuid = Uuid();

    for (var i = 0; i < total; i++) {
      emit(BulkImportProcessing(current: i + 1, total: total));

      try {
        final candidate = selectedCandidates[i];
        final file = File(candidate.localPath);
        final sizeBytes = await file.length();

        // Create ImageData from candidate
        final imageData = ImageData(
          id: uuid.v4(),
          localPath: candidate.localPath,
          sizeBytes: sizeBytes,
          mimeType: 'image/jpeg',
          width: candidate.width,
          height: candidate.height,
        );

        // Process image (compress + strip EXIF + thumbnail)
        final processed = await _imagePipelineService.processImage(imageData);

        // Run OCR
        final ocrResult =
            await _ocrService.recognizeText(processed.localPath);

        // Build receipt
        final now = DateTime.now().toIso8601String();
        final receipt = Receipt(
          receiptId: uuid.v4(),
          userId: userId,
          storeName: ocrResult.extractedStoreName,
          extractedMerchantName: ocrResult.extractedStoreName,
          purchaseDate: ocrResult.extractedDate,
          extractedDate: ocrResult.extractedDate,
          totalAmount: ocrResult.extractedTotal,
          extractedTotal: ocrResult.extractedTotal,
          currency: ocrResult.extractedCurrency ?? 'EUR',
          ocrRawText: ocrResult.rawText,
          localImagePaths: [processed.localPath],
          thumbnailKeys:
              processed.thumbnailPath != null ? [processed.thumbnailPath!] : [],
          createdAt: now,
          updatedAt: now,
        );

        await _receiptRepository.saveReceipt(receipt);
      } catch (_) {
        // Skip individual failures, continue with remaining
      }
    }

    emit(BulkImportComplete(count: total));
  }
}
