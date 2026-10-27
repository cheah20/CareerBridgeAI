import 'package:flutter/material.dart';

import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import '../shell/server_status.dart';

/// Admin dashboard with sample data (real data arrives in Phases 5–6).
class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: 'System overview',
          title: 'Everything running smoothly',
          subtitle: 'Pending reviews, the current AI model, errors and API usage in one place.',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [ServerStatusChip(), GlassChip(label: 'Sample data')]),
        ),
        SizedBox(height: Gaps.section),
        StatStrip(items: [
          StatItem('Users', '128', '96 seekers, 30 recruiters'),
          StatItem('Pending companies', '3', 'Oldest: 2 days'),
          StatItem('Pending jobs', '5', 'New postings'),
          StatItem('API budget used', '12%', 'This month'),
        ]),
        SizedBox(height: Gaps.block),
        TwoPane(
          main: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(title: 'Waiting for review', trailing: 'Oldest first'),
                GlassListRow(initials: 'CX', title: 'Company X Sdn Bhd', subtitle: 'Company verification, 2 days ago', selected: true),
                GlassListRow(initials: 'DE', title: 'Data Engineer (Contract)', subtitle: 'New job posting, Company X'),
                GlassListRow(initials: 'MT', title: 'Melaka Tech Solutions', subtitle: 'Company re-review, details changed'),
              ],
            ),
          ),
          side: FocusCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI model', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 12),
                FocusEntry(title: 'No model deployed yet', subtitle: 'Training and evaluation arrive in Phase 3'),
                FocusEntry(title: 'Errors today: 0', subtitle: 'Alerts and monitoring arrive in Phase 6', isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
