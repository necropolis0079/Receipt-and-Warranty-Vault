import 'package:equatable/equatable.dart';

sealed class ExpiringEvent extends Equatable {
  const ExpiringEvent();

  @override
  List<Object?> get props => [];
}

class ExpiringLoadRequested extends ExpiringEvent {
  const ExpiringLoadRequested(this.userId, {this.daysAhead = 30});
  final String userId;
  final int daysAhead;

  @override
  List<Object?> get props => [userId, daysAhead];
}

class ExpiringRefreshRequested extends ExpiringEvent {
  const ExpiringRefreshRequested();
}
