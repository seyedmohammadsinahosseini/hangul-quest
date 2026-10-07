/// Single source of truth for the learner. Persists to SharedPreferences.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/curriculum_data.dart';
import '../models/curriculum.dart';

const _storageKey = 'hq_state_v1';

// ---------------------------------------------------------------------------
// Persisted records
// ---------------------------------------------------------------------------

class Profile {
  String displayName;
  String theme; // light | dark
  int dailyGoal;
  int xpEarned;
  int xpSpent;
  int hintsUsed;
  int correctAnswers;
  int wrongAnswers;
  int xpToday;
  int streak;
  int longestStreak;
  String? lastActiveDate;
  String createdAt;

  Profile({
    this.displayName = 'Learner',
    this.theme = 'light',
    this.dailyGoal = 10,
    this.xpEarned = 0,
    this.xpSpent = 0,
    this.hintsUsed = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.xpToday = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  int get xpBalance => xpEarned > xpSpent ? xpEarned - xpSpent : 0;
  int get accuracy {
    final total = correctAnswers + wrongAnswers;
    return total == 0 ? 0 : (correctAnswers / total * 100).round();
  }

  bool get goalDone => xpToday >= dailyGoal;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'theme': theme,
        'dailyGoal': dailyGoal,
        'xpEarned': xpEarned,
        'xpSpent': xpSpent,
        'hintsUsed': hintsUsed,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'xpToday': xpToday,
        'streak': streak,
        'longestStreak': longestStreak,
        'lastActiveDate': lastActiveDate,
        'createdAt': createdAt,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        displayName: j['displayName'] as String? ?? 'Learner',
        theme: j['theme'] as String? ?? 'light',
        dailyGoal: j['dailyGoal'] as int? ?? 10,
        xpEarned: j['xpEarned'] as int? ?? 0,
        xpSpent: j['xpSpent'] as int? ?? 0,
        hintsUsed: j['hintsUsed'] as int? ?? 0,
        correctAnswers: j['correctAnswers'] as int? ?? 0,
        wrongAnswers: j['wrongAnswers'] as int? ?? 0,
        xpToday: j['xpToday'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        longestStreak: j['longestStreak'] as int? ?? 0,
        lastActiveDate: j['lastActiveDate'] as String?,
        createdAt: j['createdAt'] as String?,
      );
}

class LessonProgress {
  final String lessonId;
  final String pathId;
  String status; // unlocked | completed
  int bestScore;
  int attempts;
  int correct;
  int total;
  int xpEarned;

  LessonProgress({
    required this.lessonId,
    required this.pathId,
    this.status = 'unlocked',
    this.bestScore = 0,
    this.attempts = 0,
    this.correct = 0,
    this.total = 0,
    this.xpEarned = 0,
  });

  bool get completed => status == 'completed';

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'pathId': pathId,
        'status': status,
        'bestScore': bestScore,
        'attempts': attempts,
        'correct': correct,
        'total': total,
        'xpEarned': xpEarned,
      };

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: j['lessonId'] as String,
        pathId: j['pathId'] as String,
        status: j['status'] as String? ?? 'unlocked',
        bestScore: j['bestScore'] as int? ?? 0,
        attempts: j['attempts'] as int? ?? 0,
        correct: j['correct'] as int? ?? 0,
        total: j['total'] as int? ?? 0,
        xpEarned: j['xpEarned'] as int? ?? 0,
      );
}

class Mistake {
  final String cardId;
  String lessonId;
  int wrongCount;
  int rightSince;
  bool mastered;

  Mistake({
    required this.cardId,
    required this.lessonId,
    this.wrongCount = 1,
    this.rightSince = 0,
    this.mastered = false,
  });

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'lessonId': lessonId,
        'wrongCount': wrongCount,
        'rightSince': rightSince,
        'mastered': mastered,
      };

  factory Mistake.fromJson(Map<String, dynamic> j) => Mistake(
        cardId: j['cardId'] as String,
        lessonId: j['lessonId'] as String? ?? '',
        wrongCount: j['wrongCount'] as int? ?? 1,
        rightSince: j['rightSince'] as int? ?? 0,
        mastered: j['mastered'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// Derived views
// ---------------------------------------------------------------------------

enum LessonStatus { locked, available, completed }

class LessonState {
  final String id;
  final String pathId;
  final LessonStatus status;
  final int bestScore;
  final int attempts;
  const LessonState(this.id, this.pathId, this.status, this.bestScore, this.attempts);
}

class PathProgress {
  final LearningPath path;
  final bool locked;
  final String? unlockLabel;
  final double unlockDone;
  final int unlockNeed;
  final int completedLessons;
  final int totalLessons;
  final int percent;
  final int accuracy;
  final String? firstAvailableLessonId;

  const PathProgress({
    required this.path,
    required this.locked,
    required this.unlockLabel,
    required this.unlockDone,
    required this.unlockNeed,
    required this.completedLessons,
    required this.totalLessons,
    required this.percent,
    required this.accuracy,
    required this.firstAvailableLessonId,
  });

  int get remaining => totalLessons - completedLessons;
}

class Achievement {
  final String id;
  final String title;
  final String desc;
  final String icon;
  final int progress;
  final int target;
  const Achievement(this.id, this.title, this.desc, this.icon, this.progress, this.target);
  bool get earned => progress >= target;
}

class ReviewCard {
  final KCard card;
  final int wrongCount;
  const ReviewCard(this.card, this.wrongCount);
}

class AnswerEntry {
  final String cardId;
  final bool correct;
  final HintTier? hint;
  const AnswerEntry(this.cardId, this.correct, this.hint);
}

class LessonResult {
  final int score;
  final bool passed;
  final int correct;
  final int total;
  final int xpGained;
  const LessonResult(this.score, this.passed, this.correct, this.total, this.xpGained);
}

// ---------------------------------------------------------------------------
// AppState
// ---------------------------------------------------------------------------

class AppState extends ChangeNotifier {
  Profile profile = Profile();
  final Map<String, LessonProgress> progress = {};
  final Map<String, Mistake> mistakes = {};
  bool ready = false;

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);
  static String _yesterday() =>
      DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

  // -------- persistence --------

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        profile = Profile.fromJson(data['profile'] as Map<String, dynamic>? ?? {});
        progress.clear();
        for (final e in (data['progress'] as List? ?? const [])) {
          final p = LessonProgress.fromJson(e as Map<String, dynamic>);
          progress[p.lessonId] = p;
        }
        mistakes.clear();
        for (final e in (data['mistakes'] as List? ?? const [])) {
          final m = Mistake.fromJson(e as Map<String, dynamic>);
          mistakes[m.cardId] = m;
        }
      }
    } catch (_) {
      // corrupted storage -> start fresh
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'profile': profile.toJson(),
          'progress': progress.values.map((p) => p.toJson()).toList(),
          'mistakes': mistakes.values.map((m) => m.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  // -------- derived: paths --------

  List<LessonProgress> _rowsIn(String pathId) =>
      progress.values.where((r) => r.pathId == pathId).toList();

  int _completedIn(String pathId) => _rowsIn(pathId).where((r) => r.completed).length;

  int _accuracyIn(String pathId) {
    final rows = _rowsIn(pathId);
    final total = rows.fold<int>(0, (s, r) => s + r.total);
    final correct = rows.fold<int>(0, (s, r) => s + r.correct);
    return total == 0 ? 0 : (correct / total * 100).round();
  }

  int _percentIn(String pathId) {
    final total = getPath(pathId)?.lessons.length ?? 0;
    return total == 0 ? 0 : (_completedIn(pathId) / total * 100).round();
  }

  ({bool locked, String? label, double done, int need}) _unlock(LearningPath path, int index) {
    if (index == 0) return (locked: false, label: null, done: 1.0, need: 1);

    if (path.id == 'p-words') {
      final testDone = progress['h-test']?.completed ?? false;
      final pct = _percentIn('p-hangul');
      final ok = testDone || pct >= 70;
      return (
        locked: !ok,
        label: 'Pass the Hangul Mastery Test (or finish 70% of Hangul Foundations)',
        done: ok ? 1.0 : (pct / 70).clamp(0, 1).toDouble(),
        need: 1,
      );
    }

    final rule = path.unlock;
    if (rule == null) {
      final prev = paths[index - 1];
      final ok = _completedIn(prev.id) > 0;
      return (
        locked: !ok,
        label: 'Start by completing a lesson in ${prev.title}',
        done: ok ? 1.0 : 0.0,
        need: 1,
      );
    }
    final completed = _completedIn(rule.pathId);
    final acc = _accuracyIn(rule.pathId);
    final ok = completed >= rule.completedLessons && acc >= rule.minAccuracy;
    return (
      locked: !ok,
      label: rule.label,
      done: completed.toDouble(),
      need: rule.completedLessons,
    );
  }

  List<PathProgress> get pathProgress {
    final out = <PathProgress>[];
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final order = path.lessons.map((l) => l.id).toList();
      final completed = _completedIn(path.id);
      final unlock = _unlock(path, i);
      String? firstAvailable;
      for (var k = 0; k < order.length; k++) {
        final prevDone = k == 0 ? true : (progress[order[k - 1]]?.completed ?? false);
        final done = progress[order[k]]?.completed ?? false;
        if (prevDone && !done) {
          firstAvailable = order[k];
          break;
        }
      }
      out.add(PathProgress(
        path: path,
        locked: unlock.locked,
        unlockLabel: unlock.label,
        unlockDone: unlock.done,
        unlockNeed: unlock.need,
        completedLessons: completed,
        totalLessons: order.length,
        percent: order.isEmpty ? 0 : (completed / order.length * 100).round(),
        accuracy: _accuracyIn(path.id),
        firstAvailableLessonId: unlock.locked ? null : firstAvailable,
      ));
    }
    return out;
  }

  Map<String, LessonState> get lessonStates {
    final map = <String, LessonState>{};
    final pp = pathProgress;
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final order = path.lessons.map((l) => l.id).toList();
      final pathLocked = pp[i].locked;
      for (var k = 0; k < order.length; k++) {
        final id = order[k];
        final row = progress[id];
        final prevDone = k == 0 ? !pathLocked : (progress[order[k - 1]]?.completed ?? false);
        final status = (row?.completed ?? false)
            ? LessonStatus.completed
            : (prevDone && !pathLocked)
                ? LessonStatus.available
                : LessonStatus.locked;
        map[id] = LessonState(id, path.id, status, row?.bestScore ?? 0, row?.attempts ?? 0);
      }
    }
    return map;
  }

  LessonStatus statusOf(String lessonId) =>
      lessonStates[lessonId]?.status ?? LessonStatus.locked;

  int get overallPercent {
    final total = allLessons.length;
    final done = progress.values.where((r) => r.completed).length;
    return total == 0 ? 0 : (done / total * 100).round();
  }

  int get completedCount => progress.values.where((r) => r.completed).length;

  String? get nextLessonId {
    for (final p in pathProgress) {
      if (!p.locked && p.firstAvailableLessonId != null) return p.firstAvailableLessonId;
    }
    return null;
  }

  /// Next lesson after [currentId] that is not locked (used on results screen).
  String? nextAfter(String currentId) {
    final states = lessonStates;
    final order = allLessons.map((l) => l.id).toList();
    final start = order.indexOf(currentId);
    for (var i = start + 1; i < order.length; i++) {
      if (states[order[i]]?.status != LessonStatus.locked) return order[i];
    }
    return null;
  }

  List<ReviewCard> get review {
    final list = mistakes.values
        .where((m) => !m.mastered && cardById.containsKey(m.cardId))
        .toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return list.take(40).map((m) => ReviewCard(cardById[m.cardId]!, m.wrongCount)).toList();
  }

  List<Achievement> get achievements {
    final completed = progress.values.where((r) => r.completed).toList();
    final hangulTest = progress['h-test'];
    final vocab = completed.where((r) => r.pathId == 'p-words').length;
    final grammar = completed.where((r) => r.pathId == 'p-grammar').length;
    final perfect = completed.where((r) => r.bestScore == 100).length;
    final mastered = mistakes.values.where((m) => m.mastered).length;
    return [
      Achievement('first-steps', 'First Steps', 'Complete your first lesson', '🌱', completed.length, 1),
      Achievement('hangul-reader', 'Hangul Reader', 'Score 70+ on the Hangul Mastery Test', '🔤', hangulTest?.bestScore ?? 0, 70),
      Achievement('word-collector', 'Word Collector', 'Complete 6 Essential Word lessons', '📚', vocab, 6),
      Achievement('grammar-engine', 'Grammar Engine', 'Complete 3 grammar lessons', '⚙️', grammar, 3),
      Achievement('xp-100', 'Century', 'Earn 100 XP in total', '💯', profile.xpEarned, 100),
      Achievement('streak-7', 'On Fire', 'Keep a 7-day streak', '🔥', profile.longestStreak, 7),
      Achievement('flawless', 'Flawless', 'Finish a lesson with 100%', '✨', perfect, 1),
      Achievement('comeback', 'Comeback Kid', 'Master 10 words in the Review Deck', '🩹', mastered, 10),
    ];
  }

  // -------- actions --------

  void _touchActivity(int xpGained) {
    final today = _today();
    if (profile.lastActiveDate == today) {
      profile.xpToday += xpGained;
    } else if (profile.lastActiveDate == _yesterday()) {
      profile.streak += 1;
      profile.xpToday = xpGained;
    } else {
      profile.streak = 1;
      profile.xpToday = xpGained;
    }
    if (profile.streak > profile.longestStreak) profile.longestStreak = profile.streak;
    profile.lastActiveDate = today;
    profile.xpEarned += xpGained;
  }

  void _markWrong(String cardId, String lessonId) {
    final m = mistakes[cardId];
    if (m == null) {
      mistakes[cardId] = Mistake(cardId: cardId, lessonId: lessonId);
    } else {
      m.wrongCount += 1;
      m.rightSince = 0;
      m.mastered = false;
    }
  }

  void _markRight(String cardId) {
    final m = mistakes[cardId];
    if (m == null) return;
    m.rightSince += 1;
    if (m.rightSince >= 3) m.mastered = true;
  }

  /// Persist one finished lesson run. 1 XP per un-hinted correct answer.
  Future<LessonResult> recordLesson(String lessonId, List<AnswerEntry> answers) async {
    final lesson = getLesson(lessonId);
    if (lesson == null) throw StateError('unknown lesson');
    final total = answers.length;
    final correct = answers.where((a) => a.correct).length;
    final xpGained = answers.where((a) => a.correct && a.hint == null).length * xpPerCorrect;
    final score = total == 0 ? 0 : (correct / total * 100).round();
    final passed = score >= lesson.passScore;
    final pathId = lessonPathId[lessonId] ?? 'p-hangul';

    final row = progress.putIfAbsent(
      lessonId,
      () => LessonProgress(lessonId: lessonId, pathId: pathId),
    );
    row.attempts += 1;
    row.correct += correct;
    row.total += total;
    row.xpEarned += xpGained;
    if (score > row.bestScore) row.bestScore = score;
    if (passed) row.status = 'completed';

    for (final a in answers) {
      if (a.correct) {
        _markRight(a.cardId);
      } else {
        _markWrong(a.cardId, lessonId);
      }
    }

    profile.correctAnswers += correct;
    profile.wrongAnswers += total - correct;
    _touchActivity(xpGained);

    await _save();
    notifyListeners();
    return LessonResult(score, passed, correct, total, xpGained);
  }

  /// Returns null on success, or an error message.
  Future<String?> buyHint(HintTier tier) async {
    final cost = hintCost[tier]!;
    if (profile.xpBalance < cost) {
      return 'You need $cost XP for this hint (balance ${profile.xpBalance}).';
    }
    profile.xpSpent += cost;
    profile.hintsUsed += 1;
    await _save();
    notifyListeners();
    return null;
  }

  Future<void> recordReview(List<AnswerEntry> entries) async {
    if (entries.isEmpty) return;
    final correct = entries.where((e) => e.correct).length;
    for (final e in entries) {
      if (e.correct) {
        if (!mistakes.containsKey(e.cardId)) {
          mistakes[e.cardId] = Mistake(cardId: e.cardId, lessonId: '', wrongCount: 0);
        }
        _markRight(e.cardId);
      } else {
        _markWrong(e.cardId, '');
      }
    }
    profile.correctAnswers += correct;
    profile.wrongAnswers += entries.length - correct;
    _touchActivity(correct * xpPerCorrect);
    await _save();
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    profile.theme = theme == 'dark' ? 'dark' : 'light';
    await _save();
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    profile.displayName = clean.length > 24 ? clean.substring(0, 24) : clean;
    await _save();
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    profile.dailyGoal = goal.clamp(5, 50).toInt();
    await _save();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    final name = profile.displayName;
    final theme = profile.theme;
    final goal = profile.dailyGoal;
    profile = Profile(displayName: name, theme: theme, dailyGoal: goal);
    progress.clear();
    mistakes.clear();
    await _save();
    notifyListeners();
  }
}
