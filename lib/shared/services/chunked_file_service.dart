import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChunkedFileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int chunkSize = 400 * 1024; // 400 KB

  Future<String> uploadLargeFile(List<int> bytes, String fileName) async {
    final fileId = _generateFileId();
    final totalChunks = (bytes.length / chunkSize).ceil();

    final batch = _firestore.batch();
    final chunksRef = _firestore.collection('file_chunks').doc(fileId).collection('chunks');

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, bytes.length);
      final chunk = bytes.sublist(start, end);
      final hex = _bytesToHex(chunk);
      final chunkDoc = chunksRef.doc('chunk_$i');
      batch.set(chunkDoc, {
        'hex': hex,
        'index': i,
        'total': totalChunks,
      });
    }

    await batch.commit();

    await _firestore.collection('large_files').doc(fileId).set({
      'fileName': fileName,
      'totalChunks': totalChunks,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return fileId;
  }

  Future<List<int>> downloadLargeFile(String fileId) async {
    final chunksSnapshot = await _firestore
        .collection('file_chunks')
        .doc(fileId)
        .collection('chunks')
        .orderBy('index')
        .get();

    final List<int> allBytes = [];
    for (var doc in chunksSnapshot.docs) {
      final hex = doc['hex'] as String;
      allBytes.addAll(_hexToBytes(hex));
    }
    return allBytes;
  }

  String _generateFileId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (DateTime.now().microsecondsSinceEpoch % 1000).toString();
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hexToBytes(String hex) {
    final List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}