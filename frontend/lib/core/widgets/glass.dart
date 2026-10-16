import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// Soft, defocused "photo" behind the glass. Drawn with radial gradients
/// (no blur filter), so it costs almost nothing to render.
///
/// The scene drifts very slowly (moving background, still cards). Only the
/// scene layer is transformed, and it stays still when the system asks for
/// reduced motion.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key});

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 20));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final scene = RepaintBoundary(child: CustomPaint(painter: _ScenePainter(t.sceneBase, t.sceneBlobs)));
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: t.sceneBase),
        AnimatedBuilder(
          animation: _drift,
          child: scene,
          builder: (context, child) {
            final v = Curves.easeInOut.transform(_drift.value);
            return FractionalTranslation(
              translation: Offset(-0.02 + 0.04 * v, 0.015 - 0.03 * v),
              child: Transform.scale(scale: 1.08, child: child),
            );
          },
        ),
        ColoredBox(color: t.sceneVeil),
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.base, this.blobs);

  final Color base;
  final List<SceneBlob> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    for (final blob in blobs) {
      final rect = Rect.fromLTWH(
        blob.bounds.left * size.width,
        blob.bounds.top * size.height,
        blob.bounds.width * size.width,
        blob.bounds.height * size.height,
      );
      // Draw a unit circle stretched into the blob's ellipse, fading to transparent.
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(rect.width / 2, rect.height / 2);
      final paint = Paint()
        ..shader = ui.Gradient.radial(Offset.zero, 1, [
          blob.color,
          blob.color.withValues(alpha: blob.color.a * 0.55),
          blob.color.withValues(alpha: 0),
        ], [0, 0.45, 1]);
      canvas.drawCircle(Offset.zero, 1, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.base != base || old.blobs != blobs;
}

/// The big floating glass window. The only widget that uses a real
/// background blur ([BackdropFilter]) — keep it to one per screen.
class GlassWindow extends StatelessWidget {
  const GlassWindow({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  static const radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 48, offset: Offset(0, 20), spreadRadius: -16)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
          child: _GlassSurface(
            color: t.shell,
            edge: t.shellEdge,
            highlight: t.highlight,
            radius: radius,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A card on the glass window: translucent fill, white hairline and a top
/// highlight, with a light shadow so it floats. Looks like glass without the
/// cost of a real blur.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Brighter "lifted" glass for the selected item.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: _GlassSurface(
        color: selected ? t.selected : t.card,
        edge: t.cardEdge,
        highlight: t.highlight,
        radius: 18,
        padding: padding,
        child: child,
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.color,
    required this.edge,
    required this.highlight,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final Color color;
  final Color edge;
  final Color highlight;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Light catching the top rim of the glass.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight.withValues(alpha: highlight.a * 0.35), highlight.withValues(alpha: 0)],
          stops: const [0, 0.08],
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// The one dark, glowing focus card per page (e.g. "Upcoming interview").
class FocusCard extends StatelessWidget {
  const FocusCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
        gradient: RadialGradient(
          center: const Alignment(-1.1, -1.3),
          radius: 1.1,
          colors: [t.focusGlow, t.focusCard],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: DefaultTextStyle.merge(style: TextStyle(color: t.focusText), child: child),
    );
  }
}

/// Small pill label, e.g. "Sample data" or a status.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.row,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.cardEdge),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? t.textSub),
      ),
    );
  }
}
