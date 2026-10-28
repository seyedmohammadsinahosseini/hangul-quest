import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = AppScope.of(context).profile.displayName;
    if (_name.text.isEmpty) _name.text = current;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    final ach = state.achievements;
    final joined = DateTime.tryParse(p.createdAt) ?? DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: context.cs.primary, borderRadius: BorderRadius.circular(18)),
                    child: Text(p.displayName.isEmpty ? '한' : p.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('Learning since ${_month(joined.month)} ${joined.year}', style: TextStyle(fontSize: 12, color: context.hq.muted)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: [
                          Pill('${p.xpEarned} XP earned', icon: Icons.bolt_rounded, tone: PillTone.brand),
                          Pill('${p.streak}d', icon: Icons.local_fire_department_rounded, tone: PillTone.warn),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              StatGrid([
                StatTile('Accuracy', '${p.accuracy}%'),
                StatTile('XP balance', '${p.xpBalance}'),
                StatTile('Correct answers', '${p.correctAnswers}'),
                StatTile('Hints used', '${p.hintsUsed}'),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Today · ${p.xpToday}/${p.dailyGoal} XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.hq.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Longest streak ${p.longestStreak}d',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.hq.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Bar(value: p.xpToday / p.dailyGoal * 100, color: context.hq.good),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SectionTitle('Achievements', sub: '${ach.where((a) => a.earned).length} of ${ach.length} unlocked', icon: Icons.emoji_events_rounded),
        for (final a in ach)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.all(12),
              borderColor: a.earned ? context.hq.good.withValues(alpha: 0.4) : null,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: a.earned ? context.hq.goodSoft : context.hq.surface2, borderRadius: BorderRadius.circular(14)),
                    child: Text(a.icon, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        Text(a.desc, style: TextStyle(fontSize: 11, color: context.hq.muted)),
                        const SizedBox(height: 4),
                        Bar(value: a.progress / a.target * 100, height: 5, color: a.earned ? context.hq.good : context.cs.primary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${a.progress}/${a.target}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: context.hq.muted)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        const SectionTitle('Settings', sub: 'Theme, goal and data'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label('Display name'),
              Row(
                children: [
                  Expanded(child: TextField(controller: _name, maxLength: 24, decoration: const InputDecoration(counterText: ''))),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      await state.setDisplayName(_name.text);
                      setState(() => _saved = true);
                      Future.delayed(const Duration(milliseconds: 1400), () {
                        if (mounted) setState(() => _saved = false);
                      });
                    },
                    child: Text(_saved ? 'Saved' : 'Save'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Label('Theme'),
              Row(
                children: [
                  for (final t in ['light', 'dark']) ...[
                    Expanded(
                      child: _Choice(
                        selected: p.theme == t,
                        onTap: () => state.setTheme(t),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t == 'light' ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(t == 'light' ? 'Light' : 'Dark'),
                          ],
                        ),
                      ),
                    ),
                    if (t == 'light') const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _Label('Daily XP goal'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in [5, 10, 20, 30])
                    _Choice(selected: p.dailyGoal == g, onTap: () => state.setDailyGoal(g), child: Text('$g XP')),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: context.hq.line),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset all progress?'),
                        content: const Text('This deletes every lesson score, XP and review word.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: context.hq.bad),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Yes, reset'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await state.resetProgress();
                  },
                  child: const Text('Reset all progress'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _month(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: context.hq.muted)),
      );
}

class _Choice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _Choice({required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.hq.brandSoft : context.hq.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? context.cs.primary : context.hq.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DefaultTextStyle.merge(
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? context.hq.brandFg : context.hq.muted),
            child: IconTheme.merge(data: IconThemeData(color: selected ? context.hq.brandFg : context.hq.muted), child: child),
          ),
        ),
      ),
    );
  }
}
