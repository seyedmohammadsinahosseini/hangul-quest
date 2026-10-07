import 'package:flutter/material.dart';

import '../data/curriculum_data.dart';
import '../main.dart';
import '../models/curriculum.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'lesson_screen.dart';
import 'path_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    final paths = state.pathProgress;
    final done = state.completedCount;
    final total = allLessons.length;
    final nextId = state.nextLessonId;
    final next = nextId == null ? null : getLesson(nextId);
    final nextPath = nextId == null ? null : getPath(lessonPathId[nextId] ?? '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ------- journey hero -------
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Ring(
                      value: state.overallPercent.toDouble(),
                      size: 84,
                      stroke: 9,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${state.overallPercent}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                          Text('DONE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: context.hq.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR JOURNEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: context.hq.muted)),
                          Text('$done / $total lessons', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          Text('${total - done} lesson${total - done == 1 ? '' : 's'} left on the roadmap', style: TextStyle(fontSize: 12, color: context.hq.muted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Pill('${p.xpBalance} XP', icon: Icons.bolt_rounded, tone: PillTone.brand),
                              Pill('${p.streak} day streak', icon: Icons.local_fire_department_rounded, tone: PillTone.warn),
                              Pill('${p.accuracy}% accuracy', icon: Icons.track_changes_rounded, tone: p.accuracy >= 70 ? PillTone.good : PillTone.neutral),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.hq.surface2.withValues(alpha: 0.6),
                  border: Border(top: BorderSide(color: context.hq.line)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily goal · ${p.xpToday}/${p.dailyGoal} XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.hq.muted)),
                        Text(
                          p.goalDone ? 'Goal reached' : '${(p.dailyGoal - p.xpToday).clamp(0, 999)} to go',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.goalDone ? context.hq.good : context.hq.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Bar(value: p.xpToday / p.dailyGoal * 100, color: context.hq.good),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------- continue -------
        if (next != null)
          Panel(
            borderColor: context.cs.primary.withValues(alpha: 0.45),
            onTap: () => openLesson(context, next.id),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: context.cs.primary, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextPath == null ? 'CONTINUE' : stageLabel(nextPath.stage).toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: context.cs.primary),
                      ),
                      Text(next.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(next.goal, style: TextStyle(fontSize: 12, color: context.hq.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Pill('Start', tone: PillTone.brand),
              ],
            ),
          )
        else
          const EmptyState(
            emoji: '🏁',
            title: 'Roadmap complete',
            body: 'You finished every lesson. Replay any lesson for a higher score or clear your Review Deck.',
          ),
        const SizedBox(height: 16),

        // ------- hint economy -------
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Hint economy', sub: 'Hints are expensive on purpose.', icon: Icons.auto_awesome_rounded, trailing: Pill('${p.hintsUsed} used', tone: PillTone.brand)),
              Row(
                children: [
                  _HintTile(cost: hintCost[HintTier.small]!, label: '50 / 50', desc: 'Removes one wrong option', afford: p.xpBalance >= hintCost[HintTier.small]!),
                  const SizedBox(width: 8),
                  _HintTile(cost: hintCost[HintTier.medium]!, label: 'Coach', desc: 'Shows romanization', afford: p.xpBalance >= hintCost[HintTier.medium]!),
                  const SizedBox(width: 8),
                  _HintTile(cost: hintCost[HintTier.large]!, label: 'Reveal', desc: 'Shows the answer', afford: p.xpBalance >= hintCost[HintTier.large]!),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '1 correct answer = $xpPerCorrect XP, so 6 correct answers buy one small hint. A hinted question never pays XP — think first, spend later.',
                style: TextStyle(fontSize: 11, height: 1.5, color: context.hq.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------- onboarding -------
        if (done == 0) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('How this course works', sub: 'Never studied Korean? Perfect.'),
                _Step(1, 'Learn the letters first', 'Hangul is 40 letters that stack into blocks. You can learn to read in a few sessions — no romanization crutch needed after this stage.'),
                _Step(2, 'Collect essential words', 'Greetings, food, places, numbers, verbs. Every word is drilled with short quizzes, matching games and listening rounds.'),
                _Step(3, 'Unlock grammar at 70%', 'Score 70% or better to pass a lesson. Finish 4 word lessons with 70%+ accuracy and the Grammar Engine opens — while new words keep coming.'),
                _Step(4, 'Speak full sentences', 'Build real sentences chunk by chunk: introductions, ordering food, asking for directions.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ------- roadmap -------
        const SectionTitle('Learning roadmap', sub: 'Alphabet → words → grammar → sentences', icon: Icons.map_rounded),
        for (final pp in paths) ...[
          _PathCard(pp),
          const SizedBox(height: 12),
        ],

        // ------- achievements -------
        const SizedBox(height: 4),
        SectionTitle('Achievements', sub: '${state.achievements.where((a) => a.earned).length} / ${state.achievements.length} earned', icon: Icons.emoji_events_rounded),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.9,
          children: [
            for (final a in state.achievements.take(4))
              Panel(
                padding: const EdgeInsets.all(10),
                borderColor: a.earned ? context.hq.good.withValues(alpha: 0.4) : null,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: a.earned ? context.hq.goodSoft : context.hq.surface2, borderRadius: BorderRadius.circular(10)),
                      child: Icon(a.earned ? Icons.check_rounded : Icons.lock_outline_rounded, size: 16, color: a.earned ? context.hq.good : context.hq.muted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(a.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${a.progress}/${a.target}', style: TextStyle(fontSize: 11, color: context.hq.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

void openLesson(BuildContext context, String lessonId) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lessonId: lessonId)));
}

class _HintTile extends StatelessWidget {
  final int cost;
  final String label;
  final String desc;
  final bool afford;
  const _HintTile({required this.cost, required this.label, required this.desc, required this.afford});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: afford ? context.hq.brandSoft.withValues(alpha: 0.5) : context.hq.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: afford ? context.cs.primary.withValues(alpha: 0.4) : context.hq.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bolt_rounded, size: 12, color: afford ? context.cs.primary : context.hq.muted),
              Text('$cost XP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            Text(desc, style: TextStyle(fontSize: 10, height: 1.3, color: context.hq.muted)),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String title;
  final String desc;
  const _Step(this.n, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.hq.brandSoft, borderRadius: BorderRadius.circular(10)),
            child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.hq.brandFg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                Text(desc, style: TextStyle(fontSize: 12, height: 1.5, color: context.hq.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final PathProgress pp;
  const _PathCard(this.pp);

  @override
  Widget build(BuildContext context) {
    final color = Color(pp.path.color);
    final nextTitle = pp.firstAvailableLessonId == null ? null : getLesson(pp.firstAvailableLessonId!)?.title;
    return Panel(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PathScreen(pathId: pp.path.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(stageLabel(pp.path.stage).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: context.hq.muted)),
                    ]),
                    const SizedBox(height: 2),
                    Text(pp.path.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(pp.path.tagline, style: TextStyle(fontSize: 12, color: context.hq.muted)),
                  ],
                ),
              ),
              if (pp.locked)
                const Pill('Locked', icon: Icons.lock_rounded, tone: PillTone.warn)
              else if (pp.percent == 100)
                const Pill('Done', icon: Icons.check_rounded, tone: PillTone.good)
              else
                Pill('${pp.percent}%', tone: PillTone.brand),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pp.completedLessons}/${pp.totalLessons} lessons · ${pp.remaining} remaining', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.hq.muted)),
              Text(pp.accuracy > 0 ? '${pp.accuracy}% accuracy' : 'not started', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.hq.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Bar(value: pp.percent.toDouble(), color: color, height: 9),
          const SizedBox(height: 12),
          if (pp.locked)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.hq.warnSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.hq.warn.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UNLOCK CONDITION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: context.hq.warn)),
                  const SizedBox(height: 2),
                  Text(pp.unlockLabel ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('Progress: ${pp.unlockDone % 1 == 0 ? pp.unlockDone.toInt() : pp.unlockDone.toStringAsFixed(1)}/${pp.unlockNeed} · needs ≥70% accuracy in that stage',
                      style: TextStyle(fontSize: 11, color: context.hq.muted)),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    nextTitle != null ? 'Next: $nextTitle' : 'Path complete — replay for a better score',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nextTitle != null ? context.hq.muted : context.hq.good),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Pill('Open map', tone: PillTone.neutral),
              ],
            ),
        ],
      ),
    );
  }
}
