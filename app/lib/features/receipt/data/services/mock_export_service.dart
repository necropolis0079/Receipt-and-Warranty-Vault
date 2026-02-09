import '../../domain/entities/receipt.dart';
import '../../domain/services/export_service.dart';

/// Mock implementation of [ExportService] for testing.
///
/// Records all calls for verification without platform dependencies.
class MockExportService implements ExportService {
  final List<Receipt> sharedReceipts = [];
  final List<String> sharedFiles = [];
  String? lastCsvOutput;

  @override
  Future<void> shareReceipt(Receipt receipt) async {
    sharedReceipts.add(receipt);
  }

  @override
  String formatReceiptAsText(Receipt receipt) {
    final buffer = StringBuffer();
    buffer.writeln('--- Receipt ---');
    buffer.writeln('Store: ${receipt.displayName}');
    if (receipt.purchaseDate != null) {
      buffer.writeln('Date: ${receipt.purchaseDate}');
    }
    if (receipt.totalAmount != null) {
      buffer.writeln('Total: ${receipt.totalAmount!.toStringAsFixed(2)} ${receipt.currency}');
    }
    if (receipt.category != null) {
      buffer.writeln('Category: ${receipt.category}');
    }
    if (receipt.warrantyMonths > 0) {
      buffer.writeln('Warranty: ${receipt.warrantyMonths} months');
      if (receipt.warrantyExpiryDate != null) {
        buffer.writeln('Warranty Expires: ${receipt.warrantyExpiryDate}');
      }
      buffer.writeln('Warranty Active: ${receipt.isWarrantyActive ? "Yes" : "No"}');
    }
    if (receipt.status != ReceiptStatus.active) {
      buffer.writeln('Status: ${receipt.status.name}');
    }
    if (receipt.userNotes != null && receipt.userNotes!.isNotEmpty) {
      buffer.writeln('Notes: ${receipt.userNotes}');
    }
    buffer.writeln('---');
    return buffer.toString();
  }

  @override
  String batchExportCsv(List<Receipt> receipts) {
    // Simple CSV without csv package dependency
    final headers = 'Store,Date,Amount,Currency,Category,Warranty Months,Expiry Date,Status,Notes';
    final rows = receipts.map((r) =>
      '${_escape(r.displayName)},${_escape(r.purchaseDate ?? '')},${r.totalAmount?.toStringAsFixed(2) ?? ''},${r.currency},${_escape(r.category ?? '')},${r.warrantyMonths},${r.warrantyExpiryDate ?? ''},${r.status.name},${_escape(r.userNotes ?? '')}');
    lastCsvOutput = '$headers\n${rows.join('\n')}';
    return lastCsvOutput!;
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Future<void> shareFile(String filePath, {String? mimeType}) async {
    sharedFiles.add(filePath);
  }
}
