import 'package:equatable/equatable.dart';

sealed class VaultEvent extends Equatable {
  const VaultEvent();

  @override
  List<Object?> get props => [];
}

class VaultLoadRequested extends VaultEvent {
  const VaultLoadRequested(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class VaultReceiptDeleted extends VaultEvent {
  const VaultReceiptDeleted(this.receiptId);
  final String receiptId;

  @override
  List<Object?> get props => [receiptId];
}

class VaultReceiptFavoriteToggled extends VaultEvent {
  const VaultReceiptFavoriteToggled({
    required this.receiptId,
    required this.isFavorite,
  });
  final String receiptId;
  final bool isFavorite;

  @override
  List<Object?> get props => [receiptId, isFavorite];
}

class VaultReceiptStatusChanged extends VaultEvent {
  const VaultReceiptStatusChanged({
    required this.receiptId,
    required this.status,
  });
  final String receiptId;
  final String status;

  @override
  List<Object?> get props => [receiptId, status];
}

class VaultReceiptUpdated extends VaultEvent {
  const VaultReceiptUpdated(this.receipt);
  final dynamic receipt;

  @override
  List<Object?> get props => [receipt];
}
