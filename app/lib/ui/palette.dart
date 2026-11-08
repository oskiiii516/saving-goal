import 'package:flutter/material.dart';

/// 调色板：作为 ThemeExtension 注入，深浅两套。
/// 取色统一走 `Palette.of(context)`，这样切主题时整棵树都会重建到新颜色。
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.card,
    required this.cardHi,
    required this.border,
    required this.green,
    required this.greenDeep,
    required this.text,
    required this.muted,
    required this.faint,
    required this.warn,
    required this.danger,
    required this.blue,
    required this.heroFrom,
    required this.heroTo,
    required this.shadow,
    required this.isDark,
  });

  final Color bg;
  final Color card;
  final Color cardHi;
  final Color border;
  final Color green;
  final Color greenDeep;
  final Color text;
  final Color muted;
  final Color faint;
  final Color warn;
  final Color danger;
  final Color blue;
  final Color heroFrom;
  final Color heroTo;
  final Color shadow;
  final bool isDark;

  static const dark = Palette(
    bg: Color(0xFF0B0E14),
    card: Color(0xFF141A23),
    cardHi: Color(0xFF1B2430),
    border: Color(0xFF263041),
    green: Color(0xFF3FB950),
    greenDeep: Color(0xFF2EA043),
    text: Color(0xFFE9EFF7),
    muted: Color(0xFF8B98A9),
    faint: Color(0xFF5E6B7D),
    warn: Color(0xFFE3B341),
    danger: Color(0xFFF85149),
    blue: Color(0xFF58A6FF),
    heroFrom: Color(0xFF13251A),
    heroTo: Color(0xFF101720),
    shadow: Color(0x66000000),
    isDark: true,
  );

  static const light = Palette(
    bg: Color(0xFFF4F6F9),
    card: Color(0xFFFFFFFF),
    cardHi: Color(0xFFEEF2F7),
    border: Color(0xFFDFE5EE),
    green: Color(0xFF1F883D),
    greenDeep: Color(0xFF196C31),
    text: Color(0xFF1A2028),
    muted: Color(0xFF5C6B7F),
    faint: Color(0xFF93A0B1),
    warn: Color(0xFF9A6700),
    danger: Color(0xFFCF222E),
    blue: Color(0xFF0A66C2),
    heroFrom: Color(0xFFE6F5EA),
    heroTo: Color(0xFFF8FAFC),
    shadow: Color(0x14000000),
    isDark: false,
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).extension<Palette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// 状态色：按目标状态取，深浅主题自动适配
  Color forStatus(String status) => switch (status) {
        'done' => green,
        'overdue' => danger,
        'behind' => warn,
        'onTrack' => green,
        _ => muted,
      };

  @override
  Palette copyWith({
    Color? bg,
    Color? card,
    Color? cardHi,
    Color? border,
    Color? green,
    Color? greenDeep,
    Color? text,
    Color? muted,
    Color? faint,
    Color? warn,
    Color? danger,
    Color? blue,
    Color? heroFrom,
    Color? heroTo,
    Color? shadow,
    bool? isDark,
  }) {
    return Palette(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      cardHi: cardHi ?? this.cardHi,
      border: border ?? this.border,
      green: green ?? this.green,
      greenDeep: greenDeep ?? this.greenDeep,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      blue: blue ?? this.blue,
      heroFrom: heroFrom ?? this.heroFrom,
      heroTo: heroTo ?? this.heroTo,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return Palette(
      bg: mix(bg, other.bg),
      card: mix(card, other.card),
      cardHi: mix(cardHi, other.cardHi),
      border: mix(border, other.border),
      green: mix(green, other.green),
      greenDeep: mix(greenDeep, other.greenDeep),
      text: mix(text, other.text),
      muted: mix(muted, other.muted),
      faint: mix(faint, other.faint),
      warn: mix(warn, other.warn),
      danger: mix(danger, other.danger),
      blue: mix(blue, other.blue),
      heroFrom: mix(heroFrom, other.heroFrom),
      heroTo: mix(heroTo, other.heroTo),
      shadow: mix(shadow, other.shadow),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Android 上没有这个家族名会自动回退到系统默认字体，不影响中文
const String kFontFamily = 'Microsoft YaHei';
