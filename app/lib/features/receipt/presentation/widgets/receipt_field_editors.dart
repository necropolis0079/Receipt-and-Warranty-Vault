import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StoreNameField extends StatelessWidget {
  const StoreNameField({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.storeName,
        prefixIcon: const Icon(Icons.store_outlined),
      ),
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
    );
  }
}

class PurchaseDateField extends StatelessWidget {
  const PurchaseDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: l10n.purchaseDate,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        hintText: value ?? l10n.selectDate,
      ),
      controller: TextEditingController(text: value),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date.toIso8601String().substring(0, 10));
        }
      },
    );
  }
}

class TotalAmountField extends StatelessWidget {
  const TotalAmountField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.totalAmount,
        prefixIcon: const Icon(Icons.euro_outlined),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      onChanged: onChanged,
    );
  }
}

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _currencies = ['EUR', 'USD', 'GBP'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: l10n.currency,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      items: _currencies
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class WarrantyEditor extends StatelessWidget {
  const WarrantyEditor({
    super.key,
    required this.months,
    required this.onChanged,
  });

  final int months;
  final ValueChanged<int> onChanged;

  static const _options = [0, 6, 12, 24, 36, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      value: _options.contains(months) ? months : 0,
      decoration: InputDecoration(
        labelText: l10n.warrantyPeriod,
        prefixIcon: const Icon(Icons.shield_outlined),
      ),
      items: _options
          .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m == 0 ? l10n.noWarranty : l10n.monthsCount(m)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  final String? value;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      value: value != null && categories.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: l10n.category,
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      hint: Text(l10n.selectCategory),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class NotesField extends StatelessWidget {
  const NotesField({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.notes,
        prefixIcon: const Icon(Icons.notes_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      onChanged: onChanged,
    );
  }
}
