import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'glass_tokens.dart';

enum GlassStyle { paper, smoke, ice }

/// Which look the user picked (default: paper).
final glassStyleProvider = NotifierProvider<GlassStyleNotifier, GlassStyle>(GlassStyleNotifier.new);

class GlassStyleNotifier extends Notifier<GlassStyle> {
  @override
  GlassStyle build() => GlassStyle.paper;

  void toggle() => state = state == GlassStyle.paper ? GlassStyle.smoke : GlassStyle.paper;
}

GlassTokens tokensFor(GlassStyle style) => switch (style) {
  GlassStyle.paper => GlassTokens.paper,
  GlassStyle.smoke => GlassTokens.smoke,
  GlassStyle.ice => GlassTokens.ice,
};

/// Material 3 theme customised to the glass design.
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

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Inter');
  final text = base.textTheme.apply(bodyColor: t.text, displayColor: t.text, fontFamily: 'Inter');

  final pillShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
  const buttonText = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14);

  return base.copyWith(
    scaffoldBackgroundColor: t.sceneBase,
    extensions: [t],
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -1.2, height: 1.05),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.6),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
      bodyMedium: text.bodyMedium?.copyWith(color: t.textSub, height: 1.45),
      labelSmall: text.labelSmall?.copyWith(color: t.textFaint, letterSpacing: 1.4),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.cardEdge)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.cardEdge)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.accent, width: 1.5)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: t.focusCard, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: t.focusText, fontSize: 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: t.focusCard, showDragHandle: true),
    popupMenuTheme: PopupMenuThemeData(
      color: t.focusCard,
      textStyle: TextStyle(color: t.focusText, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
