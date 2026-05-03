import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'remote_logger.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _logFileName = 'rizz_log.txt';
  final RemoteLogger _remoteLogger;
  final String _deviceId;
  String? _username;
  File? _logFile;
  bool _initialized = false;
  bool _verboseLogging = false; // подробное логирование ВКЛ/ВЫКЛ

  AppLogger(this._remoteLogger, {required String deviceId})
      : _deviceId = deviceId;

  void setUsername(String username) {
    _username = username;
  }

  /// Включить/выключить подробное логирование (info/debug).
  void setVerboseLogging(bool enabled) {
    _verboseLogging = enabled;
  }
  void enableVerboseLogging() => setVerboseLogging(true);
  void disableVerboseLogging() => setVerboseLogging(false);

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
    // Отправляем на сервер всегда ошибки и предупреждения, подробные логи — только если включён флаг
    if (level == LogLevel.error || level == LogLevel.warning || _verboseLogging) {
      _remoteLogger.sendLog(
        level: levelStr,
        summary: summary,
        details: details,
        deviceId: _deviceId,
        username: _username,
      );
    }
  }

  Future<void> debug(String message) async {
    if (_verboseLogging || kDebugMode) await log(LogLevel.debug, message);
  }

  Future<void> info(String message) async {
    if (_verboseLogging || kDebugMode) {
      await log(LogLevel.info, message);
    }
  }

  Future<void> warning(String message, {String? details}) =>
      log(LogLevel.warning, message, details: details);

  Future<void> error(String message, {Object? error, StackTrace? stack}) {
    final details = error != null || stack != null
        ? 'Exception: $error\nStackTrace: $stack'
        : null;
    return log(LogLevel.error, message, details: details);
  }

  /// Полностью очистить файл логов (удалить все записи).
  Future<void> clearLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('', mode: FileMode.write);
        _write('=== Log cleared at ${DateTime.now()} ===\n');
      }
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }

  File? getLogFile() => _logFile;
}