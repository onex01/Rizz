import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'remote_logger.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _logFileName = 'rizz_log.txt';
  final RemoteLogger _remoteLogger;
  File? _logFile;
  File? getLogFile() => _logFile;
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
      // Веб: не пишем в файл, только консоль и удалённо
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

  Future<void> log(LogLevel level, String message, [Object? error, StackTrace? stack]) async {
    final levelStr = level.toString().split('.').last.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$levelStr] $timestamp - $message\n';
    debugPrint(logEntry);
    await _write(logEntry);

    // Отправляем warning и error на сервер
    if (level == LogLevel.error || level == LogLevel.warning) {
      _remoteLogger.sendLog(
        level: levelStr,
        message: message,
        error: error?.toString(),
        stackTrace: stack?.toString(),
      );
    }
  }

  Future<void> debug(String message) async {
    if (kDebugMode) await log(LogLevel.debug, message);
  }

  Future<void> info(String message) => log(LogLevel.info, message);
  Future<void> warning(String message) => log(LogLevel.warning, message);
  Future<void> error(String message, [Object? error, StackTrace? stack]) =>
      log(LogLevel.error, message, error, stack);
}