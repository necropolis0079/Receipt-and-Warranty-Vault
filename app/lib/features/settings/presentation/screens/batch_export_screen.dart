import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import '../../../receipt/domain/entities/receipt.dart';
import '../../../receipt/domain/services/export_service.dart';
import '../../../receipt/presentation/bloc/vault_bloc.dart';
import '../../../receipt/presentation/bloc/vault_state.dart';

/// Screen for selecting a date range and exporting matching receipts as CSV.
class BatchExportScreen extends StatefulWidget {
  const BatchExportScreen({super.key});

  @override
  State<BatchExportScreen> createState() => _BatchExportScreenState();
}

class _BatchExportScreenState extends State<BatchExportScreen> {
  DateTimeRange? _dateRange;
  bool _exporting = false;

  List<Receipt> _filterByDateRange(List<Receipt> receipts) {
    if (_dateRange == null) return receipts;
    return receipts.where((r) {
      if (r.purchaseDate == null) return false;
      final date = DateTime.tryParse(r.purchaseDate!);
      if (date == null) return false;
      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final endInclusive = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      return !date.isBefore(start) && !date.isAfter(endInclusive);
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _export(List<Receipt> receipts) async {
    setState(() => _exporting = true);
    try {
      final exportService = GetIt.I<ExportService>();
      final csv = exportService.batchExportCsv(receipts);
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/warranty_vault_export_$timestamp.csv');
      await file.writeAsString(csv);
      await exportService.shareFile(file.path, mimeType: 'text/csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).exportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vaultState = context.watch<VaultBloc>().state;
    final allReceipts =
        vaultState is VaultLoaded ? vaultState.receipts : <Receipt>[];
    final filtered = _filterByDateRange(allReceipts);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportByDateRange)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date range selection card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectDateRange,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dateRange != null
                                    ? '${_formatDate(_dateRange!.start)}  →  ${_formatDate(_dateRange!.end)}'
                                    : l10n.allDates,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            if (_dateRange != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () =>
                                    setState(() => _dateRange = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Match count
            Center(
              child: Text(
                l10n.receiptsToExport(filtered.length),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (filtered.isEmpty && _dateRange != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.noReceiptsInRange,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
            const Spacer(),
            // Export button
            FilledButton.icon(
              onPressed:
                  filtered.isEmpty || _exporting ? null : () => _export(filtered),
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download),
              label: Text(l10n.exportCsv),
            ),
          ],
        ),
      ),
    );
  }
}
