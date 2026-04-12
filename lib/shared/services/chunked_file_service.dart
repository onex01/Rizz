import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChunkedFileService {
  static const int CHUNK_SIZE = 400 * 1024; // 400 KB

  final FirebaseFirestore firestore;

  ChunkedFileService(this.firestore);

  Future<String> uploadLargeFile(Uint8List bytes, String fileName) async {
    final fileId = firestore.collection('large_files').doc().id;
    final base64String = base64Encode(bytes);
    final chunks = <String>[];

    final totalChunks = (base64String.length / CHUNK_SIZE).ceil();
    for (int i = 0; i < totalChunks; i++) {
      final start = i * CHUNK_SIZE;
      final end = (start + CHUNK_SIZE < base64String.length)
          ? start + CHUNK_SIZE
          : base64String.length;
      final chunk = base64String.substring(start, end);
      final chunkDoc = await firestore.collection('file_chunks').add({
        'fileId': fileId,
        'index': i,
        'data': chunk,
      });
      chunks.add(chunkDoc.id);
    }

    await firestore.collection('large_files').doc(fileId).set({
      'fileName': fileName,
      'chunkIds': chunks,
      'totalSize': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return fileId;
  }

  Future<Uint8List> downloadLargeFile(String fileId) async {
    final doc = await firestore.collection('large_files').doc(fileId).get();
    if (!doc.exists) throw Exception('File not found');
    final chunkIds = List<String>.from(doc['chunkIds']);
    final buffer = StringBuffer();
    for (final chunkId in chunkIds) {
      final chunkDoc =
          await firestore.collection('file_chunks').doc(chunkId).get();
      buffer.write(chunkDoc['data']);
    }
    return base64Decode(buffer.toString());
  }
}