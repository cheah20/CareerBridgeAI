import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// Page background. Plain paper in light mode; slow-moving soft light in dark mode.
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
    if (t.sceneBlobs.isEmpty) return ColoredBox(color: t.sceneBase);
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

/// Frosted bar: whatever scrolls under it shows through, blurred.
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.border = const Border(), this.radius = 0, this.color});

  final Widget child;
  final BoxBorder border;
  final double radius;

  /// Defaults to the theme's bar colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color ?? t.bar, border: border, borderRadius: radius > 0 ? BorderRadius.circular(radius) : null),
          child: child,
        ),
      ),
    );
  }
}

/// Background photo for the public pages.
class PhotoBackground extends StatelessWidget {
  const PhotoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF1C2238)),
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3, tileMode: TileMode.clamp),
          child: const Image(image: AssetImage('web/background/kl-skyline.jpg'), fit: BoxFit.cover, alignment: Alignment(-0.2, 0)),
        ),
        const ColoredBox(color: Color(0x47101528)),
      ],
    );
  }
}

/// A plain card with a thin border.
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
    return _GlassSurface(
      color: selected ? t.selected : t.card,
      edge: selected ? t.text.withValues(alpha: 0.25) : t.cardEdge,
      highlight: t.highlight,
      radius: 12,
      padding: padding,
      child: child,
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

/// The one dark card per page (e.g. "Upcoming interview").
class FocusCard extends StatelessWidget {
  const FocusCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.cardEdge),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? t.textSub),
      ),
    );
  }
}
