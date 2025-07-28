import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  Future<bool> initSpeech() async {
    return await _speech.initialize();
  }

  void startListening(Function(String text) onResult) {
    _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult(_lastWords);
      },
    );
    _isListening = true;
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  bool get isListening => _isListening;
}
