import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final bool isRead;
  final String? replyToMessageId;
  final String? repliedMessageText;
  final bool isEdited;
  final Timestamp? editedAt;
  final bool isDeleted;
  final String type; // text / image_hex / file_hex / voice / video_circle
  final Map<String, dynamic>? mediaData; // hex, fileName, fileSize, etc.

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.replyToMessageId,
    this.repliedMessageText,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.type = 'text',
    this.mediaData,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'replyToMessageId': replyToMessageId,
      'repliedMessageText': repliedMessageText,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'isDeleted': isDeleted,
      'type': type,
    };
    if (mediaData != null) map.addAll(mediaData!);
    return map;
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      senderId: map['senderId'],
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      repliedMessageText: map['repliedMessageText'],
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'],
      isDeleted: map['isDeleted'] ?? false,
      type: map['type'] ?? 'text',
      mediaData: _extractMediaData(map),
    );
  }

  static Map<String, dynamic>? _extractMediaData(Map<String, dynamic> map) {
    final mediaKeys = ['hexData', 'fileName', 'fileSize', 'fileExtension', 'duration'];
    final media = <String, dynamic>{};
    for (var key in mediaKeys) {
      if (map.containsKey(key)) media[key] = map[key];
    }
    return media.isEmpty ? null : media;
  }
}