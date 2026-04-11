import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'file_handler.dart';

class NativeFileHandler implements FileHandler {
  @override
  Future<String?> saveFile(List<int> bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  @override
  Future<List<int>?> readFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }
}

FileHandler createFileHandler() => NativeFileHandler();