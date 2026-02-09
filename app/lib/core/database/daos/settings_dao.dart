import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/settings_table.dart';

part 'settings_dao.g.dart';

/// Data access object for the [Settings] table.
///
/// Provides key-value storage for user preferences such as locale,
/// theme mode, default currency, and sync configuration.
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Get a setting value by key. Returns null if not found.
  Future<String?> getValue(String key) async {
    final entry = await (select(settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return entry?.value;
  }

  /// Set a setting value (insert or update).
  Future<void> setValue(String key, String? value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  /// Watch a setting value reactively.
  Stream<String?> watchValue(String key) {
    return (select(settings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((entry) => entry?.value);
  }

  /// Delete a setting by key.
  Future<void> deleteKey(String key) {
    return (delete(settings)..where((s) => s.key.equals(key))).go();
  }

  /// Get all settings as a map.
  Future<Map<String, String?>> getAll() async {
    final entries = await select(settings).get();
    return {for (final e in entries) e.key: e.value};
  }
}
