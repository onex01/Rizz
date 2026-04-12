import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String uid;
  final String nickname;
  final String? photoUrl;
  final bool isBlocked;
  final DateTime addedAt;

  Contact({
    required this.uid,
    required this.nickname,
    this.photoUrl,
    this.isBlocked = false,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nickname': nickname,
    'photoUrl': photoUrl,
    'isBlocked': isBlocked,
    'addedAt': Timestamp.fromDate(addedAt),
  };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
    uid: map['uid'],
    nickname: map['nickname'],
    photoUrl: map['photoUrl'],
    isBlocked: map['isBlocked'] ?? false,
    addedAt: (map['addedAt'] as Timestamp).toDate(),
  );
}