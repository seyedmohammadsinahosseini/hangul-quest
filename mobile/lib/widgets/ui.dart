import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/tts.dart';
import '../theme.dart';

/// Rounded surface card used across the app.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? context.hq.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class Bar extends StatelessWidget {
  final double value; // 0..100
  final Color? color;
  final double height;
  const Bar({super.key, required this.value, this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0, 100) / 100;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: height,
        color: context.hq.surface2,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          widthFactor: pct,
          child: Container(
            decoration: BoxDecoration(
              color: color ?? context.cs.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class Ring extends StatelessWidget {
  final double value; // 0..100
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;
  const Ring({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 7,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 100) / 100),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke, color ?? context.cs.primary, context.hq.surface2),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.value, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

enum PillTone { neutral, brand, good, bad, warn }

class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final PillTone tone;
  const Pill(this.text, {super.key, this.icon, this.tone = PillTone.neutral});

  @override
  Widget build(BuildContext context) {
    final hq = context.hq;
    late Color bg;
    late Color fg;
    switch (tone) {
      case PillTone.neutral:
        bg = hq.surface2;
        fg = hq.muted;
      case PillTone.brand:
        bg = hq.brandSoft;
        fg = hq.brandFg;
      case PillTone.good:
        bg = hq.goodSoft;
        fg = hq.good;
      case PillTone.bad:
        bg = hq.badSoft;
        fg = hq.bad;
      case PillTone.warn:
        bg = hq.warnSoft;
        fg = hq.warn;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class SpeakerButton extends StatelessWidget {
  final String text;
  final double size;
  const SpeakerButton(this.text, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.hq.surface2,
      shape: CircleBorder(side: BorderSide(color: context.hq.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Tts.speak(text),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.volume_up_rounded, size: size * 0.5, color: context.cs.onSurface),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  const StatTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.hq.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hq.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.hq.muted, letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? sub;
  final IconData? icon;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.sub, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: context.cs.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                if (sub != null)
                  Text(sub!, style: TextStyle(fontSize: 12, color: context.hq.muted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const EmptyState({super.key, required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.hq.line),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.hq.muted)),
        ],
      ),
    );
  }
}

/// Big Korean text with a comfortable fallback font stack.
class Hangul extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final TextAlign align;
  const Hangul(this.text, {super.key, this.size = 40, this.weight = FontWeight.w700, this.color, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(fontSize: size, fontWeight: weight, height: 1.15, color: color),
    );
  }
}

Color pathColor(int argb) => Color(argb);
