import 'package:flutter_tts/flutter_tts.dart';

/// Korean text-to-speech. Fails silently if the device has no ko-KR voice.
class Tts {
  Tts._();
  static final FlutterTts _tts = FlutterTts();
  static bool _initialised = false;
  static bool available = false;

  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      final langs = await _tts.getLanguages;
      if (langs is List) {
        available = langs.any((l) => l.toString().toLowerCase().startsWith('ko'));
      }
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      available = false;
    }
  }

  static Future<void> speak(String text, {double rate = 0.45}) async {
    if (text.trim().isEmpty) return;
    try {
      await init();
      await _tts.stop();
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
