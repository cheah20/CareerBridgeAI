import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

// post a job, or edit one when jobId is set
class JobFormPage extends StatefulWidget {
  const JobFormPage({super.key, this.jobId, this.store});

  final int? jobId;
  final RecruiterSample? store;

  @override
  State<JobFormPage> createState() => _JobFormPageState();
}

class _JobFormPageState extends State<JobFormPage> {
  RecruiterSample get _s => widget.store ?? recruiterSample;
  late final Job? _job = widget.jobId == null ? null : _s.job(widget.jobId!);

  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: _job?.title);
  late final _description = TextEditingController(text: _job?.description);
  late final _skills = TextEditingController(text: _job?.skills.join(', '));
  late final _location = TextEditingController(text: _job?.location);
  late final _vacancies = TextEditingController(text: '${_job?.vacancies ?? 1}');
  late final _salary = TextEditingController(text: _job?.salary);
  late String _experience = _job?.experience ?? experienceLevels.first;
  late String _education = _job?.education ?? educationLevels[1];
  late String _workMode = _job?.workMode ?? workModes.first;
  late String _workType = _job?.workType ?? workTypes.first;
  late DateTime? _closing = _job?.closing;

  // drafts need only a title
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _skills, _location, _vacancies, _salary]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => _submitting && (v ?? '').trim().isEmpty ? 'Fill this in before submitting.' : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _closing ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _closing = picked);
  }

  void _save({required bool submit}) {
    setState(() => _submitting = submit);
    if (_title.text.trim().isEmpty) {
      _form.currentState!.validate();
      showDone(context, 'Enter a job title first.');
      return;
    }
    if (submit && (!_form.currentState!.validate() || _closing == null)) {
      showDone(
        context,
        _closing == null ? 'Choose a closing date before submitting.' : 'Fill in the fields marked in red.',
      );
      return;
    }
    final status = submit ? JobStatus.review : JobStatus.draft;
    final skills = _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final job =
        _job ??
        Job(
          id: 0,
          title: '',
          description: '',
          skills: const [],
          experience: '',
          education: '',
          workMode: '',
          workType: '',
          location: '',
          vacancies: 1,
          salary: '',
          closing: null,
          status: status,
        );
    job
      ..title = _title.text.trim()
      ..description = _description.text.trim()
      ..skills = skills
      ..experience = _experience
      ..education = _education
      ..workMode = _workMode
      ..workType = _workType
      ..location = _location.text.trim()
      ..vacancies = int.tryParse(_vacancies.text) ?? 1
      ..salary = _salary.text.trim()
      ..closing = _closing
      ..status = status;
    if (_job == null) {
      _s.addJob(job);
    } else {
      _s.changed();
    }
    showDone(context, submit ? '"${job.title}" was sent to the Admin for review.' : 'Draft saved.');
    context.go('/recruiter/jobs');
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) =>
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: options.contains(value) ? value : options.first,
        decoration: InputDecoration(labelText: label),
        items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
        onChanged: (v) => setState(() => onChanged(v!)),
      );

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    if (widget.jobId != null && _job == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackLink(label: 'Back to job postings', path: '/recruiter/jobs'),
          const SizedBox(height: 12),
          const PageHeader(
            kicker: 'Recruiter',
            title: 'Job not found',
            subtitle: 'It may have been deleted. Go back to your job postings.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BackLink(label: 'Back to job postings', path: '/recruiter/jobs'),
        const SizedBox(height: 8),
        PageHeader(
          kicker: 'Recruiter',
          title: _job == null ? 'Post a job' : 'Edit job',
          subtitle: 'The required skills are what the AI compares with each applicant\'s resume.',
          trailing: const GlassChip(label: 'Sample data'),
        ),
        const SizedBox(height: Gaps.section),
        GlassCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('job-title'),
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Job title *',
                    hintText: 'For example: Junior Data Analyst',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a job title.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('job-description'),
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Job description *',
                    hintText: 'Main duties and what a normal week looks like',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('job-skills'),
                  controller: _skills,
                  decoration: const InputDecoration(
                    labelText: 'Required skills *',
                    hintText: 'Separate with commas, for example: SQL, Excel, Power BI',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                FieldPair(
                  _dropdown('Experience *', _experience, experienceLevels, (v) => _experience = v),
                  _dropdown('Education *', _education, educationLevels, (v) => _education = v),
                ),
                const SizedBox(height: 16),
                FieldPair(
                  _dropdown('Work mode *', _workMode, workModes, (v) => _workMode = v),
                  _dropdown('Work type *', _workType, workTypes, (v) => _workType = v),
                ),
                const SizedBox(height: 16),
                FieldPair(
                  TextFormField(
                    key: const Key('job-location'),
                    controller: _location,
                    decoration: const InputDecoration(labelText: 'Location *', hintText: 'For example: Melaka'),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _vacancies,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Number of openings'),
                  ),
                ),
                const SizedBox(height: 16),
                FieldPair(
                  TextFormField(
                    controller: _salary,
                    decoration: const InputDecoration(
                      labelText: 'Monthly salary range (RM)',
                      hintText: 'For example: 3,000 – 4,000',
                    ),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Closing date *',
                        suffixIcon: const Icon(Icons.event_outlined),
                        errorText: _submitting && _closing == null ? 'Choose a date before submitting.' : null,
                      ),
                      child: Text(
                        _closing == null ? 'Choose a date' : shortDate(_closing!),
                        style: TextStyle(fontSize: 16, color: t.text),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: t.row, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: t.textSub),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Submitting sends the job to the Admin for review. Job seekers see it once it is approved.',
                          style: TextStyle(fontSize: 15, color: t.textSub),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    FilledButton(onPressed: () => _save(submit: true), child: const Text('Submit for review')),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () => _save(submit: false), child: const Text('Save as draft')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
