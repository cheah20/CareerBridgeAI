import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'applicant_detail_page.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

// change an applicant's status, or set an interview
class ApplicantManagePage extends StatefulWidget {
  const ApplicantManagePage({super.key, required this.applicantId, this.store});

  final int applicantId;
  final RecruiterSample? store;

  @override
  State<ApplicantManagePage> createState() => _ApplicantManagePageState();
}

class _ApplicantManagePageState extends State<ApplicantManagePage> {
  RecruiterSample get _s => widget.store ?? recruiterSample;
  late final Applicant? _a = _s.applicant(widget.applicantId);

  late AppStatus _status = _a?.status ?? AppStatus.applied;
  late DateTime? _date = _a?.interview?.when;
  late TimeOfDay? _time = _a?.interview == null ? null : TimeOfDay.fromDateTime(_a!.interview!.when);
  late final _place = TextEditingController(text: _a?.interview?.place);
  late final _notes = TextEditingController(text: _a?.interview?.notes);
  bool _tried = false;

  @override
  void dispose() {
    _place.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _updateStatus() {
    final a = _a!;
    if (_status == a.status) {
      showDone(context, 'Status is already ${a.status.label}.');
      return;
    }
    _s.setStatus(a, _status);
    showDone(context, 'Status changed to ${_status.label}.');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 3)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0));
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _schedule() async {
    setState(() => _tried = true);
    if (_date == null || _time == null || _place.text.trim().isEmpty) {
      showDone(context, 'Choose a date, a time and a place first.');
      return;
    }
    final a = _a!;
    final when = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    _s.schedule(a, Interview(when, _place.text.trim(), _notes.text.trim()));
    setState(() => _status = AppStatus.interview);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Interview set'),
        content: Text(
          '${a.name}: ${shortDate(when)} at ${clock(when)}, ${_place.text.trim()}.\n\n'
          'Their status is now Interview. Email invitations start once email is set up.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  Widget _picker(String label, String? value, IconData icon, VoidCallback onTap) {
    final t = GlassTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
          errorText: _tried && value == null ? 'Choose one.' : null,
        ),
        child: Text(value ?? 'Choose', style: TextStyle(fontSize: 16, color: t.text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final a = _a;
    if (a == null) return const MissingApplicant();
    final job = _s.job(a.jobId);
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BackLink(label: 'Back to ${a.name}', path: '/recruiter/applicants/${a.id}'),
          const SizedBox(height: 8),
          PageHeader(
            kicker: 'Applied for ${job?.title ?? 'a closed job'}',
            title: 'Manage ${a.name}',
            trailing: GlassChip(label: 'Now: ${a.status.label}', color: a.status.color(t)),
          ),
          const SizedBox(height: Gaps.section),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardHeader(title: 'Change status'),
                Text(
                  'Move the applicant to another stage without setting an interview.',
                  style: TextStyle(fontSize: 15, color: t.textSub),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<AppStatus>(
                    isExpanded: true,
                    key: ValueKey(_status),
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [for (final s in AppStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _updateStatus, child: const Text('Update status')),
              ],
            ),
          ),
          const SizedBox(height: Gaps.block),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(title: 'Set an interview'),
                FieldPair(
                  _picker('Date *', _date == null ? null : shortDate(_date!), Icons.event_outlined, _pickDate),
                  _picker('Time (Malaysia) *', _time?.format(context), Icons.schedule_outlined, _pickTime),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('interview-place'),
                  controller: _place,
                  decoration: InputDecoration(
                    labelText: 'Place or meeting link *',
                    hintText: 'For example: Room 2B, or a Google Meet link',
                    errorText: _tried && _place.text.trim().isEmpty ? 'Enter a place or link.' : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Notes for the applicant (optional)'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: t.row, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Setting an interview changes the status to Interview.',
                    style: TextStyle(fontSize: 15, color: t.textSub),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    FilledButton(onPressed: _schedule, child: const Text('Set interview')),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/recruiter/applicants/${a.id}'),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
