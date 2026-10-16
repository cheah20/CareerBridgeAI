import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/page_parts.dart';
import '../public/public_frame.dart';
import 'session.dart';

/// Login page (web layout: welcome on the left, form on the right).
/// Real Supabase login is task 1.5.
///
/// In debug builds a "Developer preview" lets you enter each role's layout
/// without an account. It is never shown in release builds.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.redirectTo});

  /// Where to go after login (the page the guest originally asked for).
  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return PublicFrame(
      centerContent: true,
      showLoginButton: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const welcome = _Welcome();
            final form = _LoginPanel(redirectTo: redirectTo);
            if (constraints.maxWidth < 860) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [welcome, const SizedBox(height: 28), form],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(flex: 5, child: welcome),
                const SizedBox(width: 48),
                Expanded(flex: 4, child: form),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          kicker: 'Welcome back',
          title: 'Log in to CareerBridge.',
          subtitle: 'One account for your resume, job matches and applications.',
        ),
        SizedBox(height: 28),
        _RoleLine(
          icon: Icons.person_search_outlined,
          title: 'Job seekers',
          text: 'Analyse your resume, see matching jobs and prepare for interviews.',
        ),
        _RoleLine(
          icon: Icons.apartment_outlined,
          title: 'Recruiters',
          text: 'Publish jobs and review applicants with AI match results.',
        ),
        _RoleLine(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admins',
          text: 'Verify companies, review jobs and manage the AI models.',
        ),
      ],
    );
  }
}

class _RoleLine extends StatelessWidget {
  const _RoleLine({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.cardEdge),
            ),
            child: Icon(icon, size: 19, color: t.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
                const SizedBox(height: 2),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends ConsumerWidget {
  const _LoginPanel({required this.redirectTo});

  final String? redirectTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log in', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: t.text, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Email login with Supabase is added in task 1.5.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textFaint)),
              const SizedBox(height: 20),
              const TextField(enabled: false, decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 14),
              const TextField(enabled: false, obscureText: true, decoration: InputDecoration(labelText: 'Password')),
              const SizedBox(height: 20),
              const FilledButton(onPressed: null, child: Text('Log in')),
              const SizedBox(height: 8),
              const TextButton(onPressed: null, child: Text('Create an account')),
            ],
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          FocusCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Developer preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Open a role\'s layout without logging in. Debug builds only.',
                  style: TextStyle(fontSize: 12.5, color: t.focusTextSub),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in UserRole.values)
                      OutlinedButton(
                        key: Key('preview-${role.pathSegment}'),
                        style: OutlinedButton.styleFrom(foregroundColor: t.focusText, backgroundColor: Colors.transparent),
                        onPressed: () {
                          ref.read(sessionProvider.notifier).signInAs(role);
                          final target = redirectTo;
                          context.go(target != null && target.startsWith(role.homePath) ? target : role.homePath);
                        },
                        child: Text(role.label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
