import 'package:equatable/equatable.dart';

import '../../../receipt/domain/entities/receipt.dart';

sealed class ExpiringState extends Equatable {
  const ExpiringState();

  @override
  List<Object?> get props => [];
}

class ExpiringInitial extends ExpiringState {
  const ExpiringInitial();
}

class ExpiringLoading extends ExpiringState {
  const ExpiringLoading();
}

class ExpiringLoaded extends ExpiringState {
  const ExpiringLoaded({
    required this.expiringSoon,
    required this.expired,
  });
  final List<Receipt> expiringSoon;
  final List<Receipt> expired;

  @override
  List<Object?> get props => [expiringSoon, expired];
}

class ExpiringEmpty extends ExpiringState {
  const ExpiringEmpty();
}

class ExpiringError extends ExpiringState {
  const ExpiringError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
