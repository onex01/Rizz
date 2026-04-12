abstract class FileHandler {
  Future<String?> saveFile(List<int> bytes, String fileName);
  Future<List<int>?> readFile(String path);
}

