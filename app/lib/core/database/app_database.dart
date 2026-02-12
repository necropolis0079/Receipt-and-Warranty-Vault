import 'package:drift/drift.dart';

import 'daos/categories_dao.dart';
import 'daos/receipts_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/categories_table.dart';
import 'tables/receipts_table.dart';
import 'tables/settings_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

/// The main Drift database for Warranty Vault.
///
/// Includes tables (receipts, categories, settings) with FTS5 full-text
/// search, indexes, and triggers set up during migration. The sync_queue
/// table is retained for schema compatibility but unused.
/// Encrypted at rest via SQLCipher (AES-256) — see [DatabaseProvider].
@DriftDatabase(
  tables: [Receipts, Categories, SyncQueue, Settings],
  daos: [ReceiptsDao, CategoriesDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Constructor for unit tests using an in-memory database.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // 1. Create all tables defined via Drift annotations.
          await m.createAll();

          // 2. Create indexes on receipts.
          for (final stmt in receiptsIndexStatements) {
            await customStatement(stmt);
          }

          // 3. Create indexes on categories.
          for (final stmt in categoriesIndexStatements) {
            await customStatement(stmt);
          }

          // 4. Create FTS5 virtual table for full-text search.
          await customStatement(createReceiptsFtsStatement);

          // 5. Create triggers to keep FTS5 index in sync.
          for (final stmt in receiptsFtsTriggerStatements) {
            await customStatement(stmt);
          }

          // 6. Seed the 10 default categories.
          for (final cat in defaultCategories) {
            await into(categories).insert(CategoriesCompanion.insert(
              name: cat['name']! as String,
              icon: Value(cat['icon']! as String),
              isDefault: const Value(true),
              sortOrder: Value(cat['sort_order']! as int),
            ));
          }
        },
      );
}
