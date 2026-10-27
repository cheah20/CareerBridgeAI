import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'glass_tokens.dart';

enum GlassStyle { paper, night }

/// Light or dark (default: light).
final glassStyleProvider = NotifierProvider<GlassStyleNotifier, GlassStyle>(GlassStyleNotifier.new);

class GlassStyleNotifier extends Notifier<GlassStyle> {
  @override
  GlassStyle build() => GlassStyle.paper;

  void toggle() => state = state == GlassStyle.paper ? GlassStyle.night : GlassStyle.paper;
}

GlassTokens tokensFor(GlassStyle style) => switch (style) {
  GlassStyle.paper => GlassTokens.paper,
  GlassStyle.night => GlassTokens.night,
};

const appFont = 'Atkinson Hyperlegible';

/// Material 3 theme with our colours and font.
ThemeData buildAppTheme(GlassTokens t) {
  final scheme = ColorScheme.fromSeed(seedColor: t.accent, brightness: t.brightness).copyWith(
    primary: t.ink,
    onPrimary: t.inkText,
    secondary: t.accent,
    surface: t.sceneBase,
    onSurface: t.text,
    onSurfaceVariant: t.textSub,
    outline: t.cardEdge,
    outlineVariant: t.cardEdge,
    error: t.danger,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: appFont);
  final text = base.textTheme.apply(bodyColor: t.text, displayColor: t.text, fontFamily: appFont);

  final pillShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
  const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
  const buttonText = TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15);

  return base.copyWith(
    scaffoldBackgroundColor: t.sceneBase,
    extensions: [t],
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -0.6, height: 1.12),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: text.bodyMedium?.copyWith(color: t.textSub, fontSize: 15, height: 1.5),
      labelSmall: text.labelSmall?.copyWith(color: t.textFaint, fontSize: 13, letterSpacing: 0),
    ),
    iconTheme: IconThemeData(color: t.textSub, size: 20),
    dividerTheme: DividerThemeData(color: t.cardEdge, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.ink,
        foregroundColor: t.inkText,
        shape: pillShape,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        backgroundColor: t.row,
        side: BorderSide(color: t.cardEdge),
        shape: pillShape,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.text, textStyle: buttonText, shape: pillShape),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.row,
      hintStyle: TextStyle(color: t.textFaint),
      labelStyle: TextStyle(color: t.textSub),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.cardEdge)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.cardEdge)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.accent, width: 1.5)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: t.focusCard, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: t.focusText, fontSize: 13, fontFamily: appFont),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: t.focusCard, showDragHandle: true),
    popupMenuTheme: PopupMenuThemeData(
      color: t.focusCard,
      textStyle: TextStyle(color: t.focusText, fontFamily: appFont),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
