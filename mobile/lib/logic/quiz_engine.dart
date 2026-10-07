/// Question generation for one lesson run. Deterministic per (lesson, attempt).
library;

import 'dart:math';

import '../data/curriculum_data.dart';
import '../logic/hangul.dart';
import '../models/curriculum.dart';

enum QType { mcKoEn, mcEnKo, mcRom, listen, typeRom, builder, match, order }

class Option {
  final String key;
  final String text;
  final bool correct;
  const Option(this.key, this.text, this.correct);
}

class MatchPair {
  final String ko;
  final String en;
  const MatchPair(this.ko, this.en);
}

class Question {
  final String id;
  final String cardId;
  final QType type;
  final String instruction;
  final String prompt;
  final bool promptIsKorean;
  final String rom;
  final String en;
  final String? note;
  final List<Option>? options;
  final List<Option>? jamoChoices;
  final List<String>? targetJamo;
  final List<String>? order;
  final List<MatchPair>? pairs;

  /// Korean hidden behind a listening question.
  final String? reveal;

  const Question({
    required this.id,
    required this.cardId,
    required this.type,
    required this.instruction,
    required this.prompt,
    required this.promptIsKorean,
    required this.rom,
    required this.en,
    this.note,
    this.options,
    this.jamoChoices,
    this.targetJamo,
    this.order,
    this.pairs,
    this.reveal,
  });

  /// The Korean answer shown in feedback.
  String get answerText {
    switch (type) {
      case QType.order:
        return order?.join(' ') ?? en;
      case QType.builder:
        return composeSyllable(targetJamo ?? const []);
      case QType.listen:
        return reveal ?? en;
      case QType.mcEnKo:
        return options?.where((o) => o.correct).firstOrNull?.text ?? en;
      default:
        return prompt.isEmpty ? en : prompt;
    }
  }
}

class Session {
  final String lessonId;
  final int attempt;
  final List<Question> matchRounds;
  final List<Question> questions;
  Session(this.lessonId, this.attempt, this.matchRounds, this.questions);
  List<Question> get all => [...matchRounds, ...questions];
}

int _hash(String s) {
  var h = 2166136261;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0x7FFFFFFF;
  }
  return h;
}

List<T> _shuffle<T>(List<T> list, Random rnd) {
  final out = List<T>.from(list);
  for (var i = out.length - 1; i > 0; i--) {
    final k = rnd.nextInt(i + 1);
    final tmp = out[i];
    out[i] = out[k];
    out[k] = tmp;
  }
  return out;
}

List<T> _pick<T>(List<T> list, int n, Random rnd) =>
    _shuffle(list, rnd).take(n).toList();

String normalizeRoman(String input) =>
    input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Loose match: ignores spaces/hyphens and tolerates classic eo/o, eu/u slips.
bool isRomanAccepted(String input, String answer) {
  final a = normalizeRoman(input);
  final b = normalizeRoman(answer);
  if (a.isEmpty) return false;
  if (a == b) return true;
  final variants = <String>{
    b,
    b.replaceAll('eo', 'o'),
    b.replaceAll('eo', 'u'),
    b.replaceAll('eu', 'u'),
    b.replaceAll('o', 'eo'),
  };
  return variants.contains(a);
}

String _field(KCard c, String f) {
  switch (f) {
    case 'ko':
      return c.ko;
    case 'rom':
      return c.rom;
    default:
      return c.en;
  }
}

List<Option> _buildOptions(KCard card, List<KCard> pool, String field, Random rnd,
    {int count = 4}) {
  final mine = _field(card, field);
  final others =
      pool.where((c) => c.id != card.id && _field(c, field) != mine).toList();
  final wrong = _pick(others, count - 1, rnd);
  final options = <Option>[
    Option('${card.id}-t', mine, true),
    ...wrong.map((c) => Option(c.id, _field(c, field), false)),
  ];
  return _shuffle(options, rnd);
}

QType _typeFor(KCard card, LessonMode mode, Random rnd) {
  if (mode == LessonMode.builder && card.jamo != null) return QType.builder;
  final hasParts = card.parts != null && card.parts!.length > 1;
  if (hasParts && rnd.nextDouble() < 0.75) return QType.order;
  if (card.jamo != null && rnd.nextDouble() < 0.4) return QType.builder;

  final roll = rnd.nextDouble();
  if (mode == LessonMode.test) {
    if (roll < 0.2) return QType.listen;
    if (roll < 0.4) return QType.mcEnKo;
    if (roll < 0.55) return QType.typeRom;
    if (roll < 0.7) return QType.mcRom;
    return QType.mcKoEn;
  }
  if (mode == LessonMode.sentences) {
    return roll < 0.7 && card.parts != null ? QType.order : QType.mcEnKo;
  }
  if (roll < 0.15) return QType.listen;
  if (roll < 0.35) return QType.mcEnKo;
  if (roll < 0.5) return QType.mcRom;
  if (roll < 0.62 && card.parts == null) return QType.typeRom;
  return QType.mcKoEn;
}

const Map<QType, String> _instructions = {
  QType.mcKoEn: 'What does this mean?',
  QType.mcEnKo: 'Choose the correct Korean.',
  QType.mcRom: 'How is this pronounced?',
  QType.listen: 'Listen and choose the meaning.',
  QType.typeRom: 'Type the romanization.',
  QType.builder: 'Build the syllable block.',
  QType.match: 'Match every pair.',
  QType.order: 'Put the words in order.',
};

Question _make(KCard card, List<KCard> pool, QType type, Random rnd, int index) {
  final id = 'q$index';
  switch (type) {
    case QType.builder:
      final target = card.jamo ?? const ['ㅇ', 'ㅏ'];
      final decoys = _pick(
          allJamoForDecoys.where((x) => !target.contains(x)).toList(), 3, rnd);
      final choices = _shuffle(<Option>[
        for (var i = 0; i < target.length; i++)
          Option('${card.id}-j$i', target[i], true),
        for (var i = 0; i < decoys.length; i++)
          Option('${card.id}-d$i', decoys[i], false),
      ], rnd);
      return Question(
        id: id,
        cardId: card.id,
        type: type,
        instruction: _instructions[type]!,
        prompt: card.en,
        promptIsKorean: false,
        rom: card.rom,
        en: card.en,
        note: card.note,
        jamoChoices: choices,
        targetJamo: target,
      );
    case QType.order:
      final parts = (card.parts != null && card.parts!.length > 1)
          ? card.parts!
          : <String>[card.ko];
      return Question(
        id: id,
        cardId: card.id,
        type: type,
        instruction: _instructions[type]!,
        prompt: card.en,
        promptIsKorean: false,
        rom: card.rom,
        en: card.en,
        note: card.note,
        order: parts,
      );
    case QType.mcEnKo:
      return Question(
        id: id,
        cardId: card.id,
        type: type,
        instruction: _instructions[type]!,
        prompt: card.en,
        promptIsKorean: false,
        rom: card.rom,
        en: card.en,
        note: card.note,
        options: _buildOptions(card, pool, 'ko', rnd),
      );
    case QType.mcRom:
      return Question(
        id: id,
        cardId: card.id,
        type: type,
        instruction: _instructions[type]!,
        prompt: card.ko,
        promptIsKorean: true,
        rom: card.rom,
        en: card.en,
        note: card.note,
        options: _buildOptions(card, pool, 'rom', rnd),
      );
    case QType.typeRom:
      return Question(
        id: id,
        cardId: card.id,
        type: type,
        instruction: _instructions[type]!,
        prompt: card.ko,
        promptIsKorean: true,
        rom: card.rom,
        en: card.en,
        note: card.note,
      );
    case QType.listen:
      return Question(
        id: id,
        cardId: card.id,
        type: type,
        instruction: _instructions[type]!,
        prompt: '',
        promptIsKorean: false,
        rom: card.rom,
        en: card.en,
        note: card.note,
        reveal: card.ko,
        options: _buildOptions(card, pool, 'en', rnd),
      );
    default:
      return Question(
        id: id,
        cardId: card.id,
        type: QType.mcKoEn,
        instruction: _instructions[QType.mcKoEn]!,
        prompt: card.ko,
        promptIsKorean: true,
        rom: card.rom,
        en: card.en,
        note: card.note,
        options: _buildOptions(card, pool, 'en', rnd),
      );
  }
}

Session buildSession(Lesson lesson, {int attempt = 1}) {
  final rnd = Random(_hash('${lesson.id}:$attempt'));
  final pool = siblingCards(lesson.id);
  final matchRounds = <Question>[];
  final questions = <Question>[];

  if (lesson.mode == LessonMode.match) {
    for (var i = 0; i < lesson.cards.length; i += 6) {
      final group = lesson.cards.sublist(
          i, i + 6 > lesson.cards.length ? lesson.cards.length : i + 6);
      if (group.length < 3) continue;
      matchRounds.add(Question(
        id: 'm${i ~/ 6}',
        cardId: group.first.id,
        type: QType.match,
        instruction: _instructions[QType.match]!,
        prompt: '',
        promptIsKorean: false,
        rom: group.map((c) => c.rom).join(' · '),
        en: group.map((c) => c.en).join(' · '),
        pairs: _shuffle(group, rnd).map((c) => MatchPair(c.ko, c.en)).toList(),
      ));
    }
  }

  final n = lesson.cards.length;
  final count = lesson.mode == LessonMode.test
      ? min(14, max(8, n))
      : min(10, max(6, n));
  final ordered = _shuffle(lesson.cards, rnd);
  for (var i = 0; i < count; i++) {
    final card = ordered[i % ordered.length];
    questions.add(_make(card, pool, _typeFor(card, lesson.mode, rnd), rnd, i));
  }

  return Session(lesson.id, attempt, matchRounds, questions);
}
