import 'package:flutter_tts/flutter_tts.dart';

/// Voice-first support: reads any app text aloud using the phone's built-in
/// offline TTS engine — for caregivers with limited literacy. English today;
/// the same pipeline can carry recorded Dagbani prompts later.
class TtsService {
  TtsService() {
    _ready = _configure();
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;

  Future<void> _configure() async {
    // speak() resolves when playback finishes — enables call-style loops.
    // Awaited before first use so early speaks don't race the setup.
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setLanguage('en-US');
  }

  Future<void> speak(String text) async {
    await _ready;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
