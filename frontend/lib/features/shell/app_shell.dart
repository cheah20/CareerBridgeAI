import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/glass_tokens.dart';
import '../../core/layout/breakpoints.dart';
import '../../core/widgets/glass.dart';
import '../../mobile_ui/mobile_bottom_nav.dart';
import '../auth/session.dart';
import 'nav_items.dart';

/// The floating glass window around every signed-in page, with the sidebar.
/// Narrow windows fall back to the parked mobile bottom navigation (lib/mobile_ui).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionProvider).role;
    if (role == null) return const SizedBox.shrink(); // the router redirects guests away
    final items = navItemsByRole[role]!;
    final location = GoRouterState.of(context).uri.path;
    final current = _currentItem(items, location);
    final size = ScreenSize.of(context);

    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(size.isCompact ? 4 : 8, 8, size.isCompact ? 4 : 8, 24),
      child: child,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(size.isCompact ? 8 : 24),
              child: GlassWindow(
                padding: EdgeInsets.all(size.isCompact ? 10 : 18),
                child: size.isCompact
                    ? Column(
                        children: [
                          _TopBar(role: role, current: current, compact: true),
                          Expanded(child: content),
                          MobileBottomNav(items: items, current: current),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 224, child: _Sidebar(items: items, current: current)),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              children: [
                                _TopBar(role: role, current: current, compact: false),
                                Expanded(child: content),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static NavItem _currentItem(List<NavItem> items, String location) {
    // The longest matching path wins, so "/seeker/jobs" beats "/seeker".
    final matches = items.where((i) => location == i.path || location.startsWith('${i.path}/')).toList()
      ..sort((a, b) => b.path.length.compareTo(a.path.length));
    return matches.isNotEmpty ? matches.first : items.first;
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(10)),
          child: Text('C', style: TextStyle(color: t.inkText, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CareerBridge', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.text)),
              Text('AI CAREER PARTNER', style: TextStyle(fontSize: 9.5, letterSpacing: 1.3, color: t.textFaint)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.current});

  final List<NavItem> items;
  final NavItem current;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final children = <Widget>[
      const Padding(padding: EdgeInsets.fromLTRB(8, 4, 8, 14), child: _Brand()),
    ];
    String? group;
    for (final item in items) {
      if (item.group != group) {
        group = item.group;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
          child: Text(group.toUpperCase(), style: TextStyle(fontSize: 10.5, letterSpacing: 1.3, color: t.textFaint)),
        ));
      }
      children.add(_SideNavTile(item: item, selected: item == current));
    }
    return ListView(padding: EdgeInsets.zero, children: children);
  }
}

class _SideNavTile extends StatelessWidget {
  const _SideNavTile({required this.item, required this.selected});

  final NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(item.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? t.selected : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: selected ? t.text : t.textSub),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: selected ? t.text : t.textSub,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.role, required this.current, required this.compact});

  final UserRole role;
  final NavItem current;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GlassTokens.of(context);
    final style = ref.watch(glassStyleProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: compact
                ? const _Brand()
                : Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${role.label} / ', style: TextStyle(color: t.textFaint)),
                      TextSpan(text: current.label, style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                    ]),
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          IconButton(
            tooltip: style == GlassStyle.smoke ? 'Switch to light glass' : 'Switch to dark glass',
            onPressed: () => ref.read(glassStyleProvider.notifier).toggle(),
            icon: Icon(style == GlassStyle.smoke ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.textSub),
          ),
          const SizedBox(width: 4),
          _AccountMenu(role: role, compact: compact),
        ],
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.role, required this.compact});

  final UserRole role;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GlassTokens.of(context);
    final name = ref.watch(sessionProvider).displayName;
    return PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'sign-out') {
          context.go('/');
          ref.read(sessionProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, child: Text(name, style: TextStyle(color: t.focusTextSub))),
        const PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.cardEdge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: t.accent,
              child: Text(role.label[0], style: TextStyle(fontSize: 12, color: t.inkText, fontWeight: FontWeight.w700)),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text(name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.text)),
            ],
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: t.textSub),
          ],
        ),
      ),
    );
  }
}
