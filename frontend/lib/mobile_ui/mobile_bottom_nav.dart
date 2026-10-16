import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/glass_tokens.dart';
import '../features/shell/nav_items.dart';

/// Bottom navigation for narrow screens (phones).
///
/// Parked: mobile layouts are scheduled after the web demo (see README.md in
/// this folder). It is only used as a basic fallback when the window is narrow.
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key, required this.items, required this.current});

  final List<NavItem> items;
  final NavItem current;

  static const _visible = 4;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final shown = items.take(_visible).toList();
    final moreSelected = !shown.contains(current);
    return Container(
      key: const Key('bottom-nav'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.cardEdge),
      ),
      child: Row(
        children: [
          for (final item in shown)
            Expanded(
              child: _BottomTab(
                icon: item.icon,
                label: item.label.split(' ').first,
                selected: item == current,
                onTap: () => context.go(item.path),
              ),
            ),
          if (items.length > _visible)
            Expanded(
              child: _BottomTab(
                icon: Icons.more_horiz,
                label: 'More',
                selected: moreSelected,
                onTap: () => _showMore(context, items.skip(_visible).toList()),
              ),
            ),
        ],
      ),
    );
  }

  void _showMore(BuildContext context, List<NavItem> rest) {
    final t = GlassTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in rest)
              ListTile(
                leading: Icon(item.icon, color: t.focusTextSub),
                title: Text(item.label, style: TextStyle(color: t.focusText)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go(item.path);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? t.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: selected ? t.text : t.textSub),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: selected ? t.text : t.textSub, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
