import 'package:flutter/material.dart';

import '../main.dart';
import '../services/tts.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<ReviewCard>? _deck; // snapshot for the current drill
  int _index = 0;
  bool _revealed = false;
  final List<AnswerEntry> _entries = [];
  bool _done = false;

  void _start(List<ReviewCard> deck) {
    setState(() {
      _deck = List.of(deck);
      _index = 0;
      _revealed = false;
      _entries.clear();
      _done = false;
    });
  }

  Future<void> _answer(bool correct) async {
    final deck = _deck!;
    _entries.add(AnswerEntry(deck[_index].card.id, correct, null));
    if (_index + 1 >= deck.length) {
      setState(() => _done = true);
      await AppScope.read(context).recordReview(List.of(_entries));
      return;
    }
    setState(() {
      _index += 1;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final live = state.review;

    if (_done) {
      final correct = _entries.where((e) => e.correct).length;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Panel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Ring(
                  value: correct / (_entries.isEmpty ? 1 : _entries.length) * 100,
                  size: 120,
                  stroke: 11,
                  color: context.hq.good,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$correct/${_entries.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
                      Text('RECALLED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: context.hq.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Review session finished', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('You earned $correct XP. Words you recalled 3 times are marked as mastered and drop out of the deck.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.hq.muted)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: live.isEmpty ? null : () => _start(live), child: const Text('Drill again')),
                ),
                TextButton(onPressed: () => setState(() { _done = false; _deck = null; }), child: const Text('Back')),
              ],
            ),
          ),
        ],
      );
    }

    if (_deck == null) {
      if (live.isEmpty) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: const [
            EmptyState(
              emoji: '🌱',
              title: 'Your review deck is empty',
              body: 'Words you answer incorrectly during lessons land here. Go play a lesson and this deck will fill up automatically.',
            ),
          ],
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Review Deck', sub: '${live.length} word${live.length == 1 ? '' : 's'} waiting', icon: Icons.favorite_rounded,
                    trailing: Pill('${state.profile.xpBalance} XP', icon: Icons.bolt_rounded, tone: PillTone.brand)),
                Text('Think of the meaning first, then reveal. Each recall pays 1 XP; three recalls in a row master the word.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: context.hq.muted)),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => _start(live), child: const Text('Start drill'))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final r in live)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.card.ko, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('${r.card.rom} · ${r.card.en}', style: TextStyle(fontSize: 11, color: context.hq.muted)),
                        ],
                      ),
                    ),
                    Pill('×${r.wrongCount}', tone: PillTone.bad),
                    const SizedBox(width: 8),
                    SpeakerButton(r.card.ko, size: 30),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    final deck = _deck!;
    final card = deck[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bar(value: _index / deck.length * 100, color: context.hq.good),
              const SizedBox(height: 8),
              Text('Card ${_index + 1} of ${deck.length} · missed ${card.wrongCount} time${card.wrongCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: context.hq.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Hangul(card.card.ko, size: 48),
              const SizedBox(height: 10),
              SpeakerButton(card.card.ko, size: 48),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _revealed = true);
                  Tts.speak(card.card.ko);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.hq.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.hq.line),
                  ),
                  child: _revealed
                      ? Column(children: [
                          Text(card.card.rom, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.cs.primary)),
                          Text(card.card.en, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ])
                      : Text('Think first, then tap to reveal', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.hq.muted)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_revealed)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: context.hq.bad, foregroundColor: Colors.white),
                  onPressed: () => _answer(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Still learning'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: context.hq.good, foregroundColor: Colors.white),
                  onPressed: () => _answer(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('I knew it'),
                ),
              ),
            ],
          )
        else
          OutlinedButton(onPressed: () => setState(() => _revealed = true), child: const Text('Reveal meaning')),
      ],
    );
  }
}
