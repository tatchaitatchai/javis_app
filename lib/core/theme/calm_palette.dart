import 'package:flutter/material.dart';

/// Calm Ambient design tokens from the MVP 1 flow (spec 012).
///
/// Names describe the role, not the colour, so dark mode can swap values:
/// `strong` is the ink call-to-action surface and `glow` the warm tile of a
/// light that is on.
@immutable
class CalmPalette extends ThemeExtension<CalmPalette> {
  const CalmPalette({
    required this.canvas,
    required this.paper,
    required this.raised,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.line,
    required this.hairline,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.accentTint,
    required this.strong,
    required this.strongRaised,
    required this.onStrong,
    required this.onStrongMuted,
    required this.glow,
    required this.glowTrack,
    required this.gold,
    required this.goldDeep,
    required this.warnBg,
    required this.warnText,
    required this.noteBg,
    required this.noteText,
    required this.danger,
    required this.scrim,
  });

  final Color canvas;
  final Color paper;
  final Color raised;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color line;
  final Color hairline;
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;
  final Color accentTint;
  final Color strong;
  final Color strongRaised;
  final Color onStrong;
  final Color onStrongMuted;
  final Color glow;
  final Color glowTrack;
  final Color gold;
  final Color goldDeep;
  final Color warnBg;
  final Color warnText;
  final Color noteBg;
  final Color noteText;
  final Color danger;
  final Color scrim;

  /// Text drawn on [gold] keeps the ink colour in both themes.
  static const onGold = Color(0xFF253026);

  static const light = CalmPalette(
    canvas: Color(0xFFF2F0E8),
    paper: Color(0xFFFBFAF5),
    raised: Color(0xFFE9E8DF),
    text: Color(0xFF253026),
    textMuted: Color(0xFF5E685C),
    textFaint: Color(0xFF8C9488),
    line: Color(0xFFCFD3C6),
    hairline: Color(0xFFE2E2D8),
    accent: Color(0xFF667860),
    accentDeep: Color(0xFF4F6249),
    accentSoft: Color(0xFF8FA287),
    accentTint: Color(0xFFE6EAE0),
    strong: Color(0xFF253026),
    strongRaised: Color(0xFF3A4639),
    onStrong: Color(0xFFFBFAF5),
    onStrongMuted: Color(0xFFCFD6C8),
    glow: Color(0xFFF4EAD3),
    glowTrack: Color(0xFFE9DDBF),
    gold: Color(0xFFE3C68C),
    goldDeep: Color(0xFFC9A962),
    warnBg: Color(0xFFF4E6C6),
    warnText: Color(0xFF8A6418),
    noteBg: Color(0xFFF4EAD3),
    noteText: Color(0xFF5B4A22),
    danger: Color(0xFFA04A3B),
    scrim: Color(0x73253026),
  );

  static const dark = CalmPalette(
    canvas: Color(0xFF151A15),
    paper: Color(0xFF1F261E),
    raised: Color(0xFF283027),
    text: Color(0xFFEDF0E8),
    textMuted: Color(0xFFB3BCAE),
    textFaint: Color(0xFF7F897B),
    line: Color(0xFF3C4739),
    hairline: Color(0xFF2E372C),
    accent: Color(0xFF9FB894),
    accentDeep: Color(0xFFB9CDAE),
    accentSoft: Color(0xFF6F8566),
    accentTint: Color(0xFF2B3628),
    strong: Color(0xFFE8EBE2),
    strongRaised: Color(0xFFD3D9CB),
    onStrong: Color(0xFF1A211A),
    onStrongMuted: Color(0xFF4A5547),
    glow: Color(0xFF3A3324),
    glowTrack: Color(0xFF4D4431),
    gold: Color(0xFFE3C68C),
    goldDeep: Color(0xFFC9A962),
    warnBg: Color(0xFF3D3220),
    warnText: Color(0xFFE6C47A),
    noteBg: Color(0xFF322C20),
    noteText: Color(0xFFE9DDBF),
    danger: Color(0xFFE08A7A),
    scrim: Color(0x99000000),
  );

  @override
  CalmPalette copyWith() => this;

  @override
  CalmPalette lerp(CalmPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return CalmPalette(
      canvas: mix(canvas, other.canvas),
      paper: mix(paper, other.paper),
      raised: mix(raised, other.raised),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      line: mix(line, other.line),
      hairline: mix(hairline, other.hairline),
      accent: mix(accent, other.accent),
      accentDeep: mix(accentDeep, other.accentDeep),
      accentSoft: mix(accentSoft, other.accentSoft),
      accentTint: mix(accentTint, other.accentTint),
      strong: mix(strong, other.strong),
      strongRaised: mix(strongRaised, other.strongRaised),
      onStrong: mix(onStrong, other.onStrong),
      onStrongMuted: mix(onStrongMuted, other.onStrongMuted),
      glow: mix(glow, other.glow),
      glowTrack: mix(glowTrack, other.glowTrack),
      gold: mix(gold, other.gold),
      goldDeep: mix(goldDeep, other.goldDeep),
      warnBg: mix(warnBg, other.warnBg),
      warnText: mix(warnText, other.warnText),
      noteBg: mix(noteBg, other.noteBg),
      noteText: mix(noteText, other.noteText),
      danger: mix(danger, other.danger),
      scrim: mix(scrim, other.scrim),
    );
  }
}

extension CalmPaletteContext on BuildContext {
  CalmPalette get palette =>
      Theme.of(this).extension<CalmPalette>() ?? CalmPalette.light;
}
