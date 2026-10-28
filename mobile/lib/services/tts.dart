import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// How usable the device's speech engine currently is.
enum TtsStatus {
  /// [Tts.init] has not finished yet.
  pending,

  /// A Korean voice was found and the engine accepted it — audio should work.
  ready,

  /// The engine works, but it has no Korean voice installed. Korean text is
  /// still sent to the engine (multi-lingual voices do speak it) and the UI
  /// shows the written word as a fallback.
  missingVoice,

  /// The platform refused to start a speech engine at all.
  unavailable,
}

/// Korean text-to-speech.
///
/// Several things used to make this silently produce no sound on real devices:
///
/// 1. On Android 11+ the app cannot even see the TTS service without a
///    `<queries><intent><action android:name="android.intent.action.TTS_SERVICE"/>`
///    block in `AndroidManifest.xml` (see `setup.sh` / `setup.bat`).
/// 2. On iOS the default audio-session category is silenced by the ring/silent
///    switch, so speech needs an explicit `playback` category.
/// 3. A voice listed by `getLanguages` is not necessarily *installed*: calling
///    `setLanguage` with an unavailable locale makes `speak` a no-op, so the
///    word is verified with `isLanguageAvailable` and a `ko*` voice is used as
///    a fallback.
/// 4. Constructing the plugin (or any channel call) can hang or throw. Every
///    step below is wrapped with a timeout, so the UI can always fall back to
///    showing the word instead of sitting on "checking audio…".
///
/// Failures are recorded in [lastError] and published through [status] so the
/// UI can explain what happened rather than staying silent.
class Tts {
  Tts._();

  static FlutterTts? _engine;
  static Future<void>? _initFuture;

  static final ValueNotifier<TtsStatus> status = ValueNotifier<TtsStatus>(TtsStatus.pending);

  /// True while an utterance is actually being spoken (drives button feedback).
  static final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  /// Most recent platform error, if any. Handy in bug reports.
  static String? lastError;

  /// The Korean locale the engine accepted, re-applied before each utterance.
  static String? _selectedLocale;

  /// Whether speech is expected to be audible right now.
  static bool get available => status.value == TtsStatus.ready;

  /// Idempotent: concurrent callers share a single handshake.
  static Future<void> init() => _initFuture ??= _configure();

  static Future<void> _configure() async {
    try {
      await _configureEngine().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          lastError ??= 'TTS handshake timed out';
          if (status.value == TtsStatus.pending) status.value = TtsStatus.missingVoice;
        },
      );
    } catch (error) {
      lastError = '$error';
      status.value = TtsStatus.unavailable;
    }
  }

  static Future<void> _configureEngine() async {
    FlutterTts engine;
    try {
      engine = _engine ??= FlutterTts();
    } catch (error) {
      // No messenger / no plugin: nothing can ever be spoken on this platform.
      lastError = '$error';
      status.value = TtsStatus.unavailable;
      return;
    }

    engine.setStartHandler(() => speaking.value = true);
    engine.setCompletionHandler(() => speaking.value = false);
    engine.setCancelHandler(() => speaking.value = false);
    engine.setErrorHandler((message) {
      lastError = '$message';
      speaking.value = false;
    });

    // Report the engine's own result code instead of awaiting a whole
    // utterance: a stuck engine would otherwise block the caller forever.
    await _call((e) => e.awaitSpeakCompletion(false));

    // --- iOS / macOS: keep audio audible with the silent switch on ---------
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      await _call((e) => e.setSharedInstance(true));
      await _call((e) => e.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            <IosTextToSpeechAudioCategoryOptions>[
              IosTextToSpeechAudioCategoryOptions.duckOthers,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          ));
    }

    // --- Android: replace the queue instead of stacking utterances --------
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _call((e) => e.setQueueMode(0));
    }

    await _call((e) => e.setVolume(1));
    await _call((e) => e.setPitch(1));
    await _call((e) => e.setSpeechRate(0.45));

    final hasKorean = await _selectKoreanVoice();
    status.value = hasKorean ? TtsStatus.ready : TtsStatus.missingVoice;
  }

  /// Picks an installed Korean voice. Returns false when the device has none.
  static Future<bool> _selectKoreanVoice() async {
    for (final locale in const <String>['ko-KR', 'ko']) {
      if (_truthy(await _call((e) => e.isLanguageAvailable(locale)))) {
        if (_truthy(await _call((e) => e.setLanguage(locale)))) return true;
      }
    }

    // Some engines only expose the locale through their language list
    // (e.g. "ko-KR-language" on older Samsung builds).
    final languages = await _call((e) => e.getLanguages);
    if (languages is List) {
      for (final language in languages) {
        if (language.toString().toLowerCase().startsWith('ko')) {
          if (_truthy(await _call((e) => e.setLanguage(language.toString())))) {
            _selectedLocale = language.toString();
            return true;
          }
          break;
        }
      }
    }

    return false;
  }

  /// Speaks [text] and reports whether the engine accepted the request.
  ///
  /// Returns `false` (rather than throwing) so call sites can show a hint.
  static Future<bool> speak(String text, {double rate = 0.45}) async {
    final value = text.trim();
    if (value.isEmpty) return false;

    await init().timeout(const Duration(seconds: 8), onTimeout: () {});

    await _call((e) => e.stop());
    // Re-assert the voice before every utterance: some Android engines reset
    // their language after stop() or when the app resumes from the background.
    if (_selectedLocale != null) await _call((e) => e.setLanguage(_selectedLocale!));
    await _call((e) => e.setSpeechRate(rate));
    final result = await _call((e) => e.speak(value), timeout: const Duration(seconds: 3));

    final ok = _truthy(result);
    if (!ok) lastError ??= 'speak() returned $result';
    return ok;
  }

  static Future<void> stop() async {
    await _call((e) => e.stop());
    speaking.value = false;
  }

  /// Runs [body] against the engine, bounded by [timeout]. Returns null on any
  /// failure (missing plugin, platform exception or a hung engine).
  static Future<dynamic> _call(
    Future<dynamic> Function(FlutterTts engine) body, {
    Duration timeout = const Duration(milliseconds: 1200),
  }) async {
    try {
      return await body(_engine ??= FlutterTts()).timeout(timeout);
    } catch (error) {
      lastError = '$error';
      return null;
    }
  }

  /// Plugin results are `1` / `true` on success and `0` / `false` otherwise.
  static bool _truthy(Object? value) => value == true || value == 1 || value == '1';
}
