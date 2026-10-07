import 'package:flutter/material.dart';

/// Extra semantic colours that Material's ColorScheme does not carry.
class HQColors extends ThemeExtension<HQColors> {
  final Color good;
  final Color goodSoft;
  final Color bad;
  final Color badSoft;
  final Color warn;
  final Color warnSoft;
  final Color surface2;
  final Color line;
  final Color muted;
  final Color brandSoft;
  final Color brandFg;

  const HQColors({
    required this.good,
    required this.goodSoft,
    required this.bad,
    required this.badSoft,
    required this.warn,
    required this.warnSoft,
    required this.surface2,
    required this.line,
    required this.muted,
    required this.brandSoft,
    required this.brandFg,
  });

  static const light = HQColors(
    good: Color(0xFF16A34A),
    goodSoft: Color(0xFFDCFCE7),
    bad: Color(0xFFDC2626),
    badSoft: Color(0xFFFEE2E2),
    warn: Color(0xFFD97706),
    warnSoft: Color(0xFFFEF3C7),
    surface2: Color(0xFFF1F3FA),
    line: Color(0xFFE3E7F1),
    muted: Color(0xFF64748B),
    brandSoft: Color(0xFFEDE9FE),
    brandFg: Color(0xFF4C1D95),
  );

  static const dark = HQColors(
    good: Color(0xFF4ADE80),
    goodSoft: Color(0xFF10311F),
    bad: Color(0xFFF87171),
    badSoft: Color(0xFF3A1519),
    warn: Color(0xFFFBBF24),
    warnSoft: Color(0xFF3A2A08),
    surface2: Color(0xFF16223A),
    line: Color(0xFF22304D),
    muted: Color(0xFF94A3C0),
    brandSoft: Color(0xFF2A2150),
    brandFg: Color(0xFFDDD6FE),
  );

  @override
  HQColors copyWith({Color? good}) => this;

  @override
  HQColors lerp(ThemeExtension<HQColors>? other, double t) {
    if (other is! HQColors) return this;
    return HQColors(
      good: Color.lerp(good, other.good, t)!,
      goodSoft: Color.lerp(goodSoft, other.goodSoft, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      badSoft: Color.lerp(badSoft, other.badSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandFg: Color.lerp(brandFg, other.brandFg, t)!,
    );
  }
}

extension HQTheme on BuildContext {
  HQColors get hq => Theme.of(this).extension<HQColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
}

const Color brand = Color(0xFF7C3AED);
const Color brandDark = Color(0xFFA78BFA);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: brightness,
  ).copyWith(
    primary: dark ? brandDark : brand,
    surface: dark ? const Color(0xFF101A2E) : Colors.white,
    onSurface: dark ? const Color(0xFFE9EEFB) : const Color(0xFF0F172A),
  );
  final bg = dark ? const Color(0xFF070B16) : const Color(0xFFF4F6FB);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    extensions: [dark ? HQColors.dark : HQColors.light],
    fontFamilyFallback: const ['Apple SD Gothic Neo', 'Noto Sans KR', 'Malgun Gothic'],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: (dark ? brandDark : brand).withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF16223A) : const Color(0xFFF1F3FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
