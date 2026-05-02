import 'dart:io';
import "dart:convert";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class MediaApiService {
  static const String baseUrl = 'https://media.rizzdp.ru';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<String?> getToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Загружает файл на сервер с опциональными параметрами сжатия.
  /// [maxWidth] — максимальная ширина изображения (если применимо), по умолчанию 1280.
  /// [quality] — качество JPEG (0-100), по умолчанию 85.
  Future<String?> uploadFile(File file, {
    int? maxWidth,
    int? quality,
  }) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    if (maxWidth != null) {
      request.fields['max_width'] = maxWidth.toString();
    }
    if (quality != null) {
      request.fields['quality'] = quality.toString();
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final urlPath = _parseUrlFromResponse(body);
      return urlPath != null ? '$baseUrl$urlPath' : null;
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  Future<File?> downloadFile(String url) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final ext = p.extension(url);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/rizz_media_${DateTime.now().millisecondsSinceEpoch}$ext');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
    return null;
  }

  String? _parseUrlFromResponse(String body) {
    try {
      // Используем jsonDecode для надёжности, но можно и простой поиск
      final start = body.indexOf('"url":"');
      if (start != -1) {
        final begin = start + 7;
        final end = body.indexOf('"', begin);
        if (end != -1) return body.substring(begin, end);
      }
      // Если не нашли, пробуем jsonDecode
      final map = jsonDecode(body);
      return map['url'];
    } catch (_) {}
    return null;
  }
}