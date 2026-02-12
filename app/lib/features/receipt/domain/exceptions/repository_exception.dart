/// Types of repository errors for categorized handling.
enum RepositoryErrorType {
  /// A database operation failed (insert, update, query).
  database,

  /// The requested entity was not found.
  notFound,

  /// An unexpected or uncategorized error.
  unknown,
}

/// Exception thrown by repository methods when a data operation fails.
///
/// Wraps the original exception [cause] with a user-friendly [message]
/// and a categorized [type] for downstream handling.
class RepositoryException implements Exception {
  const RepositoryException({
    required this.message,
    required this.type,
    this.cause,
  });

  /// User-friendly error description.
  final String message;

  /// Categorized error type.
  final RepositoryErrorType type;

  /// The original exception, if any.
  final Object? cause;

  @override
  String toString() => 'RepositoryException($type): $message';
}
