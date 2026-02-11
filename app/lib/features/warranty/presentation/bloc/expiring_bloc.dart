import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/daos/settings_dao.dart';
import '../../../../core/notifications/reminder_scheduler.dart';
import '../../../receipt/domain/repositories/receipt_repository.dart';
import 'expiring_event.dart';
import 'expiring_state.dart';

class ExpiringBloc extends Bloc<ExpiringEvent, ExpiringState> {
  ExpiringBloc({
    required ReceiptRepository receiptRepository,
    ReminderScheduler? reminderScheduler,
    SettingsDao? settingsDao,
  })  : _receiptRepository = receiptRepository,
        _reminderScheduler = reminderScheduler,
        _settingsDao = settingsDao,
        super(const ExpiringInitial()) {
    on<ExpiringLoadRequested>(_onLoadRequested);
    on<ExpiringRefreshRequested>(_onRefreshRequested);
  }

  final ReceiptRepository _receiptRepository;
  final ReminderScheduler? _reminderScheduler;
  final SettingsDao? _settingsDao;
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
      // Schedule reminders for all expiring-soon receipts (if enabled).
      if (_reminderScheduler != null && expiringSoon.isNotEmpty) {
        if (_settingsDao != null) {
          final enabled = await _settingsDao.getValue('reminders_enabled');
          if (enabled == 'false') {
            // Reminders disabled — skip scheduling.
          } else {
            await _reminderScheduler.scheduleForAll(expiringSoon);
          }
        } else {
          // No settings DAO — default to enabled.
          await _reminderScheduler.scheduleForAll(expiringSoon);
        }
      }

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
