import 'dart:async';
import 'package:flutter/material.dart';
import 'package:banten_explorer/domain/entities/chat_entity.dart';
import 'package:banten_explorer/domain/repositories/chat_repository.dart';
import 'package:banten_explorer/presentation/services/speech_service.dart';
import 'package:banten_explorer/presentation/services/tts_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository chatRepository;
  final SpeechService speechService;
  final TtsService ttsService;

  String? _playingMessageId;
  String? get playingMessageId => _playingMessageId;

  String _selectedLanguage = 'id_ID';
  String get selectedLanguage => _selectedLanguage;

  ChatProvider({
    required this.chatRepository,
    required this.speechService,
    required this.ttsService,
  }) {
    _initSpeech();
    _listenToHistory();

    ttsService.setCompletionHandler(() {
      _playingMessageId = null;
      notifyListeners();
    });
  }

  List<ChatEntity> _messages = [];
  List<ChatEntity> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isS2SProcessing = false;
  bool get isS2SProcessing => _isS2SProcessing;

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

  void setSpeechLanguage(String localeCode) {
    _selectedLanguage = localeCode;
    notifyListeners();
  }

  Future<void> toggleAudio(String messageId, String text) async {
    if (_playingMessageId == messageId) {
      await ttsService.stop();
      _playingMessageId = null;
      notifyListeners();
    } else {
      await ttsService.stop();
      _playingMessageId = messageId;
      notifyListeners();
      await ttsService.speak(text);
    }
  }

  // FUNGSI BARU UNTUK MERESET AUDIO SAAT KELUAR S2S
  Future<void> stopAudio() async {
    await ttsService.stop();
    _playingMessageId = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await stopAudio(); // Hentikan audio sebelumnya

    final userMessage = ChatEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.insert(0, userMessage);
    _isLoading = true;
    notifyListeners();

    await chatRepository.saveChatToHistory(userMessage);

    try {
      // KIRIM BAHASA KE BACKEND
      final botResponse = await chatRepository.sendMessageToServer(
        text,
        _selectedLanguage,
      );
      await chatRepository.saveChatToHistory(botResponse);
    } catch (e) {
      final errorMessage = ChatEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Maaf, server sedang sibuk. Silakan coba lagi nanti.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      await chatRepository.saveChatToHistory(errorMessage);
    } finally {
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
      await stopAudio();

      _isListening = true;
      _recognizedText = '';
      notifyListeners();

      speechService.startListening((text) {
        _recognizedText = text;
        notifyListeners();
      }, localeId: _selectedLanguage);
    }
  }

  Future<void> processS2SAudio(String filePath) async {
    _isS2SProcessing = true;
    _isLoading = true;
    notifyListeners();

    try {
      // KIRIM BAHASA KE BACKEND
      final result = await chatRepository.sendAudioMessageToServer(
        filePath,
        _selectedLanguage,
      );
      final userChat = result[0];
      final botChat = result[1];

      _messages.insert(0, userChat);
      await chatRepository.saveChatToHistory(userChat);

      _messages.insert(0, botChat);
      await chatRepository.saveChatToHistory(botChat);

      await ttsService.stop();
      _playingMessageId = botChat.id;
      _isS2SProcessing = false;
      _isLoading = false;
      notifyListeners();

      await ttsService.speak(botChat.text);
    } catch (e) {
      _isS2SProcessing = false;
      _isLoading = false;
      notifyListeners();
    }
  }
  

  @override
  void dispose() {
    _chatSubscription?.cancel();
    ttsService.stop();
    super.dispose();
  }
}
