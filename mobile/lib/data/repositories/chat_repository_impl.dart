import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banten_explorer/core/network/api_client.dart';
import 'package:banten_explorer/data/models/chat_response_model.dart';
import 'package:banten_explorer/domain/entities/chat_entity.dart';
import 'package:banten_explorer/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient apiClient;
  final FirebaseFirestore firestore;
  final String sessionId = 'sesi_prototipe_01';

  ChatRepositoryImpl({
    required this.apiClient,
    required this.firestore,
  });

  @override
  Future<ChatEntity> sendMessageToServer(String message) async {
    final Map<String, dynamic> responseData = await apiClient.sendMessage(message);
    final ChatResponseModel model = ChatResponseModel.fromJson(responseData);

    return ChatEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: model.pesan,
      isUser: false,
      timestamp: DateTime.now(),
      showMap: model.tampilkanMap,
      mapKeyword: model.keywordLokasi,
      imageUrls: model.gambarUrls,
    );
  }

  @override
  Future<void> saveChatToHistory(ChatEntity chat) async {
    await firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .doc(chat.id)
        .set({
      'id': chat.id,
      'text': chat.text,
      'isUser': chat.isUser,
      'timestamp': chat.timestamp.toIso8601String(),
      'showMap': chat.showMap,
      'mapKeyword': chat.mapKeyword,
      'imageUrls': chat.imageUrls,
    });
  }

  @override
  Stream<List<ChatEntity>> getChatHistory() {
    return firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        List<String>? parsedUrls;
        if (data['imageUrls'] != null) {
          parsedUrls = List<String>.from(data['imageUrls']);
        }
        
        return ChatEntity(
          id: data['id'] as String,
          text: data['text'] as String,
          isUser: data['isUser'] as bool,
          timestamp: DateTime.parse(data['timestamp'] as String),
          showMap: data['showMap'] as bool? ?? false,
          mapKeyword: data['mapKeyword'] as String?,
          imageUrls: parsedUrls,
        );
      }).toList();
    });
  }
}