import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'remote_logger.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _logFileName = 'rizz_log.txt';
  final RemoteLogger _remoteLogger;
  File? _logFile;
  bool _initialized = false;

  AppLogger(this._remoteLogger);

  Future<void> init() async {
    if (_initialized) return;
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _logFile = File('${dir.path}/$_logFileName');
        if (!await _logFile!.exists()) {
          await _logFile!.create(recursive: true);
        }
        _initialized = true;
        await _write('=== Rizz Log Started === ${DateTime.now()}\n');
      } catch (e) {
        debugPrint('Logger init error: $e');
      }
    } else {
      _initialized = true;
      debugPrint('=== Rizz Web Log Started === ${DateTime.now()}');
    }
  }

  Future<void> _write(String text) async {
    if (!_initialized || _logFile == null || kIsWeb) return;
    try {
      await _logFile!.writeAsString(text, mode: FileMode.append);
    } catch (e) {
      debugPrint('Log write error: $e');
    }
  }

  Future<void> log(LogLevel level, String summary, {String? details}) async {
    final levelStr = level.toString().split('.').last.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$levelStr] $timestamp - $summary\n';
    debugPrint(logEntry);
    await _write(logEntry);
    if (details != null && details.isNotEmpty) {
      await _write('  Details: $details\n');
    }

    if (level == LogLevel.error || level == LogLevel.warning) {
      _remoteLogger.sendLog(
        level: levelStr,
        summary: summary,
        details: details,
      );
    }
  }

  Future<void> debug(String message) async {
    if (kDebugMode) await log(LogLevel.debug, message);
  }

  Future<void> info(String message) => log(LogLevel.info, message);

  Future<void> warning(String message, {String? details}) =>
      log(LogLevel.warning, message, details: details);

  Future<void> error(String message, {Object? error, StackTrace? stack}) {
    final details = error != null || stack != null
        ? 'Exception: $error\nStackTrace: $stack'
        : null;
    return log(LogLevel.error, message, details: details);
  }

  File? getLogFile() => _logFile;
}