import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Agar TTS menunggu hingga selesai bicara sebelum dieksekusi ulang
    await _flutterTts.awaitSpeakCompletion(true);
    
    // Konfigurasi dasar premium
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); 
  }

  // Listener ketika audio selesai diputar
  void setCompletionHandler(VoidCallback onComplete) {
    _flutterTts.setCompletionHandler(onComplete);
  }

  // FITUR BARU: Deteksi bahasa cerdas berbasis Regex (Tanpa perlu mengubah backend)
  String _detectLanguage(String text) {
    // 1. Jepang (Deteksi huruf Hiragana / Katakana)
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(text)) {
      return "ja-JP";
    }
    
    // 2. Mandarin / China (Deteksi huruf Hanzi)
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) {
      return "zh-CN";
    }
    
    // 3. Arab (Deteksi huruf Arab / Hijaiyah)
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return "ar-SA";
    }

    // 4. Jerman (Deteksi kata sandang dan karakter umlaut khas Jerman)
    if (RegExp(r'\b(und|der|die|das|ist|Bitte|Entschuldigung|für|mit)\b', caseSensitive: false).hasMatch(text) || RegExp(r'[äöüß]').hasMatch(text)) {
      return "de-DE";
    }

    // 5. Perancis (Deteksi kata sandang dan karakter aksen khas Perancis)
    if (RegExp(r'\b(le|la|les|pour|vous|nous|est|sur|avec|si)\b', caseSensitive: false).hasMatch(text) || RegExp(r'[çèéêàâîôû]').hasMatch(text)) {
      return "fr-FR";
    }

    // 6. Inggris (Deteksi kata umum bahasa Inggris)
    if (RegExp(r'\b(the|is|are|you|and|for|with|if|to)\b', caseSensitive: false).hasMatch(text)) {
      return "en-US";
    }

    // Default: Indonesia
    return "id-ID";
  }

  Future<void> speak(String text) async {
    String languageCode = _detectLanguage(text);
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}