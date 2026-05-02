import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'cloud_storage_service.dart';

class WebDavStorageService implements CloudStorageService {
  String? _baseUrl;
  String? _username;
  String? _password;

  @override
  Future<bool> isConfigured() async => _baseUrl != null;

  Future<void> configure(String baseUrl, String username, String password) async {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    _username = username;
    _password = password;
  }

  @override
  Future<String?> uploadFile(String fileName, File file) async {
    if (_baseUrl == null) return null;
    final url = '${_baseUrl}$fileName';
    final bytes = await file.readAsBytes();
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ${_basicAuth(_username!, _password!)}',
      },
      body: bytes,
    );
    if (response.statusCode == 201 || response.statusCode == 204) {
      return url;
    }
    return null;
  }

  @override
  Future<File?> downloadFile(String remoteId) async {
    // remoteId — полный URL
    final response = await http.get(
      Uri.parse(remoteId),
      headers: {'Authorization': 'Basic ${_basicAuth(_username!, _password!)}'},
    );
    if (response.statusCode == 200) {
      final file = File('${Directory.systemTemp.path}/${Uri.parse(remoteId).pathSegments.last}');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
    return null;
  }

  @override
  Future<void> deleteFile(String remoteId) async {
    await http.delete(Uri.parse(remoteId),
        headers: {'Authorization': 'Basic ${_basicAuth(_username!, _password!)}'});
  }

  String _basicAuth(String user, String pass) {
    final bytes = utf8.encode('$user:$pass');
    return base64.encode(bytes);
  }
}