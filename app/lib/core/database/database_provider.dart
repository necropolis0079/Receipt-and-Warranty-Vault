import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'app_database.dart';

const _dbFileName = 'warranty_vault.db';
const _encryptionKeyStorageKey = 'db_encryption_key';

/// Provides the singleton [AppDatabase] instance with SQLCipher encryption.
///
/// On first launch a random 256-bit key is generated and stored in the
/// platform secure storage (Keychain on iOS, EncryptedSharedPreferences on
/// Android). Subsequent launches retrieve the existing key.
class DatabaseProvider {
  DatabaseProvider._();

  static AppDatabase? _instance;

  /// Returns the singleton [AppDatabase], creating it on first call.
  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;

    final executor = await _openEncrypted();
    _instance = AppDatabase(executor);
    return _instance!;
  }

  /// Closes the database and resets the singleton.
  ///
  /// Used during testing, account deletion, or database reset.
  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  /// Opens the SQLCipher-encrypted database file.
  static Future<QueryExecutor> _openEncrypted() async {
    return LazyDatabase(() async {
      // Ensure the SQLCipher native library is loaded on Android.
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, _dbFileName));
      final key = await _getOrCreateKey();

      return NativeDatabase.createInBackground(
        file,
        setup: (db) {
          db.execute("PRAGMA key = '$key'");
        },
      );
    });
  }

  /// Retrieves the encryption key from secure storage, generating one if
  /// this is the first launch.
  static Future<String> _getOrCreateKey() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    var key = await storage.read(key: _encryptionKeyStorageKey);
    if (key == null) {
      key = _generateHexKey();
      await storage.write(key: _encryptionKeyStorageKey, value: key);
    }
    return key;
  }

  /// Generates a cryptographically secure 256-bit key as a 64-char hex string.
  static String _generateHexKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
