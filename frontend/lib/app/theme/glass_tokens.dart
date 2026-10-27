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
    required this.bar,
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
    required this.successSoft,
    required this.warning,
    required this.danger,
    required this.sceneBase,
    required this.sceneBlobs,
    required this.sceneVeil,
    required this.blurSigma,
  });

  final Brightness brightness;

  // Text.
  final Color text;
  final Color textSub;
  final Color textFaint;

  // Side menu.
  final Color shell;
  final Color shellEdge;

  // Frosted glass for the top bar and the open side menu (content scrolls under it).
  final Color bar;

  // Cards.
  final Color card;
  final Color cardEdge;
  final Color highlight;
  final Color row;
  final Color selected;

  // Links and small highlights.
  final Color accent;

  // The one dark card per page (e.g. "Upcoming interview").
  final Color focusCard;
  final Color focusText;
  final Color focusTextSub;
  final Color focusGlow;

  // Main button.
  final Color ink;
  final Color inkText;

  // Green = you have it, amber = points you can add, red = problem.
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color danger;

  // Background behind everything.
  final Color sceneBase;
  final List<SceneBlob> sceneBlobs;
  final Color sceneVeil;

  /// Blur used by the glass bars.
  final double blurSigma;

  /// Light: paper white, navy text, green and amber. All text is 4.5:1 or more.
  static const paper = GlassTokens(
    brightness: Brightness.light,
    text: Color(0xFF172033),
    textSub: Color(0xFF4A5468),
    textFaint: Color(0xFF656D7C),
    shell: Color(0xFFFBFBF9),
    shellEdge: Color(0xFFE3E4E0),
    bar: Color(0xA8FBFBF9),
    card: Color(0xFFFFFFFF),
    cardEdge: Color(0xFFE3E4E0),
    highlight: Color(0x00FFFFFF),
    row: Color(0xFFF3F4F1),
    selected: Color(0xFFECEEE9),
    accent: Color(0xFF2F5BD3),
    focusCard: Color(0xFF172033),
    focusText: Color(0xFFF3F5F8),
    focusTextSub: Color(0xFFC5CBD6),
    focusGlow: Color(0xFF26355A),
    ink: Color(0xFF172033),
    inkText: Color(0xFFFFFFFF),
    success: Color(0xFF047C58),
    successSoft: Color(0xFFE8F3ED),
    warning: Color(0xFF9A5A0E),
    danger: Color(0xFFB3261E),
    sceneBase: Color(0xFFFBFBF9),
    sceneBlobs: [],
    sceneVeil: Color(0x00000000),
    blurSigma: 16,
  );

  /// Dark: smoky glass over soft purple and teal light.
  static const night = GlassTokens(
    brightness: Brightness.dark,
    text: Color(0xFFF2F2F4),
    textSub: Color(0xFFC4C6CF),
    textFaint: Color(0xFF9EA1AE),
    shell: Color(0x8C12141C),
    shellEdge: Color(0x1FFFFFFF),
    bar: Color(0x9912141C),
    card: Color(0x8C1E1F26),
    cardEdge: Color(0x1FFFFFFF),
    highlight: Color(0x2EFFFFFF),
    row: Color(0x0FFFFFFF),
    selected: Color(0x24FFFFFF),
    accent: Color(0xFF60CDFF),
    focusCard: Color(0xE6070A14),
    focusText: Color(0xFFF2F2F4),
    focusTextSub: Color(0xFFB4B8C4),
    focusGlow: Color(0x993B2A7A),
    ink: Color(0xFFF2F2F4),
    inkText: Color(0xFF0B1020),
    success: Color(0xFF5FD7A5),
    successSoft: Color(0x245FD7A5),
    warning: Color(0xFFFFC46B),
    danger: Color(0xFFFF8A80),
    sceneBase: Color(0xFF0B1020),
    sceneBlobs: nightScene,
    sceneVeil: Color(0x00000000),
    blurSigma: 24,
  );

  /// Soft purple and teal glow for dark mode.
  static const nightScene = <SceneBlob>[
    SceneBlob(Rect.fromLTWH(-0.15, -0.20, 0.75, 0.75), Color(0xB33B2A7A)),
    SceneBlob(Rect.fromLTWH(0.50, 0.40, 0.70, 0.80), Color(0xA60D4F6E)),
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
      bar: c(bar, other.bar),
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
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      sceneBase: c(sceneBase, other.sceneBase),
      sceneBlobs: t < 0.5 ? sceneBlobs : other.sceneBlobs,
      sceneVeil: c(sceneVeil, other.sceneVeil),
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }
}

/// One soft colour shape in the background.
@immutable
class SceneBlob {
  const SceneBlob(this.bounds, this.color);

  /// Position and size as fractions of the screen (0 to 1, may go past the edges).
  final Rect bounds;
  final Color color;
}
