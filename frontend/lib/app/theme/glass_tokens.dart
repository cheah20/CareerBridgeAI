import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// All app colours in one place. [GlassTokens.paper] is the default.
/// Use `GlassTokens.of(context)` to read them.
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.brightness,
    required this.text,
    required this.textSub,
    required this.textFaint,
    required this.shell,
    required this.shellEdge,
    required this.card,
    required this.cardEdge,
    required this.highlight,
    required this.row,
    required this.selected,
    required this.accent,
    required this.focusCard,
    required this.focusText,
    required this.focusTextSub,
    required this.focusGlow,
    required this.ink,
    required this.inkText,
    required this.success,
    required this.warning,
    required this.danger,
    required this.sceneBase,
    required this.sceneBlobs,
    required this.sceneVeil,
    required this.blurSigma,
  });

  final Brightness brightness;

  // Text on glass.
  final Color text;
  final Color textSub;
  final Color textFaint;

  // The big floating window (the only surface with real background blur).
  final Color shell;
  final Color shellEdge;

  // Cards inside the window: translucent fill + hairline + top highlight.
  final Color card;
  final Color cardEdge;
  final Color highlight;
  final Color row;
  final Color selected;

  final Color accent;

  // The single dark focus card per page (e.g. "Upcoming interview").
  final Color focusCard;
  final Color focusText;
  final Color focusTextSub;
  final Color focusGlow;

  // Primary button ("ink"): black on light glass, white on dark glass.
  final Color ink;
  final Color inkText;

  // Status colours (match levels, skill gaps, alerts).
  final Color success;
  final Color warning;
  final Color danger;

  // Background scene behind the glass.
  final Color sceneBase;
  final List<SceneBlob> sceneBlobs;
  final Color sceneVeil;

  /// Blur strength of the big window (the design value "40px").
  final double blurSigma;

  /// Default look, chosen in the design preview: glass opacity 31%, blur 40.
  static const smoke = GlassTokens(
    brightness: Brightness.dark,
    text: Color(0xFFF4F7FB),
    textSub: Color(0xC7EAF0F8),
    textFaint: Color(0x8FE2E9F3),
    shell: Color(0x21788492), // rgba(120,132,146, 0.13)
    shellEdge: Color(0x47FFFFFF),
    card: Color(0x1AFFFFFF), // white 10%
    cardEdge: Color(0x33FFFFFF),
    highlight: Color(0x59FFFFFF),
    row: Color(0x0FFFFFFF), // white 6%
    selected: Color(0x38FFFFFF), // white 22%
    accent: Color(0xFF8CC4FF),
    focusCard: Color(0xB80A0D14),
    focusText: Color(0xFFF3F6FB),
    focusTextSub: Color(0x9EE1E8F5),
    focusGlow: Color(0x736EAAFF),
    ink: Color(0xFFFFFFFF),
    inkText: Color(0xFF0F1626),
    success: Color(0xFF5FD7A5),
    warning: Color(0xFFF2C25A),
    danger: Color(0xFFFF8A80),
    sceneBase: Color(0xFFD8DCDF),
    sceneBlobs: officeScene,
    sceneVeil: Color(0x61121822),
    blurSigma: 40,
  );

  /// Light page, white cards, dark text (default).
  static const paper = GlassTokens(
    brightness: Brightness.light,
    text: Color(0xFF111827),
    textSub: Color(0xFF4B5563),
    textFaint: Color(0xFF5B6472),
    shell: Color(0xFFF4F6F9),
    shellEdge: Color(0xFFE1E6ED),
    card: Color(0xFFFFFFFF),
    cardEdge: Color(0xFFE1E6ED),
    highlight: Color(0x00FFFFFF),
    row: Color(0xFFF1F4F8),
    selected: Color(0xFFE8F0FD),
    accent: Color(0xFF2F6FDB),
    focusCard: Color(0xFF111827),
    focusText: Color(0xFFF3F6FB),
    focusTextSub: Color(0xFFC9D1DC),
    focusGlow: Color(0xFF1F2A44),
    ink: Color(0xFF111827),
    inkText: Color(0xFFFFFFFF),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
    sceneBase: Color(0xFFE9EDF2),
    sceneBlobs: [],
    sceneVeil: Color(0x00000000),
    blurSigma: 0,
  );

  /// Optional light mode.
  static const ice = GlassTokens(
    brightness: Brightness.light,
    text: Color(0xFF111A2B),
    textSub: Color(0xFF586377),
    textFaint: Color(0xFF7C8698),
    shell: Color(0x42FFFFFF),
    shellEdge: Color(0x9EFFFFFF),
    card: Color(0x85FFFFFF),
    cardEdge: Color(0xD9FFFFFF),
    highlight: Color(0xEBFFFFFF),
    row: Color(0x57FFFFFF),
    selected: Color(0xE6FFFFFF),
    accent: Color(0xFF3F7BE0),
    focusCard: Color(0xE6101521),
    focusText: Color(0xFFF3F6FB),
    focusTextSub: Color(0x9EE1E8F5),
    focusGlow: Color(0x8C4A86E8),
    ink: Color(0xFF111827),
    inkText: Color(0xFFFFFFFF),
    success: Color(0xFF1F9D6F),
    warning: Color(0xFFD4911A),
    danger: Color(0xFFD9483F),
    sceneBase: Color(0xFFD8DCDF),
    sceneBlobs: officeScene,
    sceneVeil: Color(0x00000000),
    blurSigma: 28,
  );

  /// A defocused office: warm wall, window light, teal chair, wooden desk.
  static const officeScene = <SceneBlob>[
    SceneBlob(Rect.fromLTWH(-0.10, -0.15, 0.70, 0.55), Color(0xFFF1EDE6)),
    SceneBlob(Rect.fromLTWH(0.57, -0.10, 0.55, 0.60), Color(0xFFA9C4DD)),
    SceneBlob(Rect.fromLTWH(0.30, 0.35, 0.45, 0.50), Color(0xB33F7C77)),
    SceneBlob(Rect.fromLTWH(-0.08, 0.70, 0.35, 0.45), Color(0xBFB98A5E)),
    SceneBlob(Rect.fromLTWH(0.65, 0.72, 0.30, 0.40), Color(0xFF7D8A96)),
    SceneBlob(Rect.fromLTWH(0.62, 0.05, 0.18, 0.70), Color(0xE6FFFFFF)),
  ];

  static GlassTokens of(BuildContext context) => Theme.of(context).extension<GlassTokens>()!;

  @override
  GlassTokens copyWith() => this;

  @override
  GlassTokens lerp(covariant GlassTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return GlassTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      text: c(text, other.text),
      textSub: c(textSub, other.textSub),
      textFaint: c(textFaint, other.textFaint),
      shell: c(shell, other.shell),
      shellEdge: c(shellEdge, other.shellEdge),
      card: c(card, other.card),
      cardEdge: c(cardEdge, other.cardEdge),
      highlight: c(highlight, other.highlight),
      row: c(row, other.row),
      selected: c(selected, other.selected),
      accent: c(accent, other.accent),
      focusCard: c(focusCard, other.focusCard),
      focusText: c(focusText, other.focusText),
      focusTextSub: c(focusTextSub, other.focusTextSub),
      focusGlow: c(focusGlow, other.focusGlow),
      ink: c(ink, other.ink),
      inkText: c(inkText, other.inkText),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      sceneBase: c(sceneBase, other.sceneBase),
      sceneBlobs: t < 0.5 ? sceneBlobs : other.sceneBlobs,
      sceneVeil: c(sceneVeil, other.sceneVeil),
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }
}

/// One soft colour shape in the background scene.
@immutable
class SceneBlob {
  const SceneBlob(this.bounds, this.color);

  /// Position and size as fractions of the scene (0–1, may overflow edges).
  final Rect bounds;
  final Color color;
}
