class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String nickname;
  final String? photoUrl;
  final String? avatarHex;
  final String? bio;

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    this.username,
    this.photoUrl,
    this.avatarHex,
    this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'avatarHex': avatarHex,
      'bio': bio,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      nickname: map['nickname'] ?? '',
      photoUrl: map['photoUrl'],
      avatarHex: map['avatarHex'],
      bio: map['bio'],
    );
  }
}