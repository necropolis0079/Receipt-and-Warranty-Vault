import 'package:drift/drift.dart';

/// Drift table definition for user categories.
///
/// Stores the 10 default categories and any user-created custom categories.
/// Default categories can be hidden but not deleted. Custom categories can
/// be deleted entirely.
@DataClassName('CategoryEntry')
class Categories extends Table {
  /// Auto-incrementing local primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Category display name. Must be unique.
  TextColumn get name => text().unique()();

  /// Icon identifier that maps to a Flutter icon in the UI.
  TextColumn get icon => text().withDefault(const Constant('other'))();

  /// Whether this is one of the 10 built-in default categories.
  /// Default categories cannot be deleted, only hidden.
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();

  /// Whether the user has hidden this category from the picker.
  /// Hidden categories still exist for receipts already assigned to them.
  BoolColumn get isHidden =>
      boolean().withDefault(const Constant(false))();

  /// Display order in the category picker UI.
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'categories';
}

/// Index definitions for the categories table.
///
/// Applied via [customStatement] in the database migration.
/// The unique index on `name` is already handled by the `.unique()` constraint
/// on the column definition above.
const List<String> categoriesIndexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order)',
];

/// The 10 default categories, used for seeding the database on first launch.
///
/// Each entry is a map with keys matching the Categories table columns.
const List<Map<String, Object>> defaultCategories = [
  {'name': 'Electronics', 'icon': 'electronics', 'is_default': 1, 'sort_order': 1},
  {'name': 'Groceries', 'icon': 'cart', 'is_default': 1, 'sort_order': 2},
  {'name': 'Clothing & Apparel', 'icon': 'clothing', 'is_default': 1, 'sort_order': 3},
  {'name': 'Home & Furniture', 'icon': 'home', 'is_default': 1, 'sort_order': 4},
  {'name': 'Health & Pharmacy', 'icon': 'health', 'is_default': 1, 'sort_order': 5},
  {'name': 'Restaurants & Food', 'icon': 'restaurant', 'is_default': 1, 'sort_order': 6},
  {'name': 'Transportation', 'icon': 'car', 'is_default': 1, 'sort_order': 7},
  {'name': 'Entertainment', 'icon': 'entertainment', 'is_default': 1, 'sort_order': 8},
  {'name': 'Services & Subscriptions', 'icon': 'subscription', 'is_default': 1, 'sort_order': 9},
  {'name': 'Other', 'icon': 'other', 'is_default': 1, 'sort_order': 10},
];
