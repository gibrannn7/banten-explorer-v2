import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initSpeech() async {
    bool hasSpeech = await _speech.initialize();
    return hasSpeech;
  }

  // MENERIMA PARAMETER LOCALE ID
  void startListening(Function(String) onResult, {String localeId = "id_ID"}) async {
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      localeId: localeId, // MENGGUNAKAN LOCALE DINAMIS
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}