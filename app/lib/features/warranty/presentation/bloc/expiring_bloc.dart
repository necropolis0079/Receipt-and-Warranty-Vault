import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../receipt/domain/repositories/receipt_repository.dart';
import 'expiring_event.dart';
import 'expiring_state.dart';

class ExpiringBloc extends Bloc<ExpiringEvent, ExpiringState> {
  ExpiringBloc({required ReceiptRepository receiptRepository})
      : _receiptRepository = receiptRepository,
        super(const ExpiringInitial()) {
    on<ExpiringLoadRequested>(_onLoadRequested);
    on<ExpiringRefreshRequested>(_onRefreshRequested);
  }

  final ReceiptRepository _receiptRepository;
  String? _lastUserId;
  int _lastDaysAhead = 30;

  Future<void> _onLoadRequested(
    ExpiringLoadRequested event,
    Emitter<ExpiringState> emit,
  ) async {
    _lastUserId = event.userId;
    _lastDaysAhead = event.daysAhead;
    emit(const ExpiringLoading());
    try {
      final results = await Future.wait([
        _receiptRepository.getExpiringWarranties(event.userId, event.daysAhead),
        _receiptRepository.getExpiredWarranties(event.userId),
      ]);
      final expiringSoon = results[0];
      final expired = results[1];
      if (expiringSoon.isEmpty && expired.isEmpty) {
        emit(const ExpiringEmpty());
      } else {
        emit(ExpiringLoaded(expiringSoon: expiringSoon, expired: expired));
      }
    } catch (e) {
      emit(ExpiringError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    ExpiringRefreshRequested event,
    Emitter<ExpiringState> emit,
  ) async {
    if (_lastUserId != null) {
      add(ExpiringLoadRequested(_lastUserId!, daysAhead: _lastDaysAhead));
    }
  }
}
