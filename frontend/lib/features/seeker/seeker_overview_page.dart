import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import '../shell/server_status.dart';

/// Job Seeker home.
class SeekerOverviewPage extends StatelessWidget {
  const SeekerOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          kicker: 'Resume v3 analysed',
          title: 'Your career this week',
          subtitle: 'Your best direction is Data Analyst. Two new jobs match above 80%, '
              'and adding Power BI would lift your top match by about 6 points.',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [ServerStatusChip(), GlassChip(label: 'Sample data')]),
        ),
        const SizedBox(height: Gaps.section),
        const StatStrip(items: [
          StatItem('Resume match', '84%', 'Strong Match'),
          StatItem('New matches', '12', '+4 since Monday'),
          StatItem('Applications', '5', '2 under review'),
          StatItem('Skills to build', '3', 'Power BI first'),
        ]),
        const SizedBox(height: Gaps.block),
        TwoPane(
          main: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(title: 'Top job matches', trailing: 'Sorted by match'),
                const GlassListRow(
                  initials: 'PD',
                  title: 'Junior Data Analyst',
                  subtitle: 'Kuala Lumpur, Hybrid, RM 4,500–5,500',
                  value: '84%', progress: 0.84,
                  valueCaption: 'Strong',
                  selected: true,
                ),
                const GlassListRow(
                  initials: 'MT',
                  title: 'Graduate Software Engineer',
                  subtitle: 'Melaka, On-site, RM 4,000–5,000',
                  value: '78%', progress: 0.78,
                  valueCaption: 'Good',
                ),
                const GlassListRow(
                  initials: 'IN',
                  title: 'AI Engineering Intern',
                  subtitle: 'Penang, Internship, RM 1,500',
                  value: '71%', progress: 0.71,
                  valueCaption: 'Good',
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () {}, child: const Text('View match details')),
                ),
              ],
            ),
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FocusCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upcoming interview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    FocusEntry(title: 'Junior Data Analyst, Round 1', subtitle: 'Mon, 20 Oct, 10:00–10:45, Online'),
                    FocusEntry(title: 'Prepare: 8 practice questions', subtitle: 'Generated from the job description', isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.block),
              GlassCard(
                child: Column(
                  children: [
                    const CardHeader(title: 'Skill gaps', trailing: 'vs. top match'),
                    LevelBar(label: 'SQL', value: 0.85, color: t.success, caption: 'Good'),
                    LevelBar(label: 'Power BI', value: 0.35, color: t.warning, caption: 'Weak'),
                    LevelBar(label: 'Docker', value: 0.1, color: t.danger, caption: 'Missing'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
