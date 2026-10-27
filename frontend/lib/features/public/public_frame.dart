import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/layout/breakpoints.dart';
import '../../core/widgets/glass.dart';

/// Pages guests can see (landing, job browsing, login): skyline photo, glass top bar, glass panel.
class PublicFrame extends StatelessWidget {
  const PublicFrame({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.centerContent = false,
    this.showLoginButton = true,
    this.panel = true,
  });

  final Widget child;
  final double maxWidth;

  /// Vertically centre short content (e.g. the login form).
  final bool centerContent;

  /// Hidden on the login page itself.
  final bool showLoginButton;

  /// Put the content on one glass panel. The landing page lays out its own panels.
  final bool panel;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final compact = ScreenSize.of(context).isCompact;
    final body = panel ? GlassPanel(padding: EdgeInsets.all(compact ? 18 : 32), child: child) : child;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PhotoBackground(),
          Column(
            children: [
              GlassBar(
                border: Border(bottom: BorderSide(color: t.shellEdge)),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 60,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
                          child: _NavRow(showLoginButton: showLoginButton),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24, vertical: compact ? 16 : 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          minHeight: centerContent ? constraints.maxHeight - (compact ? 32 : 80) : 0,
                        ),
                        child: centerContent ? Center(child: body) : body,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.showLoginButton});

  final bool showLoginButton;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'C',
                        style: TextStyle(color: t.inkText, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'CareerBridge',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: t.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (constraints.maxWidth >= 640 || !showLoginButton)
            TextButton(onPressed: () => context.go('/jobs'), child: const Text('Browse jobs')),
          if (showLoginButton) ...[
            const SizedBox(width: 8),
            FilledButton(onPressed: () => context.go('/login'), child: const Text('Log in')),
          ],
        ],
      ),
    );
  }
}

/// Frosted panel that sits on the photo. Thick enough that text stays easy to read.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(32)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final light = t.brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x40101528), blurRadius: 50, offset: Offset(0, 20), spreadRadius: -10),
        ],
      ),
      child: GlassBar(
        radius: 16,
        color: light ? const Color(0xDEFBFBF9) : const Color(0xCC12141C),
        border: Border.all(color: light ? const Color(0xCCFFFFFF) : const Color(0x24FFFFFF)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
