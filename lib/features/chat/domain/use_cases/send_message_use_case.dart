import '../message.dart';
import '../../data/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;
  SendMessageUseCase(this._repository);

  Future<void> call(String chatId, Message message) async {
    await _repository.sendMessage(chatId, message);
  }
}