import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String? replyToMessageId;
  final String? repliedMessageText;
  final String type;
  final Map<String, dynamic>? mediaData;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.replyToMessageId,
    this.repliedMessageText,
    this.type = 'text',
    this.mediaData,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'replyToMessageId': replyToMessageId,
      'repliedMessageText': repliedMessageText,
      'type': type,
    };
    if (mediaData != null) map.addAll(mediaData!);
    return map;
  }
}