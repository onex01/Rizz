import 'dart:html' as html;
import 'dart:typed_data';
import 'file_handler.dart';

class WebFileHandler implements FileHandler {
  @override
  Future<String?> saveFile(List<int> bytes, String fileName) async {
    try {
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = fileName;
      anchor.click();
      return fileName;
    } catch (e) {
      print('Error saving file on web: $e');
      return null;
    }
  }

  @override
  Future<List<int>?> readFile(String path) async {
    print('Reading file by path is not supported on web in the same way.');
    return null;
  }
}

FileHandler createFileHandler() => WebFileHandler();