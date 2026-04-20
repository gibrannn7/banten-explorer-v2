import 'package:banten_explorer/domain/entities/chat_entity.dart';

abstract class ChatRepository {
  Future<ChatEntity> sendMessageToServer(String message, String language);
  Stream<List<ChatEntity>> getChatHistory();
  Future<void> saveChatToHistory(ChatEntity chat);
  Future<List<ChatEntity>> sendAudioMessageToServer(String filePath, String language);
}