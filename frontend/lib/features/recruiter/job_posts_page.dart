import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

const _flex = [5, 2, 2, 2, 3];

// company job list
class JobPostsPage extends StatelessWidget {
  const JobPostsPage({super.key, this.store});

  final RecruiterSample? store;

  @override
  Widget build(BuildContext context) {
    final s = store ?? recruiterSample;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        int count(JobStatus status) => s.jobs.where((j) => j.status == status).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              kicker: 'Recruiter',
              title: 'Job postings',
              subtitle: 'New jobs go to the Admin for review. Job seekers see a job once it is open.',
              trailing: const GlassChip(label: 'Sample data'),
            ),
            const SizedBox(height: Gaps.section),
            StatStrip(
              items: [
                StatItem('All jobs', '${s.jobs.length}', 'Including drafts'),
                StatItem('Open', '${count(JobStatus.open)}', 'Seen by job seekers'),
                StatItem('Waiting review', '${count(JobStatus.review)}', 'With the Admin'),
                StatItem('Applicants', '${s.applicants.length}', 'Across all jobs'),
              ],
            ),
            const SizedBox(height: Gaps.block),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Your jobs', style: Theme.of(context).textTheme.titleMedium)),
                      FilledButton.icon(
                        onPressed: () => context.go('/recruiter/jobs/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Post a job'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const TableHead(labels: ['Job', 'Status', 'Applicants', 'Closes', 'Actions'], flex: _flex),
                  if (s.jobs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No jobs yet. Post your first job to start receiving applicants.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final job in s.jobs) _JobRow(job: job, store: s),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.store});

  final Job job;
  final RecruiterSample store;

  Future<void> _confirm(
    BuildContext context,
    String title,
    String message,
    String action,
    String done,
    VoidCallback onYes,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      onYes();
      showDone(context, done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final applicants = store.applicantsFor(job.id).length;
    final edit = TextButton(onPressed: () => context.go('/recruiter/jobs/${job.id}/edit'), child: const Text('Edit'));
    final actions = switch (job.status) {
      JobStatus.closed => [
        TextButton(
          onPressed: () => _confirm(
            context,
            'Reopen "${job.title}"?',
            'It goes back to the Admin for review before job seekers can see it.',
            'Reopen',
            '"${job.title}" is waiting for review.',
            () => store.setJobStatus(job, JobStatus.review),
          ),
          child: const Text('Reopen'),
        ),
      ],
      JobStatus.draft => [
        edit,
        TextButton(
          style: TextButton.styleFrom(foregroundColor: t.danger),
          onPressed: () => _confirm(
            context,
            'Delete the draft "${job.title}"?',
            'The draft is removed for good.',
            'Delete',
            'Draft deleted.',
            () => store.deleteJob(job),
          ),
          child: const Text('Delete'),
        ),
      ],
      _ => [
        edit,
        TextButton(
          style: TextButton.styleFrom(foregroundColor: t.danger),
          onPressed: () => _confirm(
            context,
            'Close "${job.title}"?',
            'Job seekers can no longer apply. Applicants you already have stay in your list.',
            'Close job',
            '"${job.title}" is closed.',
            () => store.setJobStatus(job, JobStatus.closed),
          ),
          child: const Text('Close'),
        ),
      ],
    };
    final where = [job.workType, job.workMode, job.location].where((p) => p.isNotEmpty).join(', ');
    return TableLine(
      flex: _flex,
      cells: [
        TwoLines(job.title, where),
        GlassChip(label: job.status.label, color: job.status.color(t)),
        applicants == 0
            ? Text('None yet', style: TextStyle(fontSize: 15, color: t.textFaint))
            : TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 40)),
                onPressed: () => context.go('/recruiter/applicants?job=${job.id}'),
                child: Text('$applicants applicant${applicants == 1 ? '' : 's'}'),
              ),
        Text(job.closing == null ? 'Not set' : shortDate(job.closing!), style: TextStyle(fontSize: 15, color: t.text)),
        Wrap(spacing: 4, children: actions),
      ],
    );
  }
}
