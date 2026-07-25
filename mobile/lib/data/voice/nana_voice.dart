import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
      debugPrint('[nana_voice] fetch ok: ${bytes?.length ?? 0} bytes');
    } catch (e) {
      debugPrint('[nana_voice] fetch FAILED: $e');
      bytes = null;
    }
    // A newer speak() started while we were fetching — abandon quietly.
    if (myGeneration != _generation) return;

    // 2. No audio obtained (offline / quota / error) → phone voice, alone.
    if (bytes == null) {
      debugPrint('[nana_voice] no audio -> phone TTS fallback');
      try {
        await _tts.speak(text);
      } catch (_) {}
      return;
    }

    // 3. Audio obtained → play it from a temp FILE (byte-source playback is
    //    unreliable on some Android builds). If playback still breaks,
    //    SILENCE the player first, then let the phone voice take over —
    //    never overlap.
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nana_voice_$myGeneration.mp3');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('[nana_voice] wrote ${file.path}');
      if (myGeneration != _generation) return;
      await _player.play(DeviceFileSource(file.path));
      debugPrint('[nana_voice] playback started');
      try {
        await _player.onPlayerComplete.first
            .timeout(const Duration(seconds: 90));
      } on TimeoutException {
        debugPrint('[nana_voice] gave up waiting for completion');
      }
      debugPrint('[nana_voice] playback completed');
      // Best-effort cleanup of this clip.
      try {
        await file.delete();
      } catch (_) {}
    } catch (e) {
      debugPrint('[nana_voice] playback FAILED: $e -> phone TTS fallback');
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
