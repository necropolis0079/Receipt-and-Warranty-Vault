import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import 'vault_event.dart';
import 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  VaultBloc({required ReceiptRepository receiptRepository})
      : _receiptRepository = receiptRepository,
        super(const VaultInitial()) {
    on<VaultLoadRequested>(_onLoadRequested);
    on<VaultReceiptDeleted>(_onReceiptDeleted);
    on<VaultReceiptFavoriteToggled>(_onFavoriteToggled);
    on<VaultReceiptStatusChanged>(_onStatusChanged);
    on<VaultReceiptUpdated>(_onReceiptUpdated);
  }

  final ReceiptRepository _receiptRepository;

  Future<void> _onLoadRequested(
    VaultLoadRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(const VaultLoading());
    try {
      await emit.forEach<List<Receipt>>(
        _receiptRepository.watchUserReceipts(event.userId),
        onData: (receipts) {
          if (receipts.isEmpty) {
            return const VaultEmpty();
          }
          final activeCount = receipts
              .where((r) => r.isWarrantyActive)
              .length;
          return VaultLoaded(receipts: receipts, activeCount: activeCount);
        },
        onError: (error, stackTrace) {
          return VaultError(error.toString());
        },
      );
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> _onReceiptDeleted(
    VaultReceiptDeleted event,
    Emitter<VaultState> emit,
  ) async {
    try {
      await _receiptRepository.softDelete(event.receiptId);
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> _onFavoriteToggled(
    VaultReceiptFavoriteToggled event,
    Emitter<VaultState> emit,
  ) async {
    try {
      final receipt = await _receiptRepository.getById(event.receiptId);
      if (receipt != null) {
        final updated = receipt.copyWith(
          isFavorite: event.isFavorite,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _receiptRepository.updateReceipt(updated);
      }
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> _onReceiptUpdated(
    VaultReceiptUpdated event,
    Emitter<VaultState> emit,
  ) async {
    try {
      final receipt = event.receipt as Receipt;
      await _receiptRepository.updateReceipt(receipt);
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> _onStatusChanged(
    VaultReceiptStatusChanged event,
    Emitter<VaultState> emit,
  ) async {
    try {
      final receipt = await _receiptRepository.getById(event.receiptId);
      if (receipt != null) {
        final status = ReceiptStatus.values.firstWhere(
          (s) => s.name == event.status,
          orElse: () => receipt.status,
        );
        final updated = receipt.copyWith(
          status: status,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _receiptRepository.updateReceipt(updated);
      }
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }
}
