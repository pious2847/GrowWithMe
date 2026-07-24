import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'tts_service.dart';

/// Nana's voice: natural speech from ElevenLabs (via our backend proxy) when
/// online, falling back to the phone's built-in TTS ONLY when no ElevenLabs
/// audio could be obtained — never both at once.
class NanaVoice {
  NanaVoice(this._api, this._tts);

  final ApiClient _api;
  final TtsService _tts;
  final AudioPlayer _player = AudioPlayer();
  int _generation = 0;

  /// Speaks and resolves when playback FINISHES — so callers can chain
  /// "speak, then listen" like a phone call. A new speak() silences any
  /// previous one (both engines) before starting.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final myGeneration = ++_generation;
    await stop();

    // 1. Try to obtain ElevenLabs audio. Fetch ONLY — nothing audible yet.
    Uint8List? bytes;
    try {
      final res = await _api.dio.post<List<int>>(
        '/assistant/speak',
        data: {'text': text},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (res.data != null && res.data!.isNotEmpty) {
        bytes = Uint8List.fromList(res.data!);
      }
    } catch (_) {
      bytes = null;
    }
    // A newer speak() started while we were fetching — abandon quietly.
    if (myGeneration != _generation) return;

    // 2. No audio obtained (offline / quota / error) → phone voice, alone.
    if (bytes == null) {
      try {
        await _tts.speak(text);
      } catch (_) {}
      return;
    }

    // 3. Audio obtained → play it. If playback breaks midway, SILENCE the
    //    player first, then let the phone voice take over — never overlap.
    try {
      await _player.play(BytesSource(bytes));
      await _player.onPlayerComplete.first
          .timeout(const Duration(seconds: 90), onTimeout: () {});
    } catch (_) {
      await _player.stop();
      if (myGeneration == _generation) {
        try {
          await _tts.speak(text);
        } catch (_) {}
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }
}
