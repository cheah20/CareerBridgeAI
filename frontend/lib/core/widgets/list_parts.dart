import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// Spacing scale for page layout: generous, so information can breathe.
abstract final class Gaps {
  static const section = 28.0;
  static const block = 20.0;
}

/// Main content with a side column; stacks into one column when narrow.
class TwoPane extends StatelessWidget {
  const TwoPane({super.key, required this.main, required this.side});

  final Widget main;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [main, const SizedBox(height: Gaps.block), side]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: main),
            const SizedBox(width: Gaps.block),
            Expanded(flex: 2, child: side),
          ],
        );
      },
    );
  }
}

/// A row inside a glass card: initials badge, title + subtitle, value on the right.
/// Plain value text with a thin coloured line under it.
class GlassListRow extends StatelessWidget {
  const GlassListRow({
    super.key,
    required this.initials,
    required this.title,
    required this.subtitle,
    this.value,
    this.valueCaption,
    this.progress,
    this.selected = false,
  });

  final String initials;
  final String title;
  final String subtitle;
  final String? value;
  final String? valueCaption;

  /// 0–1; draws a thin line under the value (e.g. match percentage).
  final double? progress;

  /// Brighter glass for the highlighted row.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? t.selected : t.row,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardEdge),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.cardEdge),
            ),
            child: Text(initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSub)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: t.textSub)),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 14),
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.text,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  if (progress != null) ...[
                    const SizedBox(height: 4),
                    _ThinLine(value: progress!, color: t.accent),
                  ],
                  if (valueCaption != null) ...[
                    const SizedBox(height: 3),
                    Text(valueCaption!, style: TextStyle(fontSize: 10.5, color: t.textFaint)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThinLine extends StatelessWidget {
  const _ThinLine({required this.value, required this.color, this.thickness = 2});

  final double value;
  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(value: value, minHeight: thickness, backgroundColor: t.row, color: color),
    );
  }
}

/// Labelled thin progress line, e.g. a skill level.
class LevelBar extends StatelessWidget {
  const LevelBar({super.key, required this.label, required this.value, required this.color, required this.caption});

  final String label;

  /// 0–1.
  final double value;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(label, style: TextStyle(fontSize: 13, color: t.text))),
          Expanded(
            child: Semantics(
              label: '$label level: $caption',
              child: ExcludeSemantics(child: _ThinLine(value: value, color: color, thickness: 4)),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(caption, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: t.textSub)),
          ),
        ],
      ),
    );
  }
}

/// One entry on the thin timeline inside the dark focus card.
class FocusEntry extends StatelessWidget {
  const FocusEntry({super.key, required this.title, required this.subtitle, this.isLast = false});

  final String title;
  final String subtitle;

  /// The last entry has no line continuing below its dot.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(width: 7, height: 7, decoration: BoxDecoration(color: t.focusText, shape: BoxShape.circle)),
                if (!isLast)
                  Expanded(child: Container(width: 1, margin: const EdgeInsets.only(top: 4), color: t.focusTextSub.withValues(alpha: 0.35))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: t.focusText)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: t.focusTextSub)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
