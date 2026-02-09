import 'package:equatable/equatable.dart';
import '../../domain/entities/receipt.dart';

class TrashState extends Equatable {
  const TrashState({
    this.receipts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Receipt> receipts;
  final bool isLoading;
  final String? error;

  TrashState copyWith({
    List<Receipt>? receipts,
    bool? isLoading,
    String? error,
  }) {
    return TrashState(
      receipts: receipts ?? this.receipts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [receipts, isLoading, error];
}
