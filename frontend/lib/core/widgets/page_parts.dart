import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import 'glass.dart';

/// Small context line, big title and one supporting sentence.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.kicker, required this.title, this.subtitle, this.trailing});

  final String kicker;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(kicker, style: TextStyle(fontSize: 15, color: t.textSub))),
            ?trailing,
          ],
        ),
        const SizedBox(height: 4),
        Text(title, style: theme.textTheme.displaySmall?.copyWith(color: t.text)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle!, style: theme.textTheme.bodyMedium),
          ),
        ],
      ],
    );
  }
}

class StatItem {
  const StatItem(this.label, this.value, this.caption);

  final String label;
  final String value;
  final String caption;
}

/// A row of big numbers inside one glass card; wraps to 2 columns on narrow screens.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = GlassTokens.of(context);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 560 ? 2 : items.length;
          final width = constraints.maxWidth / columns;
          return Wrap(
            children: [
              for (final (index, item) in items.indexed)
                Container(
                  width: width,
                  // Thin dividers between columns and rows.
                  decoration: BoxDecoration(
                    border: Border(
                      left: index % columns == 0 ? BorderSide.none : BorderSide(color: t.cardEdge),
                      top: index < columns ? BorderSide.none : BorderSide(color: t.cardEdge),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: TextStyle(fontSize: 14, color: t.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: t.text,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(item.caption, style: theme.textTheme.bodySmall?.copyWith(color: t.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Title row of a card.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: t.text))),
          if (trailing != null) Text(trailing!, style: TextStyle(fontSize: 12, color: t.textFaint)),
        ],
      ),
    );
  }
}

/// Placeholder for a feature that a later phase will build.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.description, required this.phase});

  final String title;
  final String description;
  final String phase;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(kicker: 'Coming in $phase', title: title, subtitle: description),
        const SizedBox(height: 20),
        GlassCard(
          child: Row(
            children: [
              Icon(Icons.construction_outlined, color: t.textFaint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This page is part of the app layout. Its features are built in $phase.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
