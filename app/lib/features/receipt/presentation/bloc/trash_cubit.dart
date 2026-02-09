import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import 'trash_state.dart';

/// Cubit managing the trash/deleted receipts screen.
class TrashCubit extends Cubit<TrashState> {
  TrashCubit({
    required ReceiptRepository receiptRepository,
    required String userId,
  })  : _receiptRepository = receiptRepository,
        _userId = userId,
        super(const TrashState());

  final ReceiptRepository _receiptRepository;
  final String _userId;
  StreamSubscription<List<Receipt>>? _subscription;

  /// Start watching deleted receipts.
  void loadDeleted() {
    emit(state.copyWith(isLoading: true, error: null));
    _subscription?.cancel();
    _subscription = _receiptRepository
        .watchByStatus(_userId, ReceiptStatus.deleted)
        .listen(
      (receipts) {
        emit(state.copyWith(receipts: receipts, isLoading: false));
      },
      onError: (Object error) {
        emit(state.copyWith(isLoading: false, error: error.toString()));
      },
    );
  }

  /// Restore a receipt from trash to active status.
  Future<void> restoreReceipt(String receiptId) async {
    try {
      await _receiptRepository.restoreReceipt(receiptId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Permanently delete a receipt.
  Future<void> permanentlyDelete(String receiptId) async {
    try {
      await _receiptRepository.hardDelete(receiptId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
