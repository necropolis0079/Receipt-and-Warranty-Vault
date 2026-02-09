import 'package:equatable/equatable.dart';

import '../../domain/entities/receipt.dart';

sealed class VaultState extends Equatable {
  const VaultState();

  @override
  List<Object?> get props => [];
}

class VaultInitial extends VaultState {
  const VaultInitial();
}

class VaultLoading extends VaultState {
  const VaultLoading();
}

class VaultLoaded extends VaultState {
  const VaultLoaded({
    required this.receipts,
    required this.activeCount,
  });
  final List<Receipt> receipts;
  final int activeCount;

  @override
  List<Object?> get props => [receipts, activeCount];
}

class VaultEmpty extends VaultState {
  const VaultEmpty();
}

class VaultError extends VaultState {
  const VaultError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
