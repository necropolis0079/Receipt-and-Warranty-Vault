import '../entities/receipt.dart';

/// Abstract service for exporting and sharing receipts.
abstract class ExportService {
  /// Share a single receipt as text with optional image attachments.
  Future<void> shareReceipt(Receipt receipt);

  /// Generate a formatted text summary of a receipt.
  String formatReceiptAsText(Receipt receipt);

  /// Export multiple receipts as a CSV string.
  String batchExportCsv(List<Receipt> receipts);

  /// Share a file by its path.
  Future<void> shareFile(String filePath, {String? mimeType});
}
