import 'package:drift/drift.dart';

/// Drift table definition for key-value application settings.
///
/// Stores user preferences and sync metadata as string key-value pairs.
/// Values are parsed by the application layer.
@DataClassName('SettingEntry')
class Settings extends Table {
  /// Setting identifier. Primary key.
  TextColumn get key => text()();

  /// Setting value, stored as a string.
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'settings';
}
