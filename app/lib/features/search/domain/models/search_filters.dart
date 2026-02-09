import 'package:equatable/equatable.dart';

import '../../../receipt/domain/entities/receipt.dart';

/// Client-side filters applied after FTS5 search results return.
class SearchFilters extends Equatable {
  const SearchFilters({
    this.category,
    this.dateFrom,
    this.dateTo,
    this.amountMin,
    this.amountMax,
    this.hasWarranty,
  });

  final String? category;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? amountMin;
  final double? amountMax;
  final bool? hasWarranty;

  bool get isActive =>
      category != null ||
      dateFrom != null ||
      dateTo != null ||
      amountMin != null ||
      amountMax != null ||
      hasWarranty != null;

  /// Apply filters to a list of receipts.
  List<Receipt> applyTo(List<Receipt> receipts) {
    return receipts.where((r) {
      if (category != null && r.category != category) return false;
      if (dateFrom != null && r.purchaseDate != null) {
        final d = DateTime.tryParse(r.purchaseDate!);
        if (d != null && d.isBefore(dateFrom!)) return false;
      }
      if (dateTo != null && r.purchaseDate != null) {
        final d = DateTime.tryParse(r.purchaseDate!);
        if (d != null && d.isAfter(dateTo!)) return false;
      }
      if (amountMin != null && (r.totalAmount ?? 0) < amountMin!) return false;
      if (amountMax != null &&
          (r.totalAmount ?? double.infinity) > amountMax!) {
        return false;
      }
      if (hasWarranty == true && r.warrantyMonths <= 0) return false;
      if (hasWarranty == false && r.warrantyMonths > 0) return false;
      return true;
    }).toList();
  }

  SearchFilters copyWith({
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? amountMin,
    double? amountMax,
    bool? hasWarranty,
  }) {
    return SearchFilters(
      category: category ?? this.category,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      hasWarranty: hasWarranty ?? this.hasWarranty,
    );
  }

  static const empty = SearchFilters();

  @override
  List<Object?> get props =>
      [category, dateFrom, dateTo, amountMin, amountMax, hasWarranty];
}
