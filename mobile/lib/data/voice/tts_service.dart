import 'package:flutter_tts/flutter_tts.dart';

/// Voice-first support: reads any app text aloud using the phone's built-in
/// offline TTS engine — for caregivers with limited literacy. English today;
/// the same pipeline can carry recorded Dagbani prompts later.
class TtsService {
  TtsService() {
    _tts
      ..setSpeechRate(0.45)
      ..setPitch(1.0)
      ..setLanguage('en-US');
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
