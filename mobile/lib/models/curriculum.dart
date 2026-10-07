/// Core content models for Hangul Quest.
library;

class Example {
  final String ko;
  final String rom;
  final String en;
  const Example(this.ko, this.rom, this.en);
}

class KCard {
  final String id;
  final String ko;
  final String rom;
  final String en;
  final String? note;

  /// Jamo pieces, used by the Syllable Builder game.
  final List<String>? jamo;

  /// Ordered word chunks, used by the Sentence Builder game.
  final List<String>? parts;
  final Example? example;

  const KCard({
    required this.id,
    required this.ko,
    required this.rom,
    required this.en,
    this.note,
    this.jamo,
    this.parts,
    this.example,
  });
}

enum LessonMode { flashcards, quiz, builder, match, sentences, test }

class Lesson {
  final String id;
  final String title;
  final String goal;
  final String icon;
  final LessonMode mode;
  final int passScore;
  final List<KCard> cards;

  const Lesson({
    required this.id,
    required this.title,
    required this.goal,
    required this.icon,
    required this.mode,
    this.passScore = 70,
    required this.cards,
  });
}

class Unit {
  final String id;
  final String title;
  final String focus;
  final List<Lesson> lessons;
  const Unit({
    required this.id,
    required this.title,
    required this.focus,
    required this.lessons,
  });
}

enum PathStage { alphabet, vocabulary, grammar, conversation }

class UnlockRule {
  final String pathId;
  final int completedLessons;
  final int minAccuracy;
  final String label;
  const UnlockRule({
    required this.pathId,
    required this.completedLessons,
    required this.minAccuracy,
    required this.label,
  });
}

class LearningPath {
  final String id;
  final String title;
  final String tagline;
  final PathStage stage;
  final int color;
  final UnlockRule? unlock;
  final List<Unit> units;

  const LearningPath({
    required this.id,
    required this.title,
    required this.tagline,
    required this.stage,
    required this.color,
    this.unlock,
    required this.units,
  });

  List<Lesson> get lessons => units.expand((u) => u.lessons).toList();
}

enum HintTier { small, medium, large }

const Map<HintTier, int> hintCost = {
  HintTier.small: 6,
  HintTier.medium: 12,
  HintTier.large: 18,
};

const int xpPerCorrect = 1;
const int defaultPassScore = 70;

String stageLabel(PathStage s) {
  switch (s) {
    case PathStage.alphabet:
      return 'Stage 1 · Alphabet';
    case PathStage.vocabulary:
      return 'Stage 2 · Words';
    case PathStage.grammar:
      return 'Stage 3 · Grammar';
    case PathStage.conversation:
      return 'Stage 4 · Sentences';
  }
}

String modeLabel(LessonMode m) {
  switch (m) {
    case LessonMode.flashcards:
      return 'Learn';
    case LessonMode.quiz:
      return 'Quiz';
    case LessonMode.builder:
    case LessonMode.match:
      return 'Game';
    case LessonMode.sentences:
      return 'Build';
    case LessonMode.test:
      return 'Test';
  }
}

String modeHelp(LessonMode m) {
  switch (m) {
    case LessonMode.flashcards:
      return 'Learn the cards, then answer a mixed quiz.';
    case LessonMode.quiz:
      return 'Mixed multiple choice, listening and typing.';
    case LessonMode.builder:
      return 'Assemble jamo into real syllable blocks.';
    case LessonMode.match:
      return 'Match Korean with English as fast as you can.';
    case LessonMode.sentences:
      return 'Build whole Korean sentences chunk by chunk.';
    case LessonMode.test:
      return 'No warm-up. A blind mixed test.';
  }
}
