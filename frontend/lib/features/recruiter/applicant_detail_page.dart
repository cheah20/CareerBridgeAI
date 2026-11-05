import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

// one applicant: resume, ai match and status history
class ApplicantDetailPage extends StatelessWidget {
  const ApplicantDetailPage({super.key, required this.applicantId, this.store});

  final int applicantId;
  final RecruiterSample? store;

  @override
  Widget build(BuildContext context) {
    final s = store ?? recruiterSample;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final a = s.applicant(applicantId);
        if (a == null) return const MissingApplicant();
        final job = s.job(a.jobId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackLink(label: 'Back to applicants', path: '/recruiter/applicants?job=${a.jobId}'),
            const SizedBox(height: 8),
            PageHeader(
              kicker: 'Applied for ${job?.title ?? 'a closed job'} on ${shortDate(a.history.first.date)}',
              title: a.name,
              trailing: const GlassChip(label: 'Sample data'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.go('/recruiter/applicants/${a.id}/manage'),
                icon: const Icon(Icons.event_outlined, size: 18),
                label: const Text('Update status or set interview'),
              ),
            ),
            const SizedBox(height: Gaps.block),
            TwoPane(
              main: _ResumeCard(applicant: a),
              side: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MatchCard(applicant: a, rank: s.rankOf(a), of: s.applicantsFor(a.jobId).length),
                  const SizedBox(height: Gaps.block),
                  _HistoryCard(applicant: a),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Submitted resume', style: Theme.of(context).textTheme.titleMedium)),
              GlassChip(label: 'Shared with you', color: t.success),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.row,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.cardEdge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.name.toUpperCase(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.text),
                ),
                for (final section in applicant.resume) ...[
                  const SizedBox(height: 16),
                  Text(
                    section.heading,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                  ),
                  const SizedBox(height: 4),
                  for (final line in section.lines)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(line, style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub)),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                showDone(context, 'The original file opens from private storage once uploads are connected.'),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download original file'),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.applicant, required this.rank, required this.of});

  final Applicant applicant;
  final int rank;
  final int of;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final a = applicant;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'AI match'),
          Row(
            children: [
              Text(
                '${a.match}%',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: a.level.color(t)),
              ),
              const SizedBox(width: 14),
              Expanded(child: TwoLines('${a.level.label} match', 'Ranked $rank of $of applicants')),
            ],
          ),
          const SizedBox(height: 12),
          Text(a.summary, style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub)),
          Divider(height: 28, color: t.cardEdge),
          FieldLabel('Matching skills (${a.matched.length})'),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final s in a.matched) SkillTag(s, have: true)]),
          if (a.missing.isNotEmpty) ...[
            const SizedBox(height: 16),
            FieldLabel('Missing skills (${a.missing.length})'),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final s in a.missing) SkillTag(s, have: false)]),
            const SizedBox(height: 8),
            Text('You can check these in the interview.', style: TextStyle(fontSize: 14, color: t.textSub)),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    const flex = [3, 3, 3];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(title: 'Status history'),
          const TableHead(labels: ['Date', 'Status', 'Changed by'], flex: flex),
          for (final h in applicant.history.reversed)
            TableLine(
              flex: flex,
              cells: [
                Text(shortDate(h.date), style: TextStyle(fontSize: 15, color: t.text)),
                Text(
                  h.status,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                ),
                Text(h.by, style: TextStyle(fontSize: 15, color: t.textSub)),
              ],
            ),
        ],
      ),
    );
  }
}

// shown when the link points to an applicant that does not exist
class MissingApplicant extends StatelessWidget {
  const MissingApplicant({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackLink(label: 'Back to applicants', path: '/recruiter/applicants'),
        SizedBox(height: 12),
        PageHeader(
          kicker: 'Recruiter',
          title: 'Applicant not found',
          subtitle: 'Go back to the applicant list and choose someone else.',
        ),
      ],
    );
  }
}
