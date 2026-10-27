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

const _railNarrow = 72.0;
const _railWide = 240.0;
const _barHeight = 60.0;

/// Layout around every signed-in page: side menu, glass top bar, scrolling content.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // The menu opens while the mouse is on it, or stays open when pinned.
  bool _hover = false;
  bool _pinned = false;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionProvider).role;
    if (role == null) return const SizedBox.shrink(); // the router redirects guests away
    final items = navItemsFor(role);
    final location = GoRouterState.of(context).uri.path;
    final current = _currentItem(items, location);
    final size = ScreenSize.of(context);

    if (size.isCompact) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SceneBackground(),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(role: role, current: current, compact: true),
                  Expanded(
                    child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), child: widget.child),
                  ),
                  MobileBottomNav(items: items, current: current),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final inset = _pinned ? _railWide : _railNarrow;
    final open = _pinned || _hover;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(),
          // Content scrolls under the glass top bar.
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(left: inset),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, _barHeight + 28, 40, 48),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: widget.child),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            left: inset,
            right: 0,
            top: 0,
            height: _barHeight,
            child: _TopBar(role: role, current: current, compact: false),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: _Rail(
                items: items,
                current: current,
                open: open,
                floating: open && !_pinned,
                pinned: _pinned,
                onPin: () => setState(() => _pinned = !_pinned),
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(8)),
      child: Text('C', style: TextStyle(color: t.inkText, fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }
}

/// Side menu: icons only until the mouse moves onto it.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.items,
    required this.current,
    required this.open,
    required this.floating,
    required this.pinned,
    required this.onPin,
  });

  final List<NavItem> items;
  final NavItem current;
  final bool open;

  /// Open over the page (not pinned), so it gets glass and a shadow.
  final bool floating;
  final bool pinned;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 0, 18),
        child: Row(
          children: [
            const _Logo(),
            Expanded(child: _Fade(open: open, gap: 12, child: Text('CareerBridge', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: t.text)))),
          ],
        ),
      ),
    ];
    String? group;
    for (final item in items) {
      if (item.group != group) {
        group = item.group;
        children.add(SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 12, 4),
            child: open
                ? _Fade(open: open, child: Text(group, style: TextStyle(fontSize: 13, color: t.textFaint)))
                : Align(alignment: Alignment.centerLeft, child: SizedBox(width: 24, child: Divider(color: t.cardEdge))),
          ),
        ));
      }
      children.add(_RailTile(item: item, selected: item == current, open: open));
    }

    final menu = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: open ? _railWide : _railNarrow,
      decoration: BoxDecoration(
        color: floating ? Colors.transparent : t.shell,
        border: Border(right: BorderSide(color: t.shellEdge)),
      ),
      child: Column(
        children: [
          Expanded(child: ListView(padding: EdgeInsets.zero, children: children)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 0, 14),
            child: Row(
              children: [
                IconButton(
                  constraints: const BoxConstraints.tightFor(width: 48, height: 40),
                  padding: EdgeInsets.zero,
                  tooltip: pinned ? 'Let the menu hide' : 'Keep the menu open',
                  onPressed: onPin,
                  icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: t.textSub),
                ),
                Expanded(child: _Fade(open: open, child: Text(pinned ? 'Menu pinned' : 'Pin menu', style: TextStyle(fontSize: 13, color: t.textFaint)))),
              ],
            ),
          ),
        ],
      ),
    );
    if (!floating) return menu;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x29172033), blurRadius: 32, offset: Offset(8, 0))]),
      child: GlassBar(child: menu),
    );
  }
}

/// Label that fades in with the menu, so no half-cut letters show while it opens.
class _Fade extends StatelessWidget {
  const _Fade({required this.open, required this.child, this.gap = 0});

  final bool open;
  final Widget child;

  /// Space before the label, collapsed with it.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: open ? 220 : 80),
      opacity: open ? 1 : 0,
      child: Padding(
        padding: EdgeInsets.only(left: gap),
        child: DefaultTextStyle.merge(maxLines: 1, softWrap: false, overflow: TextOverflow.clip, child: child),
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({required this.item, required this.selected, required this.open});

  final NavItem item;
  final bool selected;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(item.path),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: selected ? t.selected : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: selected ? t.text : t.textSub),
                Expanded(
                  child: _Fade(
                    open: open,
                    gap: 12,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 15,
                        color: selected ? t.text : t.textSub,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return open ? tile : Tooltip(message: item.label, waitDuration: const Duration(milliseconds: 400), child: tile);
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
    return GlassBar(
      border: Border(bottom: BorderSide(color: t.shellEdge)),
      child: SizedBox(
        height: compact ? 56 : _barHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 40),
          child: Row(
            children: [
              if (compact) ...[const _Logo(), const SizedBox(width: 10)],
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    if (!compact) TextSpan(text: '${role.label} / ', style: TextStyle(color: t.textSub)),
                    TextSpan(text: current.label, style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
                  ]),
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: style == GlassStyle.night ? 'Switch to light' : 'Switch to dark',
                onPressed: () => ref.read(glassStyleProvider.notifier).toggle(),
                icon: Icon(style == GlassStyle.night ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.textSub),
              ),
              const SizedBox(width: 4),
              _AccountMenu(role: role, compact: compact),
            ],
          ),
        ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: t.accent,
            child: Text(role.label[0], style: TextStyle(fontSize: 13, color: t.inkText, fontWeight: FontWeight.w700)),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(name, style: TextStyle(fontSize: 15, color: t.text)),
          ],
          const SizedBox(width: 2),
          Icon(Icons.expand_more, size: 18, color: t.textSub),
        ],
      ),
    );
  }
}
