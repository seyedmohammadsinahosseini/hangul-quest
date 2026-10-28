import 'package:flutter_test/flutter_test.dart';
import 'package:hangul_quest/services/tts.dart';

/// Unit-level guarantees for the speech service. Kept in its own file so the
/// static engine state cannot leak between widget tests (each test file runs in
/// a fresh isolate).
void main() {
  test('speaking an empty string is a no-op', () async {
    expect(await Tts.speak('   '), isFalse);
  });

  test('init degrades instead of throwing when no engine is available', () async {
    // In this environment there is no platform implementation at all, which is
    // the worst case a device can hit: init must resolve and report a status.
    await Tts.init();

    expect(Tts.status.value, isNot(TtsStatus.pending));
    expect(Tts.status.value, isNot(TtsStatus.ready));
    expect(Tts.available, isFalse);
    expect(Tts.lastError, isNotNull);
  });

  test('a failed utterance reports false rather than throwing', () async {
    expect(await Tts.speak('안녕하세요'), isFalse);
  });
}
