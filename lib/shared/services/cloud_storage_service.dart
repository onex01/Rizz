import 'dart:io';

abstract class CloudStorageService {
  Future<bool> isConfigured();
  Future<String?> uploadFile(String fileName, File file);
  Future<File?> downloadFile(String remoteId);
  Future<void> deleteFile(String remoteId);
}