import 'dart:async';
import 'package:flutter/material.dart';
import 'package:banten_explorer/domain/entities/chat_entity.dart';
import 'package:banten_explorer/domain/repositories/chat_repository.dart';
import 'package:banten_explorer/presentation/services/speech_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository chatRepository;
  final SpeechService speechService;

  ChatProvider({
    required this.chatRepository,
    required this.speechService,
  }) {
    _initSpeech();
    _listenToHistory();
  }

  List<ChatEntity> _messages = [];
  List<ChatEntity> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isListening = false;
  bool get isListening => _isListening;

  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  StreamSubscription<List<ChatEntity>>? _chatSubscription;

  Future<void> _initSpeech() async {
    await speechService.initSpeech();
  }

  void _listenToHistory() {
    _chatSubscription = chatRepository.getChatHistory().listen((history) {
      _messages = history;
      notifyListeners();
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // KUNCI PERBAIKAN (OPTIMISTIC UPDATE): 
    // Masukkan pesan ke UI seketika sebelum menunggu Firestore/Server
    _messages.insert(0, userMessage);
    _isLoading = true;
    notifyListeners();

    // Menyimpan ke Firestore
    await chatRepository.saveChatToHistory(userMessage);

    try {
      final botResponse = await chatRepository.sendMessageToServer(text);
      
      // Simpan respons bot ke Firestore
      await chatRepository.saveChatToHistory(botResponse);
    } catch (e) {
      final errorMessage = ChatEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Maaf, server sedang sibuk. Silakan coba lagi nanti.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      // Tampilkan error jika koneksi Python terputus
      await chatRepository.saveChatToHistory(errorMessage);
    } finally {
      // Matikan animasi loading Lottie
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleListening(TextEditingController textController) async {
    if (_isListening) {
      await speechService.stopListening();
      _isListening = false;
      if (_recognizedText.isNotEmpty) {
        textController.text = _recognizedText;
      }
      notifyListeners();
    } else {
      _isListening = true;
      _recognizedText = '';
      notifyListeners();

      speechService.startListening((text) {
        _recognizedText = text;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }
}