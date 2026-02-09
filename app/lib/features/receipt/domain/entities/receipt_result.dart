import 'receipt.dart';

sealed class ReceiptResult {
  const ReceiptResult();
}

class ReceiptSaveSuccess extends ReceiptResult {
  const ReceiptSaveSuccess(this.receipt);
  final Receipt receipt;
}

class ReceiptSaveFailure extends ReceiptResult {
  const ReceiptSaveFailure(this.message);
  final String message;
}

class ReceiptValidationError extends ReceiptResult {
  const ReceiptValidationError(this.fieldErrors);
  final Map<String, String> fieldErrors;
}
