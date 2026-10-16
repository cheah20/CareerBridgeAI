import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/layout/breakpoints.dart';
import '../../core/widgets/glass.dart';

/// Glass window for pages guests can see (landing, job browsing, login).
class PublicFrame extends StatelessWidget {
  const PublicFrame({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.centerContent = false,
    this.showLoginButton = true,
  });

  final Widget child;
  final double maxWidth;

  /// Vertically centre short content (e.g. the login form) in the window.
  final bool centerContent;

  /// Hidden on the login page itself.
  final bool showLoginButton;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final compact = ScreenSize.of(context).isCompact;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 8 : 24),
                  child: GlassWindow(
                    padding: EdgeInsets.all(compact ? 14 : 24),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => Row(
                            children: [
                              Flexible(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => context.go('/'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(10)),
                                        child: Text('C', style: TextStyle(color: t.inkText, fontWeight: FontWeight.w700)),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          'CareerBridge AI',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.text),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (constraints.maxWidth >= 640 || !showLoginButton)
                                TextButton(onPressed: () => context.go('/jobs'), child: const Text('Browse jobs')),
                              if (showLoginButton) ...[
                                const SizedBox(width: 8),
                                FilledButton(onPressed: () => context.go('/login'), child: const Text('Log in')),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: centerContent
                                  ? ConstrainedBox(
                                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                                      child: Center(child: child),
                                    )
                                  : child,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
