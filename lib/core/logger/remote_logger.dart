import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../version.dart';
import '../utils/device_info.dart';

class RemoteLogger {
  static const String _apiUrl = 'https://logs.rizzdp.ru/';

  /// Отправка лога на сервер.
  ///
  /// [deviceId] – уникальный идентификатор устройства/пользователя.
  /// [username] – имя пользователя (если доступно).
  /// Остальные параметры заполняются из [DeviceInfo.gather()] автоматически.
  Future<void> sendLog({
    required String level,
    required String summary,
    String? details,
    required String deviceId,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    if (kDebugMode) return;

    try {
      final deviceInfo = await DeviceInfo.gather();
      
      // Извлекаем модель устройства и версию ОС из собранных данных
      final deviceModel = deviceInfo['device_model']?.toString();
      final osVersion = deviceInfo['os_version']?.toString();

      final fullMetadata = {
        ...?metadata,
        'device': deviceInfo,
      };

      final body = jsonEncode({
        'level': level,
        'summary': summary,
        'details': details,
        'metadata': fullMetadata,
        'timestamp': DateTime.now().toIso8601String(),
        'appVersion': AppVersion.fullVersion,
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'device_id': deviceId,
        'username': username ?? 'unknown',
        'device_model': deviceModel ?? 'unknown',
        'os_version': osVersion ?? 'unknown',
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        debugPrint('RemoteLogger: Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('RemoteLogger error: $e');
    }
  }
}