import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/tts.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  state.load();
  Tts.init();
  runApp(HangulQuestApp(state: state));
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class HangulQuestApp extends StatelessWidget {
  final AppState state;
  const HangulQuestApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          title: 'Hangul Quest',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: state.profile.theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
          home: state.ready ? const HomeShell() : const _Splash(),
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(20)),
              child: const Text('한', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            const Text('Hangul Quest', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Loading your roadmap…', style: TextStyle(color: context.hq.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
