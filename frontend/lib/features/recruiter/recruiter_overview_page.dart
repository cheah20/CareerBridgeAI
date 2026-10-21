import 'package:flutter/material.dart';

import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import '../shell/server_status.dart';

/// Recruiter home with sample data (real data arrives in Phases 4–5).
class RecruiterOverviewPage extends StatelessWidget {
  const RecruiterOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: 'Company X · Recruiter',
          title: 'Hiring at a glance.',
          subtitle: 'Applicants are sorted by AI match. The match is a fit indicator only — '
              'you review every candidate and make the decision.',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [ServerStatusChip(), GlassChip(label: 'Sample data')]),
        ),
        SizedBox(height: Gaps.section),
        StatStrip(items: [
          StatItem('Active jobs', '3', '1 waiting for review'),
          StatItem('New applicants', '18', 'This week'),
          StatItem('Interviews', '4', 'Next 7 days'),
          StatItem('Shortlisted', '6', 'Across all jobs'),
        ]),
        SizedBox(height: Gaps.block),
        TwoPane(
          main: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(title: 'Newest applicants', trailing: 'Sorted by match'),
                GlassListRow(initials: 'AR', title: 'Aina Rahman', subtitle: 'Junior Data Analyst · Applied today', value: '84%', progress: 0.84, valueCaption: 'Strong', selected: true),
                GlassListRow(initials: 'LW', title: 'Lim Wei Jie', subtitle: 'Junior Data Analyst · Applied yesterday', value: '76%', progress: 0.76, valueCaption: 'Good'),
                GlassListRow(initials: 'NS', title: 'Nur Sofea', subtitle: 'Graduate Software Engineer · 2 days ago', value: '69%', progress: 0.69, valueCaption: 'Fair'),
              ],
            ),
          ),
          side: FocusCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next steps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 12),
                FocusEntry(title: 'Interview · Aina Rahman', subtitle: 'Mon, 20 Oct · 10:00–10:45 · Online'),
                FocusEntry(title: 'Job waiting for Admin review', subtitle: 'Data Engineer (Contract)', isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
