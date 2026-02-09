import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

/// Data access object for the [Categories] table.
///
/// Manages default and custom categories, including visibility toggling
/// and display-order management.
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all visible categories, ordered by sort position.
  Stream<List<CategoryEntry>> watchVisible() {
    return (select(categories)
          ..where((c) => c.isHidden.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Get all categories (including hidden), ordered by sort position.
  Future<List<CategoryEntry>> getAll() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Get a single category by ID.
  Future<CategoryEntry?> getById(int id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new custom category. Returns the auto-generated ID.
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  /// Update an existing category.
  Future<bool> updateCategory(CategoriesCompanion entry) async {
    final rows = await (update(categories)
          ..where((c) => c.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  /// Delete a custom category. Default categories cannot be deleted.
  Future<void> deleteCategory(int id) async {
    await (delete(categories)
          ..where((c) => c.id.equals(id) & c.isDefault.equals(false)))
        .go();
  }

  /// Hide a category from the picker UI.
  Future<void> hide(int id) {
    return (update(categories)..where((c) => c.id.equals(id)))
        .write(const CategoriesCompanion(isHidden: Value(true)));
  }

  /// Show a previously hidden category.
  Future<void> show(int id) {
    return (update(categories)..where((c) => c.id.equals(id)))
        .write(const CategoriesCompanion(isHidden: Value(false)));
  }

  /// Update the display order for a category.
  Future<void> reorder(int id, int newSortOrder) {
    return (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(sortOrder: Value(newSortOrder)));
  }

  /// Seed default categories if the table is empty.
  ///
  /// Called during database migration (schema version 1).
  Future<void> seedDefaults() async {
    final count = await (selectOnly(categories)
          ..addColumns([categories.id.count()]))
        .map((row) => row.read(categories.id.count()))
        .getSingle();

    if ((count ?? 0) > 0) return;

    await batch((b) {
      for (final cat in defaultCategories) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: cat['name']! as String,
            icon: Value(cat['icon']! as String),
            isDefault: const Value(true),
            sortOrder: Value(cat['sort_order']! as int),
          ),
        );
      }
    });
  }
}
