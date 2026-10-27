import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'public_frame.dart';

/// Guests can browse published jobs; applying requires an account.
class PublicJobsPage extends StatelessWidget {
  const PublicJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const PageHeader(
            kicker: 'Open jobs',
            title: 'Browse jobs',
            subtitle: 'Log in to see your match for each job and to apply.',
            trailing: GlassChip(label: 'Sample listings'),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(title: 'Latest jobs', trailing: 'Newest first'),
                const GlassListRow(initials: 'PD', title: 'Junior Data Analyst', subtitle: 'Kuala Lumpur, Hybrid, RM 4,500–5,500'),
                const GlassListRow(initials: 'MT', title: 'Graduate Software Engineer', subtitle: 'Melaka, On-site, RM 4,000–5,000'),
                const GlassListRow(initials: 'IN', title: 'AI Engineering Intern', subtitle: 'Penang, Internship, RM 1,500'),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => context.go('/login'), child: const Text('Log in to apply')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
