import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';

// table header, flex sets each column's width
class TableHead extends StatelessWidget {
  const TableHead({super.key, required this.labels, required this.flex});

  final List<String> labels;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.cardEdge)),
      ),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              flex: flex[i],
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.textSub),
              ),
            ),
        ],
      ),
    );
  }
}

// table row matching TableHead
class TableLine extends StatelessWidget {
  const TableLine({super.key, required this.cells, required this.flex});

  final List<Widget> cells;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.cardEdge.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          for (final (i, cell) in cells.indexed)
            Expanded(
              flex: flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Align(alignment: Alignment.centerLeft, child: cell),
              ),
            ),
        ],
      ),
    );
  }
}

// bold line with a grey line under it
class TwoLines extends StatelessWidget {
  const TwoLines(this.title, this.subtitle, {super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 14, color: t.textSub)),
      ],
    );
  }
}

// skill the applicant has or lacks
class SkillTag extends StatelessWidget {
  const SkillTag(this.label, {super.key, required this.have});

  final String label;
  final bool have;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final color = have ? t.success : t.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: have ? t.successSoft : t.row,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(have ? Icons.check : Icons.close, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// label above a group of fields
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.textSub),
      ),
    );
  }
}

// back button on sub-pages
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go(path),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text(label),
      ),
    );
  }
}

// two fields side by side, stacked when narrow
class FieldPair extends StatelessWidget {
  const FieldPair(this.left, this.right, {super.key});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

void showDone(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
