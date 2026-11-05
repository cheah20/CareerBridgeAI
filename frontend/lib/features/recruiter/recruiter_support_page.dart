import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

const _categories = [
  'Bug or technical problem',
  'Company verification',
  'Job post approval',
  'Account',
  'Feature request',
];
const _severities = ['Low', 'Medium', 'High', 'Critical'];

// report a problem or ask the admin, and see earlier reports
class RecruiterSupportPage extends StatefulWidget {
  const RecruiterSupportPage({super.key, this.store});

  final RecruiterSample? store;

  @override
  State<RecruiterSupportPage> createState() => _RecruiterSupportPageState();
}

class _RecruiterSupportPageState extends State<RecruiterSupportPage> {
  RecruiterSample get _s => widget.store ?? recruiterSample;

  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = _categories.first;
  String _severity = _severities[1];
  String? _file;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Fill this in.' : null;

  Future<void> _attach() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
    );
    if (picked != null) setState(() => _file = picked.name);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ticket = _s.addTicket(_subject.text.trim());
    _form.currentState!.reset();
    _subject.clear();
    _message.clear();
    setState(() => _file = null);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report sent'),
        content: Text('Your reference is ${ticket.ref}. The Admin replies here, under Earlier reports.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          kicker: 'Recruiter',
          title: 'Help and bug report',
          subtitle: 'Report a problem, a match score that looks wrong, or ask the Admin a question.',
          trailing: GlassChip(label: 'Sample data'),
        ),
        const SizedBox(height: Gaps.section),
        TwoPane(
          main: GlassCard(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CardHeader(title: 'New report'),
                  TextFormField(
                    key: const Key('report-subject'),
                    controller: _subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      hintText: 'For example: Match score looks wrong for one applicant',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  FieldPair(
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category *'),
                      items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => _category = v!,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _severity,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'How serious *'),
                      items: [for (final s in _severities) DropdownMenuItem(value: s, child: Text(s))],
                      onChanged: (v) => _severity = v!,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('report-message'),
                    controller: _message,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'What happened *',
                      hintText: 'The steps you took and what you expected to see',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Screenshot or file (optional, PNG, JPG or PDF)'),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _attach,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Attach file'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_file ?? 'No file attached', style: TextStyle(fontSize: 14, color: t.textSub)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(onPressed: _submit, child: const Text('Send to Admin')),
                  ),
                ],
              ),
            ),
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'When to expect a reply'),
                    Text(
                      'High and critical reports: within 4 working hours.\nOther reports and verification: within 1 to 2 working days, Monday to Friday, 9 am to 6 pm.',
                      style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.block),
              ListenableBuilder(
                listenable: _s,
                builder: (context, _) => GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CardHeader(title: 'Earlier reports'),
                      for (final ticket in _s.tickets)
                        TableLine(
                          flex: const [4, 2],
                          cells: [
                            TwoLines(ticket.subject, '${ticket.ref}, ${shortDate(ticket.date)}'),
                            GlassChip(label: ticket.status, color: ticket.status == 'Resolved' ? t.success : t.warning),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
