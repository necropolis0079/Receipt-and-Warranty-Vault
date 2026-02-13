import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/daos/categories_dao.dart';
import '../../domain/entities/receipt.dart';
import '../bloc/vault_bloc.dart';
import '../bloc/vault_event.dart';
import '../widgets/receipt_field_editors.dart';

/// Screen for editing an existing receipt's fields.
///
/// Pre-populates all editable fields from the [receipt] parameter.
/// On save, dispatches [VaultReceiptUpdated] to persist changes.
class EditReceiptScreen extends StatefulWidget {
  const EditReceiptScreen({super.key, required this.receipt});

  final Receipt receipt;

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  late final TextEditingController _storeController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String? _purchaseDate;
  late String _currency;
  late String? _category;
  late int _warrantyMonths;

  List<String> _categoryNames = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _storeController =
        TextEditingController(text: widget.receipt.storeName ?? '');
    _amountController = TextEditingController(
      text: widget.receipt.totalAmount?.toString() ?? '',
    );
    _notesController =
        TextEditingController(text: widget.receipt.userNotes ?? '');

    _purchaseDate = widget.receipt.purchaseDate;
    _currency = widget.receipt.currency;
    _category = widget.receipt.category;
    _warrantyMonths = widget.receipt.warrantyMonths;

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final dao = GetIt.I<CategoriesDao>();
    final entries = await dao.getAll();
    if (mounted) {
      setState(() {
        _categoryNames =
            entries.where((e) => !e.isHidden).map((e) => e.name).toList();
      });
    }
  }

  @override
  void dispose() {
    _storeController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_saving) return;
    setState(() => _saving = true);

    final now = DateTime.now().toIso8601String();

    String? warrantyExpiryDate = widget.receipt.warrantyExpiryDate;
    if (_warrantyMonths > 0 && _purchaseDate != null) {
      final purchaseDateTime = DateTime.tryParse(_purchaseDate!);
      if (purchaseDateTime != null) {
        // Calculate expiry: add months, then clamp day to last day of target
        // month to avoid overflow (e.g. Jan 31 + 1 month = Feb 28/29).
        final targetMonth = purchaseDateTime.month + _warrantyMonths;
        final expiryRaw = DateTime(purchaseDateTime.year, targetMonth + 1, 0);
        final clampedDay = purchaseDateTime.day <= expiryRaw.day
            ? purchaseDateTime.day
            : expiryRaw.day;
        final expiryDate =
            DateTime(purchaseDateTime.year, targetMonth, clampedDay);
        warrantyExpiryDate = expiryDate.toIso8601String().split('T').first;
      }
    } else if (_warrantyMonths == 0) {
      warrantyExpiryDate = null;
    }

    final totalAmount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));

    final updated = widget.receipt.copyWith(
      storeName: _storeController.text.isNotEmpty
          ? _storeController.text
          : widget.receipt.storeName,
      purchaseDate: _purchaseDate,
      totalAmount: totalAmount,
      currency: _currency,
      category: _category,
      warrantyMonths: _warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate,
      userNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
      updatedAt: now,
    );

    context.read<VaultBloc>().add(VaultReceiptUpdated(updated));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).receiptUpdated)),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editReceipt),
        actions: [
          TextButton(
            onPressed: _saving ? null : _onSave,
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoreNameField(
              controller: _storeController,
            ),
            AppSpacing.verticalGapMd,

            PurchaseDateField(
              value: _purchaseDate,
              onChanged: (v) => setState(() => _purchaseDate = v),
            ),
            AppSpacing.verticalGapMd,

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TotalAmountField(
                    controller: _amountController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CurrencySelector(
                    value: _currency,
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalGapMd,

            if (_categoryNames.isNotEmpty)
              CategoryPickerField(
                value: _category,
                categories: _categoryNames,
                onChanged: (v) => setState(() => _category = v),
              ),
            if (_categoryNames.isNotEmpty) AppSpacing.verticalGapMd,

            WarrantyEditor(
              months: _warrantyMonths,
              onChanged: (v) => setState(() => _warrantyMonths = v),
            ),
            AppSpacing.verticalGapMd,

            NotesField(
              controller: _notesController,
            ),
            AppSpacing.verticalGapLg,

            FilledButton.icon(
              onPressed: _saving ? null : _onSave,
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            AppSpacing.verticalGapLg,
          ],
        ),
      ),
    );
  }
}
