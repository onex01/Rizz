import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/chat_repository.dart';

class GetChatsUseCase {
  final ChatRepository _repository;
  GetChatsUseCase(this._repository);

  Stream<QuerySnapshot> call(String userId) => _repository.getChats(userId);
}