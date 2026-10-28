import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangul_quest/main.dart';
import 'package:hangul_quest/screens/profile_screen.dart';
import 'package:hangul_quest/services/tts.dart';
import 'package:hangul_quest/state/app_state.dart';
import 'package:hangul_quest/theme.dart';
import 'package:hangul_quest/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// These tests pin down the two layout/audio bugs reported from a real device:
///
/// * "BOTTOM OVERFLOWED BY 3.1 PIXELS" under the four profile stats, and
/// * an audio button that did nothing and said nothing.
///
/// Both are regressions that a fixed `childAspectRatio` and a silent `catch`
/// make easy to reintroduce, so they are covered here.

Widget _host(Widget child, {double width = 320, double textScale = 1.0}) {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: inner!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  group('stat grid layout', () {
    testWidgets('4 tiles do not overflow on a narrow screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(
        StatGrid(const [
          StatTile('Accuracy', '92%'),
          StatTile('XP balance', '612'),
          StatTile('Correct answers', '431'),
          StatTile('Hints used', '18'),
        ]),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('4 tiles survive a 1.6x system font scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(
        textScale: 1.6,
        StatGrid(const [
          StatTile('Accuracy', '92%'),
          StatTile('XP balance', '1,204'),
          StatTile('Correct answers', '12,345'),
          StatTile('Hints used', '18'),
        ]),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('12,345'), findsOneWidget);
    });

    testWidgets('EvenGrid keeps mixed-height cards overflow-free', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(
        textScale: 1.4,
        EvenGrid(
          children: const [
            Panel(child: Text('First card')),
            Panel(child: Text('A second card with a longer label that wraps')),
            Panel(child: Text('Third')),
            Panel(child: Text('Fourth')),
          ],
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('audio feedback', () {
    testWidgets('a blocked voice reports why instead of failing silently', (tester) async {
      // No TTS plugin is registered in the widget-test environment, which is the
      // same situation as a phone with no usable Korean voice: the tap must
      // surface guidance rather than doing nothing.
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(
        const Center(child: SpeakerButton('안녕하세요', size: 48)),
      ));

      // Let the engine handshake finish so the button knows audio is unusable.
      Tts.init();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(Tts.status.value, isNot(TtsStatus.ready));

      await tester.tap(find.byType(SpeakerButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Korean voice'), findsOneWidget);

      // Let the background retry finish so no fake timer outlives the test.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });

  });

  group('the reported screen', () {
    testWidgets('the "You" tab renders its four stats without overflow', (tester) async {
      // 411 dp wide is a Pixel-class phone: the size the "BOTTOM OVERFLOWED BY
      // 3.1 PIXELS" report came from.
      await tester.binding.setSurfaceSize(const Size(411, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final state = AppState();
      await state.load();

      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final label in ['ACCURACY', 'XP BALANCE', 'CORRECT ANSWERS', 'HINTS USED']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('the same screen survives a large system font', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final state = AppState();
      await state.load();

      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
