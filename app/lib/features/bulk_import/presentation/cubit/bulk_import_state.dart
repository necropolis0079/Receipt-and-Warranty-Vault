import 'package:equatable/equatable.dart';

import '../../domain/entities/gallery_candidate.dart';

sealed class BulkImportState extends Equatable {
  const BulkImportState();

  @override
  List<Object?> get props => [];
}

final class BulkImportInitial extends BulkImportState {
  const BulkImportInitial();
}

final class BulkImportScanning extends BulkImportState {
  const BulkImportScanning();
}

final class BulkImportCandidatesReady extends BulkImportState {
  const BulkImportCandidatesReady({
    required this.candidates,
    required this.selectedIds,
  });

  final List<GalleryCandidate> candidates;
  final Set<String> selectedIds;

  @override
  List<Object?> get props => [candidates, selectedIds];
}

final class BulkImportProcessing extends BulkImportState {
  const BulkImportProcessing({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  List<Object?> get props => [current, total];
}

final class BulkImportComplete extends BulkImportState {
  const BulkImportComplete({required this.count});

  final int count;

  @override
  List<Object?> get props => [count];
}

final class BulkImportError extends BulkImportState {
  const BulkImportError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class BulkImportPermissionDenied extends BulkImportState {
  const BulkImportPermissionDenied();
}
