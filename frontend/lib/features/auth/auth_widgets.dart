import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/page_parts.dart';

/// Web layout shared by the login and sign-up pages:
/// welcome text on the left, the form on the right.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.kicker, required this.title, required this.subtitle, required this.form});

  final String kicker;
  final String title;
  final String subtitle;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final welcome = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(kicker: kicker, title: title, subtitle: subtitle),
        const SizedBox(height: 28),
        const _RoleLine(
          icon: Icons.person_search_outlined,
          title: 'Job seekers',
          text: 'Analyse your resume, see matching jobs and prepare for interviews.',
        ),
        const _RoleLine(
          icon: Icons.apartment_outlined,
          title: 'Recruiters',
          text: 'Publish jobs and review applicants with AI match results.',
        ),
        const _RoleLine(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admins',
          text: 'Verify companies, review jobs and manage the AI models.',
        ),
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 860) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [welcome, const SizedBox(height: 28), form]);
          }
          return Row(
            children: [
              Expanded(flex: 5, child: welcome),
              const SizedBox(width: 48),
              Expanded(flex: 4, child: form),
            ],
          );
        },
      ),
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

/// Error message box inside a form.
class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.text, this.isError = true});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final color = isError ? t.danger : t.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: t.text))),
        ],
      ),
    );
  }
}

/// Button content that shows a small spinner while busy.
class BusyLabel extends StatelessWidget {
  const BusyLabel({super.key, required this.busy, required this.label});

  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(label);
    return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
  }
}

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Enter a valid email address.';
  return null;
}
