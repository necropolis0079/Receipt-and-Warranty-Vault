import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/services/export_service.dart';

/// Device implementation of [ExportService] using share_plus and csv packages.
class DeviceExportService implements ExportService {
  @override
  Future<void> shareReceipt(Receipt receipt) async {
    final text = formatReceiptAsText(receipt);
    // Share text. If images exist, share them as XFiles.
    if (receipt.localImagePaths.isNotEmpty) {
      final files = receipt.localImagePaths
          .map((path) => XFile(path))
          .toList();
      await Share.shareXFiles(files, text: text);
    } else {
      await Share.share(text);
    }
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
    final headers = [
      'Store',
      'Date',
      'Amount',
      'Currency',
      'Category',
      'Warranty Months',
      'Expiry Date',
      'Status',
      'Notes',
    ];
    final rows = receipts.map((r) => [
          r.displayName,
          r.purchaseDate ?? '',
          r.totalAmount?.toStringAsFixed(2) ?? '',
          r.currency,
          r.category ?? '',
          r.warrantyMonths.toString(),
          r.warrantyExpiryDate ?? '',
          r.status.name,
          r.userNotes ?? '',
        ]);
    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  @override
  Future<void> shareFile(String filePath, {String? mimeType}) async {
    await Share.shareXFiles([XFile(filePath, mimeType: mimeType)]);
  }
}
