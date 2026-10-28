import 'package:flutter_tts/flutter_tts.dart';

/// Korean text-to-speech. Fails silently if the device has no ko-KR voice.
class Tts {
  Tts._();
  static final FlutterTts _tts = FlutterTts();
  // Share the in-flight initialization as well as the completed result. A bool
  // set before the first await let a quick tap call speak() before ko-KR had
  // actually been selected, which could result in silence on a cold start.
  static Future<void>? _initialization;
  static bool available = false;

  static Future<void> init() => _initialization ??= _configure();

  static Future<void> _configure() async {
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
      // Wait for the same setup started during app launch, rather than racing it.
      await init();
      await _tts.stop();
      // Reassert the language immediately before each utterance: some Android
      // engines reset their voice after stop() or when the app resumes.
      await _tts.setLanguage('ko-KR');
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
