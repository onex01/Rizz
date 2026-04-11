import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../version.dart';
import '../utils/device_info.dart';

class RemoteLogger {
  static const String _apiUrl = 'https://rizz.onex01.ru/api/logs';

  Future<void> sendLog({
    required String level,
    required String message,
    String? error,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    if (kDebugMode) return; // не отправляем в дебаге

    try {
      // Добавляем информацию об устройстве
      final deviceInfo = await DeviceInfo.gather();
      final fullMetadata = {
        ...?metadata,
        'device': deviceInfo,
      };

      final body = jsonEncode({
        'level': level,
        'message': message,
        'error': error,
        'stackTrace': stackTrace,
        'metadata': fullMetadata,
        'timestamp': DateTime.now().toIso8601String(),
        'appVersion': AppVersion.fullVersion,
        'platform': Platform.operatingSystem,
      });

      await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('RemoteLogger error: $e');
    }
  }
}