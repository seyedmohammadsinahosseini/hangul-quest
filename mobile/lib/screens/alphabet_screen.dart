import 'package:flutter/material.dart';

import '../data/curriculum_data.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  String? _active;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Hangul chart', sub: 'Tap any letter to hear it.', icon: Icons.grid_view_rounded,
                  trailing: Tts.available ? const Pill('audio ready', tone: PillTone.good) : const Pill('no Korean voice', tone: PillTone.warn)),
              Text(
                'Korean is written in blocks: a consonant and a vowel always sit together, and a final consonant can be added underneath. Every block you will ever read is built from these 40 letters.',
                style: TextStyle(fontSize: 12, height: 1.5, color: context.hq.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final g in hangulTable) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(g.group.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: context.hq.muted)),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              for (final item in g.items)
                _LetterTile(
                  item: item,
                  active: _active == item,
                  onTap: () {
                    setState(() => _active = item);
                    Tts.speak(item.split(' ').first);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Panel(
          child: Column(
            children: [
              const Text('How a block is assembled', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final piece in ['ㅎ', '+', 'ㅏ', '+', 'ㄴ', '=', '한'])
                    Container(
                      width: piece == '+' || piece == '=' ? 22 : 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: piece == '한' ? context.cs.primary : (piece == '+' || piece == '=' ? Colors.transparent : context.hq.surface2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(piece,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: piece == '한' ? Colors.white : (piece == '+' || piece == '=' ? context.hq.muted : null))),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text('한 = ㅎ + ㅏ + ㄴ → “han”. The final consonant is called batchim.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.hq.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String item;
  final bool active;
  final VoidCallback onTap;
  const _LetterTile({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = item.split(' ');
    return Material(
      color: active ? context.hq.brandSoft : context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? context.cs.primary : context.hq.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(parts[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 2),
            Text(parts.length > 1 ? parts[1] : '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.hq.muted)),
            Icon(Icons.volume_up_rounded, size: 12, color: active ? context.cs.primary : context.hq.muted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
