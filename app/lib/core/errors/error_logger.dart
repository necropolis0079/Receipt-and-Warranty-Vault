import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton service that logs errors to a local file for debugging.
///
/// Captures Flutter framework errors, platform errors, and uncaught
/// zone errors. Logs are stored in `error_logs.txt` in the app's
/// documents directory.
class ErrorLogger {
  ErrorLogger._();
  static final ErrorLogger instance = ErrorLogger._();

  File? _logFile;
  bool _initialized = false;

  /// Initialize the logger — must be called before logging.
  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/error_logs.txt');
    _initialized = true;
  }

  /// Log a general error with optional stack trace.
  Future<void> logError(Object error, [StackTrace? stackTrace]) async {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer()
      ..writeln('[$timestamp] ERROR: $error')
      ..writeln(stackTrace ?? StackTrace.current)
      ..writeln('---');

    if (kDebugMode) {
      debugPrint(buffer.toString());
    }

    if (_logFile != null) {
      try {
        await _logFile!.writeAsString(
          buffer.toString(),
          mode: FileMode.append,
        );
      } catch (_) {
        // Silently ignore file write errors to prevent infinite loops.
      }
    }
  }

  /// Log a [FlutterErrorDetails] from [FlutterError.onError].
  Future<void> logFlutterError(FlutterErrorDetails details) async {
    await logError(details.exceptionAsString(), details.stack);
  }

  /// Read all logged errors as a string.
  Future<String> getErrorLogs() async {
    if (_logFile == null || !await _logFile!.exists()) return '';
    return _logFile!.readAsString();
  }

  /// Clear all logged errors.
  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }
}
