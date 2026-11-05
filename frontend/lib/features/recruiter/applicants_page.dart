import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

const _flex = [2, 4, 4, 2, 3];
const _educations = ["Bachelor's degree", 'Diploma', "Master's degree"];
const _experiences = ['Fresh graduate', '1–2 years', '3+ years'];

// applicants for one job, highest match first, with filters
class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key, this.jobId, this.store});

  final int? jobId;
  final RecruiterSample? store;

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  RecruiterSample get _s => widget.store ?? recruiterSample;

  late int? _jobId = widget.jobId ?? _s.jobs.where((j) => _s.applicantsFor(j.id).isNotEmpty).firstOrNull?.id;
  AppStatus? _status;
  MatchLevel? _level;
  String? _education;
  String? _experience;
  final _skill = TextEditingController();

  @override
  void dispose() {
    _skill.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _status = _level = null;
    _education = _experience = null;
    _skill.clear();
  });

  List<Applicant> _shown() {
    final skill = _skill.text.trim().toLowerCase();
    return _s
        .applicantsFor(_jobId ?? -1)
        .where((a) => _status == null || a.status == _status)
        .where((a) => _level == null || a.level == _level)
        .where((a) => _education == null || a.educationLevel == _education)
        .where((a) => _experience == null || a.experienceLevel == _experience)
        .where((a) => skill.isEmpty || a.skills.toLowerCase().contains(skill))
        .toList();
  }

  Widget _filter<T>(
    String label,
    T? value,
    String all,
    List<T> options,
    String Function(T) name,
    ValueChanged<T?> onChanged,
  ) => SizedBox(
    width: 200,
    child: DropdownButtonFormField<T?>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: null, child: Text(all)),
        for (final o in options) DropdownMenuItem(value: o, child: Text(name(o))),
      ],
      onChanged: (v) => setState(() => onChanged(v)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final job = _jobId == null ? null : _s.job(_jobId!);
        final shown = _shown();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackLink(label: 'Back to job postings', path: '/recruiter/jobs'),
            const SizedBox(height: 8),
            PageHeader(
              kicker: 'Recruiter',
              title: job == null ? 'Applicants' : 'Applicants: ${job.title}',
              subtitle: 'Sorted by AI match. The match supports your review; you make the hiring decision.',
              trailing: const GlassChip(label: 'Sample data'),
            ),
            const SizedBox(height: Gaps.section),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 420,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      key: ValueKey(_jobId),
                      initialValue: _jobId,
                      decoration: const InputDecoration(labelText: 'Job'),
                      items: [for (final j in _s.jobs) DropdownMenuItem(value: j.id, child: Text(j.title))],
                      onChanged: (v) => setState(() => _jobId = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _filter('Status', _status, 'All statuses', AppStatus.values, (s) => s.label, (v) => _status = v),
                      _filter(
                        'Match',
                        _level,
                        'All matches',
                        MatchLevel.values,
                        (l) => switch (l) {
                          MatchLevel.strong => '80% and above',
                          MatchLevel.moderate => '60% to 79%',
                          MatchLevel.low => 'Below 60%',
                        },
                        (v) => _level = v,
                      ),
                      _filter('Education', _education, 'All levels', _educations, (e) => e, (v) => _education = v),
                      _filter(
                        'Experience',
                        _experience,
                        'All experience',
                        _experiences,
                        (e) => e,
                        (v) => _experience = v,
                      ),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          key: const Key('skill-filter'),
                          controller: _skill,
                          decoration: const InputDecoration(labelText: 'Skill', hintText: 'For example: Flutter'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      TextButton(onPressed: _reset, child: const Text('Reset filters')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gaps.block),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CardHeader(
                    title: '${shown.length} applicant${shown.length == 1 ? '' : 's'}',
                    trailing: 'Highest match first',
                  ),
                  const TableHead(
                    labels: ['Match', 'Applicant', 'Education and background', 'Status', 'Actions'],
                    flex: _flex,
                  ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No applicants match these filters. Reset the filters or choose another job.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: t.textSub),
                      ),
                    ),
                  for (final a in shown) _ApplicantRow(applicant: a, store: _s),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  const _ApplicantRow({required this.applicant, required this.store});

  final Applicant applicant;
  final RecruiterSample store;

  Future<void> _reject(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${applicant.name}?'),
        content: const Text('Their application status changes to Rejected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      store.setStatus(applicant, AppStatus.rejected);
      showDone(context, '${applicant.name} is rejected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final a = applicant;
    final ended = a.status == AppStatus.rejected || a.status == AppStatus.hired;
    return TableLine(
      flex: _flex,
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${a.match}%',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: a.level.color(t)),
            ),
            Text(
              a.level.label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: a.level.color(t)),
            ),
          ],
        ),
        TwoLines(a.name, 'Skills: ${a.skills}'),
        TwoLines(a.education, a.experience),
        GlassChip(label: a.status.label, color: a.status.color(t)),
        Wrap(
          spacing: 4,
          children: [
            TextButton(onPressed: () => context.go('/recruiter/applicants/${a.id}'), child: const Text('View')),
            if (!ended && a.level == MatchLevel.low)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: t.danger),
                onPressed: () => _reject(context),
                child: const Text('Reject'),
              )
            else if (!ended)
              TextButton(
                onPressed: () => context.go('/recruiter/applicants/${a.id}/manage'),
                child: const Text('Interview'),
              ),
          ],
        ),
      ],
    );
  }
}
