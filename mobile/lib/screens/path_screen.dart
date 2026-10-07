import 'package:flutter/material.dart';

import '../data/curriculum_data.dart';
import '../main.dart';
import '../models/curriculum.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';

class PathScreen extends StatelessWidget {
  final String pathId;
  const PathScreen({super.key, required this.pathId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final path = getPath(pathId);
    if (path == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Unknown path')));
    }
    final index = paths.indexOf(path);
    final pp = state.pathProgress[index];
    final color = Color(path.color);
    final states = state.lessonStates;

    return Scaffold(
      appBar: AppBar(title: Text(path.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('STAGE ${index + 1} OF ${paths.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: context.hq.muted)),
                    const Spacer(),
                    if (pp.locked) const Pill('Locked', icon: Icons.lock_rounded, tone: PillTone.warn),
                  ],
                ),
                const SizedBox(height: 4),
                Text(path.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text(path.tagline, style: TextStyle(fontSize: 13, color: context.hq.muted)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${pp.percent}% complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                    Text(pp.remaining == 0 ? 'nothing left' : '${pp.remaining} lesson${pp.remaining == 1 ? '' : 's'} remaining',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.hq.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                Bar(value: pp.percent.toDouble(), color: color, height: 10),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_rounded, size: 12, color: context.hq.good),
                    const SizedBox(width: 4),
                    Text('${pp.completedLessons}/${pp.totalLessons} passed', style: TextStyle(fontSize: 11, color: context.hq.muted)),
                    const SizedBox(width: 12),
                    Icon(Icons.track_changes_rounded, size: 12, color: context.cs.primary),
                    const SizedBox(width: 4),
                    Text('${pp.accuracy}% accuracy', style: TextStyle(fontSize: 11, color: context.hq.muted)),
                  ],
                ),
                if (pp.locked) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.hq.warnSoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.hq.warn.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HOW TO UNLOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: context.hq.warn)),
                        const SizedBox(height: 4),
                        Text(pp.unlockLabel ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('pass score is always 70%', style: TextStyle(fontSize: 11, color: context.hq.muted)),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => PathScreen(pathId: paths[(index - 1).clamp(0, paths.length - 1)].id)),
                          ),
                          child: const Text('Go to the previous stage'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (var ui = 0; ui < path.units.length; ui++) ...[
            _UnitBlock(unit: path.units[ui], unitIndex: ui, color: color, states: states, pathLocked: pp.locked),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _UnitBlock extends StatelessWidget {
  final Unit unit;
  final int unitIndex;
  final Color color;
  final Map<String, LessonState> states;
  final bool pathLocked;
  const _UnitBlock({required this.unit, required this.unitIndex, required this.color, required this.states, required this.pathLocked});

  @override
  Widget build(BuildContext context) {
    final done = unit.lessons.where((l) => states[l.id]?.status == LessonStatus.completed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UNIT ${unitIndex + 1} · ${unit.title.toUpperCase()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: context.hq.muted)),
                    Text(unit.focus, style: TextStyle(fontSize: 12, color: context.hq.muted)),
                  ],
                ),
              ),
              Pill('$done/${unit.lessons.length}', tone: done == unit.lessons.length ? PillTone.good : PillTone.neutral),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var li = 0; li < unit.lessons.length; li++) ...[
          _LessonRow(lesson: unit.lessons[li], index: li, color: color, st: states[unit.lessons[li].id], pathLocked: pathLocked),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final int index;
  final Color color;
  final LessonState? st;
  final bool pathLocked;
  const _LessonRow({required this.lesson, required this.index, required this.color, required this.st, required this.pathLocked});

  @override
  Widget build(BuildContext context) {
    final status = st?.status ?? LessonStatus.locked;
    final locked = status == LessonStatus.locked || pathLocked;
    final done = status == LessonStatus.completed;

    final node = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? context.hq.good : (locked ? context.hq.surface2 : context.cs.surface),
        border: Border.all(color: done ? context.hq.good : (locked ? context.hq.line : context.cs.primary), width: 2),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : Text(locked ? '' : '${index + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.cs.primary)),
    );

    return Padding(
      padding: EdgeInsets.only(left: index.isEven ? 0 : 12),
      child: Row(
        children: [
          node,
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: locked ? 0.6 : 1,
              child: Panel(
                padding: const EdgeInsets.all(12),
                borderColor: done ? context.hq.good.withValues(alpha: 0.4) : (locked ? null : context.cs.primary.withValues(alpha: 0.3)),
                onTap: locked ? null : () => openLesson(context, lesson.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(modeLabel(lesson.mode).toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: color)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(lesson.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(lesson.goal, style: TextStyle(fontSize: 11, color: context.hq.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (done) Text('${st?.bestScore}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: context.hq.good)),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: locked ? context.hq.surface2 : (done ? context.hq.goodSoft : context.cs.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        locked ? Icons.lock_outline_rounded : (done ? Icons.check_rounded : Icons.play_arrow_rounded),
                        size: 18,
                        color: locked ? context.hq.muted : (done ? context.hq.good : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
