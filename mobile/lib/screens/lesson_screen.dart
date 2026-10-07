import 'dart:math';

import 'package:flutter/material.dart';

import '../data/curriculum_data.dart';
import '../logic/hangul.dart';
import '../logic/quiz_engine.dart';
import '../main.dart';
import '../models/curriculum.dart';
import '../services/tts.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

enum _Phase { learn, practice, results }

class HintFlags {
  final bool small;
  final bool medium;
  final bool large;
  const HintFlags({this.small = false, this.medium = false, this.large = false});
  HintFlags copyWith({bool? small, bool? medium, bool? large}) =>
      HintFlags(small: small ?? this.small, medium: medium ?? this.medium, large: large ?? this.large);
  HintTier? get used => large ? HintTier.large : (medium ? HintTier.medium : (small ? HintTier.small : null));
}

List<T> _shuffled<T>(List<T> list) {
  final out = List<T>.from(list);
  out.shuffle(Random());
  return out;
}

class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Lesson lesson;
  int _attempt = 1;
  late Session _session;
  late List<Question> _questions;
  late _Phase _phase;
  int _learnIndex = 0;
  int _qIndex = 0;
  final List<AnswerEntry> _answers = [];
  HintFlags _hints = const HintFlags();
  bool _busy = false;
  LessonResult? _result;

  @override
  void initState() {
    super.initState();
    lesson = getLesson(widget.lessonId)!;
    _build();
  }

  void _build() {
    _session = buildSession(lesson, attempt: _attempt);
    _questions = _session.all;
    _phase = lesson.mode == LessonMode.test ? _Phase.practice : _Phase.learn;
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    final res = await AppScope.read(context).recordLesson(lesson.id, List.of(_answers));
    if (!mounted) return;
    setState(() {
      _result = res;
      _phase = _Phase.results;
      _busy = false;
    });
  }

  void _onAnswered(bool correct) {
    final q = _questions[_qIndex];
    _answers.add(AnswerEntry(q.cardId, correct, _hints.used));
  }

  void _next() {
    if (_qIndex + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() {
      _qIndex += 1;
      _hints = const HintFlags();
    });
  }

  Future<void> _buyHint(HintTier tier) async {
    final err = await AppScope.read(context).buyHint(tier);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() {
      switch (tier) {
        case HintTier.small:
          _hints = _hints.copyWith(small: true);
        case HintTier.medium:
          _hints = _hints.copyWith(medium: true);
        case HintTier.large:
          _hints = _hints.copyWith(large: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('-${hintCost[tier]} XP · hint unlocked'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1200),
    ));
  }

  void _retry() {
    setState(() {
      _attempt += 1;
      _answers.clear();
      _qIndex = 0;
      _learnIndex = 0;
      _hints = const HintFlags();
      _result = null;
      _build();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locked = state.statusOf(lesson.id) == LessonStatus.locked;

    Widget body;
    if (locked) {
      body = _LockedView(lesson: lesson);
    } else if (_phase == _Phase.learn) {
      body = _LearnPhase(
        lesson: lesson,
        index: _learnIndex,
        onNext: () {
          if (_learnIndex + 1 >= lesson.cards.length) {
            setState(() => _phase = _Phase.practice);
          } else {
            setState(() => _learnIndex += 1);
          }
        },
        onBack: () => setState(() => _learnIndex = max(0, _learnIndex - 1)),
        onSkip: () => setState(() => _phase = _Phase.practice),
      );
    } else if (_phase == _Phase.results && _result != null) {
      body = _ResultsPhase(
        lesson: lesson,
        result: _result!,
        answers: _answers,
        nextLessonId: _result!.passed ? state.nextAfter(lesson.id) : null,
        onRetry: _retry,
      );
    } else {
      final q = _questions[_qIndex];
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(child: Bar(value: _qIndex / _questions.length * 100)),
              const SizedBox(width: 10),
              Text('${_qIndex + 1}/${_questions.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.hq.muted)),
              const SizedBox(width: 10),
              Pill('${state.profile.xpBalance}', icon: Icons.bolt_rounded, tone: PillTone.brand),
            ],
          ),
          const SizedBox(height: 12),
          _QuestionCard(
            key: ValueKey('${_attempt}:${q.id}'),
            question: q,
            hints: _hints,
            busy: _busy,
            xpBalance: state.profile.xpBalance,
            onAnswered: _onAnswered,
            onNext: _next,
            onHint: _buyHint,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(modeHelp(lesson.mode), style: TextStyle(fontSize: 11, color: context.hq.muted)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Pill('pass ${lesson.passScore}%', icon: Icons.track_changes_rounded),
          ),
        ],
      ),
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Locked
// ---------------------------------------------------------------------------

class _LockedView extends StatelessWidget {
  final Lesson lesson;
  const _LockedView({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Panel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: context.hq.warnSoft, borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.lock_rounded, color: context.hq.warn),
            ),
            const SizedBox(height: 12),
            const Text('This lesson is still locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Finish the lesson before it and score at least 70% to open this one.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.hq.muted)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to the roadmap')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Learn phase
// ---------------------------------------------------------------------------

class _LearnPhase extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  const _LearnPhase({required this.lesson, required this.index, required this.onNext, required this.onBack, required this.onSkip});

  @override
  State<_LearnPhase> createState() => _LearnPhaseState();
}

class _LearnPhaseState extends State<_LearnPhase> {
  bool _reveal = false;

  @override
  void initState() {
    super.initState();
    Tts.speak(widget.lesson.cards[widget.index].ko);
  }

  @override
  void didUpdateWidget(covariant _LearnPhase old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _reveal = false;
      Tts.speak(widget.lesson.cards[widget.index].ko);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.lesson.cards[widget.index];
    final total = widget.lesson.cards.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: Bar(value: (widget.index + 1) / total * 100, color: context.hq.good)),
            const SizedBox(width: 10),
            Text('${widget.index + 1}/$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.hq.muted)),
          ],
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('NEW CARD · ${widget.lesson.title.toUpperCase()}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.6, color: context.hq.muted)),
              const SizedBox(height: 16),
              Hangul(card.ko, size: card.ko.length > 6 ? 36 : 60),
              const SizedBox(height: 12),
              SpeakerButton(card.ko, size: 48),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _reveal = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.hq.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.hq.line),
                  ),
                  child: _reveal
                      ? Column(children: [
                          Text(card.rom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.cs.primary)),
                          Text(card.en, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ])
                      : Text('Tap to reveal meaning', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.hq.muted)),
                ),
              ),
              if (card.jamo != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final piece in card.jamo!)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: context.hq.surface2, borderRadius: BorderRadius.circular(8)),
                        child: Text(piece, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
              ],
              if (card.note != null) ...[
                const SizedBox(height: 12),
                Text(card.note!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.hq.muted)),
              ],
              if (card.example != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.hq.surface2, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.example!.ko, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            Text(card.example!.rom, style: TextStyle(fontSize: 11, color: context.hq.muted)),
                            const SizedBox(height: 4),
                            Text(card.example!.en, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      SpeakerButton(card.example!.ko, size: 30),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.index == 0 ? null : widget.onBack,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Back'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: widget.onNext,
                child: Text(widget.index + 1 == total ? 'Start the quiz' : 'Next card'),
              ),
            ),
          ],
        ),
        TextButton(onPressed: widget.onSkip, child: const Text('I know these — skip to the quiz')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Question card
// ---------------------------------------------------------------------------

class _QuestionCard extends StatefulWidget {
  final Question question;
  final HintFlags hints;
  final bool busy;
  final int xpBalance;
  final void Function(bool correct) onAnswered;
  final VoidCallback onNext;
  final void Function(HintTier) onHint;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.hints,
    required this.busy,
    required this.xpBalance,
    required this.onAnswered,
    required this.onNext,
    required this.onHint,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _answered = false;
  bool _correct = false;

  void _settle(bool correct) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _correct = correct;
    });
    widget.onAnswered(correct);
    if (widget.question.type == QType.listen && widget.question.reveal != null) {
      Tts.speak(widget.question.reveal!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    Widget round;
    switch (q.type) {
      case QType.match:
        round = _MatchRound(question: q, answered: _answered, onSettle: _settle);
      case QType.builder:
        round = _BuilderRound(question: q, answered: _answered, hints: widget.hints, onSettle: _settle);
      case QType.order:
        round = _OrderRound(question: q, answered: _answered, hints: widget.hints, onSettle: _settle);
      case QType.typeRom:
        round = _TypeRound(question: q, answered: _answered, hints: widget.hints, onSettle: _settle);
      default:
        round = _ChoiceRound(question: q, answered: _answered, hints: widget.hints, onSettle: _settle);
    }

    return Column(
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.instruction.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: context.cs.primary)),
              const SizedBox(height: 8),
              round,
              if (widget.hints.medium) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.hq.brandSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COACH HINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: context.cs.primary)),
                      Text(q.rom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      if (q.note != null) Text(q.note!, style: TextStyle(fontSize: 12, color: context.hq.muted)),
                    ],
                  ),
                ),
              ],
              if (_answered) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_correct ? context.hq.goodSoft : context.hq.badSoft).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (_correct ? context.hq.good : context.hq.bad).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: _correct ? context.hq.good : context.hq.bad, shape: BoxShape.circle),
                          child: Icon(_correct ? Icons.check_rounded : Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(_correct ? 'Correct!' : 'Not quite', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.answerText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                Text('${q.rom} · ${q.en}', style: TextStyle(fontSize: 12, color: context.hq.muted)),
                                if (q.note != null) Text(q.note!, style: TextStyle(fontSize: 11, color: context.hq.muted)),
                              ],
                            ),
                          ),
                          if (q.answerText.isNotEmpty) SpeakerButton(q.answerText),
                        ],
                      ),
                      if (widget.hints.used != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Hint used — this question pays no XP.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.hq.warn)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: widget.busy ? null : widget.onNext, child: Text(widget.busy ? 'Saving…' : 'Continue')),
                ),
              ],
            ],
          ),
        ),
        if (!_answered) ...[
          const SizedBox(height: 12),
          _HintBar(xpBalance: widget.xpBalance, hints: widget.hints, onHint: widget.onHint, disabled: widget.busy),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Choice (mc & listen)
// ---------------------------------------------------------------------------

class _ChoiceRound extends StatefulWidget {
  final Question question;
  final bool answered;
  final HintFlags hints;
  final void Function(bool) onSettle;
  const _ChoiceRound({required this.question, required this.answered, required this.hints, required this.onSettle});

  @override
  State<_ChoiceRound> createState() => _ChoiceRoundState();
}

class _ChoiceRoundState extends State<_ChoiceRound> {
  String? _picked;
  String? _eliminated;

  List<Option> get _options => widget.question.options ?? const [];

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    if (q.type == QType.listen) {
      if (q.reveal != null) Tts.speak(q.reveal!);
    } else if (q.promptIsKorean) {
      Tts.speak(q.prompt);
    }
  }

  @override
  void didUpdateWidget(covariant _ChoiceRound old) {
    super.didUpdateWidget(old);
    if (widget.hints.small && !old.hints.small && _eliminated == null) {
      final wrong = _options.where((o) => !o.correct).toList();
      if (wrong.isNotEmpty) setState(() => _eliminated = wrong.first.key);
    }
    if (widget.hints.large && !old.hints.large && !widget.answered) {
      final key = _options.where((o) => o.correct).firstOrNull?.key;
      if (key != null) {
        setState(() => _picked = key);
        WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettle(true);
      });
      }
    }
  }

  void _choose(Option o) {
    if (widget.answered) return;
    setState(() => _picked = o.key);
    widget.onSettle(o.correct);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final twoCol = q.type != QType.mcRom && _options.every((o) => o.text.length <= 14);
    final replay = q.type == QType.listen ? (q.reveal ?? '') : q.prompt;

    Widget prompt;
    if (q.type == QType.listen && Tts.available) {
      prompt = Column(children: [
        const SizedBox(height: 8),
        Material(
          color: context.cs.primary,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Tts.speak(replay),
            child: const SizedBox(width: 80, height: 80, child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 36)),
          ),
        ),
        const SizedBox(height: 6),
        Text('Tap to replay the audio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.hq.muted)),
        const SizedBox(height: 8),
      ]);
    } else if (q.type == QType.listen) {
      prompt = Column(children: [
        Hangul(replay, size: 36),
        Text('No Korean voice on this device — read the word instead of listening.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.hq.muted)),
        const SizedBox(height: 8),
      ]);
    } else {
      prompt = Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Hangul(q.prompt, size: q.prompt.length > 8 ? 22 : 40)),
            if (q.promptIsKorean) ...[const SizedBox(width: 10), SpeakerButton(q.prompt)],
          ],
        ),
      );
    }

    final tiles = <Widget>[];
    for (final o in _options) {
      final isRight = widget.answered && o.correct;
      final isWrongPick = widget.answered && _picked == o.key && !o.correct;
      Color bg = context.hq.surface2;
      Color border = context.hq.line;
      Color? fg;
      if (isRight) {
        bg = context.hq.goodSoft;
        border = context.hq.good;
        fg = context.hq.good;
      } else if (isWrongPick) {
        bg = context.hq.badSoft;
        border = context.hq.bad;
        fg = context.hq.bad;
      }
      if (_eliminated == o.key && !widget.answered) {
        tiles.add(Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: context.hq.line)),
          child: Text('removed', style: TextStyle(fontSize: 11, color: context.hq.muted)),
        ));
        continue;
      }
      tiles.add(Opacity(
        opacity: widget.answered && !isRight && !isWrongPick ? 0.55 : 1,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.answered ? null : () => _choose(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              alignment: Alignment.center,
              child: Text(o.text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
            ),
          ),
        ),
      ));
    }

    return Column(
      children: [
        prompt,
        if (twoCol)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: tiles,
          )
        else
          Column(children: [for (final t in tiles) Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: t))]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Type the romanization
// ---------------------------------------------------------------------------

class _TypeRound extends StatefulWidget {
  final Question question;
  final bool answered;
  final HintFlags hints;
  final void Function(bool) onSettle;
  const _TypeRound({required this.question, required this.answered, required this.hints, required this.onSettle});

  @override
  State<_TypeRound> createState() => _TypeRoundState();
}

class _TypeRoundState extends State<_TypeRound> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Tts.speak(widget.question.prompt);
  }

  @override
  void didUpdateWidget(covariant _TypeRound old) {
    super.didUpdateWidget(old);
    if (widget.hints.large && !old.hints.large && !widget.answered) {
      _ctrl.text = widget.question.rom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettle(true);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _check() {
    if (widget.answered || _ctrl.text.trim().isEmpty) return;
    widget.onSettle(isRomanAccepted(_ctrl.text, widget.question.rom));
  }

  @override
  Widget build(BuildContext context) {
    final rom = widget.question.rom;
    final preview = widget.hints.small ? '${rom.substring(0, max(1, rom.length ~/ 2))}…' : null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Hangul(widget.question.prompt, size: 42), const SizedBox(width: 10), SpeakerButton(widget.question.prompt)],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: !widget.answered,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(hintText: 'Type the romanization…'),
                onSubmitted: (_) => _check(),
              ),
            ),
            if (!widget.answered) ...[const SizedBox(width: 8), FilledButton(onPressed: _check, child: const Text('Check'))],
          ],
        ),
        if (preview != null && !widget.answered)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('Starts with “$preview”', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.hq.warn))),
        Padding(padding: const EdgeInsets.only(top: 8), child: Text('Spaces and hyphens are ignored.', style: TextStyle(fontSize: 11, color: context.hq.muted))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Syllable builder
// ---------------------------------------------------------------------------

class _BuilderRound extends StatefulWidget {
  final Question question;
  final bool answered;
  final HintFlags hints;
  final void Function(bool) onSettle;
  const _BuilderRound({required this.question, required this.answered, required this.hints, required this.onSettle});

  @override
  State<_BuilderRound> createState() => _BuilderRoundState();
}

class _BuilderRoundState extends State<_BuilderRound> {
  late final List<Option> _choices;
  final List<String> _pickedKeys = [];

  List<String> get _target => widget.question.targetJamo ?? const [];
  List<String> get _picked => _pickedKeys.map((k) => _choices.firstWhere((c) => c.key == k).text).toList();

  @override
  void initState() {
    super.initState();
    _choices = _shuffled(widget.question.jamoChoices ?? const []);
  }

  @override
  void didUpdateWidget(covariant _BuilderRound old) {
    super.didUpdateWidget(old);
    if (widget.hints.small && !old.hints.small && _pickedKeys.isEmpty && _target.isNotEmpty) {
      final first = _choices.where((c) => c.correct && c.text == _target[0]).firstOrNull;
      if (first != null) setState(() => _pickedKeys.add(first.key));
    }
    if (widget.hints.large && !old.hints.large && !widget.answered) {
      setState(() {
        _pickedKeys
          ..clear()
          ..addAll(_target.map((t) => _choices.where((c) => c.correct && c.text == t).firstOrNull?.key).whereType<String>());
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettle(true);
      });
    }
  }

  void _tap(Option c) {
    if (widget.answered || _pickedKeys.contains(c.key)) return;
    setState(() => _pickedKeys.add(c.key));
    if (_picked.length == _target.length) {
      widget.onSettle(_picked.join() == _target.join());
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _picked.isEmpty ? '' : composeSyllable(_picked);
    final remaining = _target.length - _picked.length;
    return Column(
      children: [
        Text('Build the block that sounds like', style: TextStyle(fontSize: 12, color: context.hq.muted)),
        Text(widget.question.en, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.cs.primary)),
        Text('/${widget.question.rom}/', style: TextStyle(fontSize: 12, color: context.hq.muted)),
        const SizedBox(height: 12),
        Container(
          height: 90,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.hq.surface2.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.hq.line, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (preview.isEmpty)
                Text('Tap the letters in order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.hq.muted))
              else
                Hangul(preview, size: 52),
              for (var i = 0; i < max(0, remaining); i++)
                Container(
                  width: 28,
                  height: 36,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.hq.line)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            for (final c in _choices)
              Opacity(
                opacity: _pickedKeys.contains(c.key) ? 0.4 : 1,
                child: Material(
                  color: context.cs.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.hq.line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _tap(c),
                    child: Center(child: Text(c.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                  ),
                ),
              ),
          ],
        ),
        if (!widget.answered && _pickedKeys.isNotEmpty)
          TextButton(onPressed: () => setState(_pickedKeys.clear), child: const Text('Clear')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sentence order
// ---------------------------------------------------------------------------

class _OrderRound extends StatefulWidget {
  final Question question;
  final bool answered;
  final HintFlags hints;
  final void Function(bool) onSettle;
  const _OrderRound({required this.question, required this.answered, required this.hints, required this.onSettle});

  @override
  State<_OrderRound> createState() => _OrderRoundState();
}

class _OrderRoundState extends State<_OrderRound> {
  late final List<String> _chips;
  final List<int> _picked = []; // indices into _chips

  List<String> get _target => widget.question.order ?? const [];

  @override
  void initState() {
    super.initState();
    _chips = _shuffled(_target);
  }

  @override
  void didUpdateWidget(covariant _OrderRound old) {
    super.didUpdateWidget(old);
    if (widget.hints.small && !old.hints.small && _picked.isEmpty && _target.isNotEmpty) {
      final i = _chips.indexOf(_target[0]);
      if (i >= 0) setState(() => _picked.add(i));
    }
    if (widget.hints.large && !old.hints.large && !widget.answered) {
      setState(() {
        _picked.clear();
        final used = <int>{};
        for (final t in _target) {
          for (var i = 0; i < _chips.length; i++) {
            if (_chips[i] == t && !used.contains(i)) {
              used.add(i);
              _picked.add(i);
              break;
            }
          }
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettle(true);
      });
    }
  }

  void _check() {
    if (widget.answered || _picked.length != _target.length) return;
    final built = _picked.map((i) => _chips[i]).join(' ');
    widget.onSettle(built == _target.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.hq.surface2, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text('Translate into Korean', style: TextStyle(fontSize: 12, color: context.hq.muted)),
            Text(widget.question.en, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            Text(widget.question.rom, style: TextStyle(fontSize: 11, color: context.hq.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.hq.surface2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.hq.line, width: 2),
          ),
          child: _picked.isEmpty
              ? Center(child: Text('Tap the chunks in the right order…', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.hq.muted)))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var k = 0; k < _picked.length; k++)
                      _Chip(
                        text: _chips[_picked[k]],
                        selected: true,
                        onTap: widget.answered ? null : () => setState(() => _picked.removeAt(k)),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _chips.length; i++)
              Opacity(
                opacity: _picked.contains(i) ? 0.35 : 1,
                child: _Chip(
                  text: _chips[i],
                  selected: false,
                  onTap: widget.answered || _picked.contains(i) ? null : () => setState(() => _picked.add(i)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!widget.answered)
          FilledButton(onPressed: _picked.length == _target.length ? _check : null, child: const Text('Check sentence')),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _Chip({required this.text, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.hq.brandSoft : context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? context.cs.primary.withValues(alpha: 0.4) : context.hq.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? context.hq.brandFg : null)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Matching game
// ---------------------------------------------------------------------------

class _MatchRound extends StatefulWidget {
  final Question question;
  final bool answered;
  final void Function(bool) onSettle;
  const _MatchRound({required this.question, required this.answered, required this.onSettle});

  @override
  State<_MatchRound> createState() => _MatchRoundState();
}

class _MatchRoundState extends State<_MatchRound> {
  late final List<String> _ko;
  late final List<String> _en;
  String? _selKo;
  String? _selEn;
  final Set<String> _matched = {};
  int _errors = 0;
  String? _wrongKo;
  String? _wrongEn;

  List<MatchPair> get _pairs => widget.question.pairs ?? const [];

  @override
  void initState() {
    super.initState();
    _ko = _shuffled(_pairs.map((p) => p.ko).toList());
    _en = _shuffled(_pairs.map((p) => p.en).toList());
  }

  void _try() {
    if (_selKo == null || _selEn == null || widget.answered) return;
    final pair = _pairs.firstWhere((p) => p.ko == _selKo);
    if (pair.en == _selEn) {
      setState(() {
        _matched.add(_selKo!);
        _selKo = null;
        _selEn = null;
      });
      Tts.speak(pair.ko);
      if (_matched.length == _pairs.length) widget.onSettle(_errors <= 1);
    } else {
      setState(() {
        _errors += 1;
        _wrongKo = _selKo;
        _wrongEn = _selEn;
      });
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() {
          _wrongKo = null;
          _wrongEn = null;
          _selKo = null;
          _selEn = null;
        });
      });
    }
  }

  Widget _tile(String text, {required bool done, required bool wrong, required bool selected, required VoidCallback onTap}) {
    Color bg = context.hq.surface2;
    Color border = context.hq.line;
    Color? fg;
    if (done) {
      bg = context.hq.goodSoft;
      border = context.hq.good;
      fg = context.hq.good;
    } else if (wrong) {
      bg = context.hq.badSoft;
      border = context.hq.bad;
      fg = context.hq.bad;
    } else if (selected) {
      bg = context.hq.brandSoft;
      border = context.cs.primary;
      fg = context.hq.brandFg;
    }
    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: done || widget.answered ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            alignment: Alignment.center,
            child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_matched.length}/${_pairs.length} pairs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.hq.muted)),
            Text('$_errors mistake${_errors == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _errors > 1 ? context.hq.bad : context.hq.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                for (final k in _ko)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _tile(k, done: _matched.contains(k), wrong: _wrongKo == k, selected: _selKo == k, onTap: () {
                      setState(() => _selKo = k);
                      _try();
                    }),
                  ),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(children: [
                for (final e in _en)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _tile(
                      e,
                      done: _pairs.any((p) => p.en == e && _matched.contains(p.ko)),
                      wrong: _wrongEn == e,
                      selected: _selEn == e,
                      onTap: () {
                        setState(() => _selEn = e);
                        _try();
                      },
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hint bar
// ---------------------------------------------------------------------------

class _HintBar extends StatelessWidget {
  final int xpBalance;
  final HintFlags hints;
  final void Function(HintTier) onHint;
  final bool disabled;
  const _HintBar({required this.xpBalance, required this.hints, required this.onHint, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final items = [
      (HintTier.small, '50 / 50', 'remove a wrong option', hints.small),
      (HintTier.medium, 'Coach', 'sound + note', hints.medium),
      (HintTier.large, 'Reveal', 'show the answer', hints.large),
    ];
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: context.cs.primary),
              const SizedBox(width: 6),
              Text('HINTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: context.hq.muted)),
              const Spacer(),
              Pill('$xpBalance XP available', icon: Icons.bolt_rounded, tone: PillTone.brand),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Builder(builder: (context) {
                    final (tier, label, desc, used) = items[i];
                    final cost = hintCost[tier]!;
                    final afford = xpBalance >= cost;
                    final enabled = !disabled && !used && afford;
                    return Opacity(
                      opacity: enabled ? 1 : 0.45,
                      child: Material(
                        color: afford && !used ? context.hq.brandSoft.withValues(alpha: 0.4) : context.hq.surface2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: afford && !used ? context.cs.primary.withValues(alpha: 0.4) : context.hq.line),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: enabled ? () => onHint(tier) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.bolt_rounded, size: 12, color: context.cs.primary),
                                  Text('$cost XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: context.cs.primary)),
                                ]),
                                const SizedBox(height: 2),
                                Text(used ? 'Used' : label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                                Text(desc, style: TextStyle(fontSize: 10, height: 1.2, color: context.hq.muted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text('Earn 1 XP per correct answer · a hinted question pays nothing', style: TextStyle(fontSize: 10, color: context.hq.muted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _ResultsPhase extends StatelessWidget {
  final Lesson lesson;
  final LessonResult result;
  final List<AnswerEntry> answers;
  final String? nextLessonId;
  final VoidCallback onRetry;
  const _ResultsPhase({required this.lesson, required this.result, required this.answers, required this.nextLessonId, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final missedIds = <String>{for (final a in answers) if (!a.correct) a.cardId};
    final missed = missedIds.map((id) => cardById[id]).whereType<KCard>().toList();
    final next = nextLessonId == null ? null : getLesson(nextLessonId!);
    final color = result.passed ? context.hq.good : context.hq.bad;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Panel(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Ring(
                value: result.score.toDouble(),
                size: 132,
                stroke: 12,
                color: color,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${result.score}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
                  Text('${result.correct}/${result.total} CORRECT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: context.hq.muted)),
                ]),
              ),
              const SizedBox(height: 14),
              Text(result.passed ? 'Lesson passed!' : 'Not yet — 70% needed', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                result.passed
                    ? 'You scored ${result.score}% on “${lesson.title}”. The next lesson is unlocked.'
                    : 'You scored ${result.score}%. Replay this lesson and reach ${lesson.passScore}% to unlock what comes next.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.hq.muted),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                Pill('+${result.xpGained} XP earned', icon: Icons.bolt_rounded, tone: PillTone.brand),
                Pill(result.passed ? 'unlocked' : 'locked', icon: result.passed ? Icons.check_rounded : Icons.close_rounded, tone: result.passed ? PillTone.good : PillTone.bad),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (missed.isNotEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WORDS TO REVIEW (${missed.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: context.hq.muted)),
                const SizedBox(height: 8),
                for (final c in missed.take(8))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: context.hq.surface2, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.ko, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          Text('${c.rom} · ${c.en}', style: TextStyle(fontSize: 11, color: context.hq.muted)),
                        ]),
                      ),
                      SpeakerButton(c.ko, size: 30),
                    ]),
                  ),
                Text('These words were added to your Review Deck.', style: TextStyle(fontSize: 11, color: context.hq.muted)),
              ],
            ),
          )
        else
          Panel(child: Center(child: Text('Perfect run — nothing to review.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: context.hq.good)))),
        const SizedBox(height: 12),
        if (next != null)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LessonScreen(lessonId: next.id))),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Next: ${next.title}'),
          ),
        const SizedBox(height: 8),
        if (next != null)
          OutlinedButton(onPressed: onRetry, child: Text('Retry “${lesson.title}”'))
        else
          FilledButton(onPressed: onRetry, child: Text('Retry “${lesson.title}”')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to the roadmap')),
      ],
    );
  }
}
