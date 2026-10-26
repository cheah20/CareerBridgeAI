import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';

/// "Your details" tab: what was read from the resume, which the Job Seeker can fix.
/// Saving sends the details back and the score is worked out again.
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.profile,
    required this.onSave,
    this.editedAt,
  });

  /// The resume profile from the entry (null when the AI could not read it).
  final Map<String, dynamic>? profile;

  /// Saves the details; returns an error message, or null when it worked.
  final Future<String?> Function(Map<String, dynamic> profile) onSave;

  /// When the details were last corrected, if ever.
  final String? editedAt;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

const jobTypes = [
  'full-time',
  'part-time',
  'internship',
  'freelance',
  'contract',
  'unknown',
];
const educationLevels = [
  'SPM',
  'STPM',
  'Certificate',
  'Diploma',
  'Bachelor',
  'Master',
  'PhD',
  'Professional',
  'Other',
];

final _date = RegExp(r'^((19|20)\d{2}(-(0?[1-9]|1[0-2]))?|present)$');

class _Job {
  _Job(Map j)
    : title = TextEditingController(text: '${j['title'] ?? ''}'),
      organisation = TextEditingController(text: '${j['organisation'] ?? ''}'),
      start = TextEditingController(text: '${j['start'] ?? ''}'),
      end = TextEditingController(text: '${j['end'] ?? ''}'),
      type = jobTypes.contains(j['type']) ? j['type'] as String : 'unknown',
      highlights = [
        for (final h in (j['highlights'] as List? ?? const [])) '$h',
      ];

  final TextEditingController title, organisation, start, end;
  String type;
  final List<String> highlights; // kept as read, not edited here

  void dispose() {
    for (final c in [title, organisation, start, end]) {
      c.dispose();
    }
  }
}

class _School {
  _School(Map e)
    : level = educationLevels.contains(e['level'])
          ? e['level'] as String
          : 'Other',
      field = TextEditingController(text: '${e['field'] ?? ''}'),
      institution = TextEditingController(text: '${e['institution'] ?? ''}'),
      year = TextEditingController(text: '${e['end_year'] ?? ''}');

  String level;
  final TextEditingController field, institution, year;

  void dispose() {
    for (final c in [field, institution, year]) {
      c.dispose();
    }
  }
}

class _ProfileEditorState extends State<ProfileEditor> {
  late TextEditingController _headline;
  final Map<String, List<String>> _tags = {};
  final List<_Job> _jobs = [];
  final List<_School> _schools = [];
  bool _saving = false;
  bool _changed = false;
  String? _error;
  String? _done;

  static const _tagLists = {
    'skills': 'Skills',
    'soft_skills': 'Soft skills',
    'certifications': 'Certifications',
    'languages': 'Languages',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileEditor old) {
    super.didUpdateWidget(old);
    if (!identical(old.profile, widget.profile)) {
      _clear();
      _load();
    }
  }

  void _load() {
    final p = widget.profile ?? const {};
    _headline = TextEditingController(text: '${p['headline'] ?? ''}');
    for (final key in _tagLists.keys) {
      _tags[key] = [for (final x in (p[key] as List? ?? const [])) '$x'];
    }
    _jobs.addAll([
      for (final j in (p['experience'] as List? ?? const [])) _Job(j as Map),
    ]);
    _schools.addAll([
      for (final e in (p['education'] as List? ?? const [])) _School(e as Map),
    ]);
    _changed = false;
  }

  // Text boxes still hold their controllers until the next frame, so free them after it.
  void _later(VoidCallback free) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => free());

  void _clear({bool now = false}) {
    final old = (_headline, [..._jobs], [..._schools]);
    void free() {
      old.$1.dispose();
      for (final j in old.$2) {
        j.dispose();
      }
      for (final s in old.$3) {
        s.dispose();
      }
    }

    now ? free() : _later(free);
    _jobs.clear();
    _schools.clear();
  }

  @override
  void dispose() {
    _clear(now: true);
    super.dispose();
  }

  void _edit(VoidCallback change) => setState(() {
    change();
    _changed = true;
    _done = null;
  });

  /// Checks the form; returns the first problem in plain words, or null.
  String? _problem() {
    for (final j in _jobs) {
      if (j.title.text.trim().isEmpty) return 'Each job needs a job title.';
      for (final d in [j.start.text.trim(), j.end.text.trim()]) {
        if (d.isNotEmpty && !_date.hasMatch(d)) {
          return 'Write dates like 2023-01 or 2023, or "present" for a current job.';
        }
      }
    }
    for (final s in _schools) {
      final y = s.year.text.trim();
      if (y.isNotEmpty &&
          (int.tryParse(y) == null ||
              int.parse(y) < 1950 ||
              int.parse(y) > 2100)) {
        return 'Write the year you finished as four digits, e.g. 2022.';
      }
    }
    return null;
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Map<String, dynamic> _collect() => {
    'headline': _text(_headline),
    for (final key in _tagLists.keys) key: _tags[key],
    'experience': [
      for (final j in _jobs)
        {
          'title': j.title.text.trim(),
          'organisation': _text(j.organisation),
          'start': _text(j.start),
          'end': _text(j.end)?.toLowerCase() == 'present'
              ? 'present'
              : _text(j.end),
          'type': j.type,
          'highlights': j.highlights,
        },
    ],
    'education': [
      for (final s in _schools)
        {
          'level': s.level,
          'field': _text(s.field),
          'institution': _text(s.institution),
          'end_year': int.tryParse(s.year.text.trim()),
        },
    ],
  };

  Future<void> _save() async {
    final problem = _problem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _done = null;
    });
    final error = await widget.onSave(_collect());
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      if (error == null) {
        _changed = false;
        _done = 'Saved. Your score has been updated.';
      }
    });
  }

  void _undo() => setState(() {
    _clear();
    _load();
    _error = null;
    _done = null;
  });

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _title(t, 'Check your details'),
              const SizedBox(height: 8),
              Text(
                widget.profile == null
                    ? 'We could not read the details from this file automatically. You can type them in here, then save to get a full score.'
                    : 'This is what we read from your resume. If anything is missing or wrong, fix it here and save. Your score updates straight away.',
                style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub),
              ),
              if (widget.editedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'You last corrected these details on ${widget.editedAt!.replaceFirst('T', ' ').substring(0, 16)}.',
                  style: TextStyle(fontSize: 13, color: t.textFaint),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                key: const Key('edit-headline'),
                controller: _headline,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Current or target job title',
                  counterText: '',
                ),
                onChanged: (_) => _edit(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in _tagLists.entries) ...[
                _TagEditor(
                  id: e.key,
                  label: e.value,
                  items: _tags[e.key]!,
                  onAdd: (v) => _edit(() {
                    if (!_tags[e.key]!.any(
                      (x) => x.toLowerCase() == v.toLowerCase(),
                    )) {
                      _tags[e.key]!.add(v);
                    }
                  }),
                  onRemove: (v) => _edit(() => _tags[e.key]!.remove(v)),
                ),
                if (e.key != _tagLists.keys.last) const SizedBox(height: 18),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _title(t, 'Experience'),
              const SizedBox(height: 4),
              Text(
                'Dates like 2023-01 or 2023. Write "present" for a job you still have.',
                style: TextStyle(fontSize: 13, color: t.textSub),
              ),
              for (final (i, j) in _jobs.indexed) _jobRow(t, i, j),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('add-job'),
                  onPressed: () =>
                      _edit(() => _jobs.add(_Job(const {'type': 'full-time'}))),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a job'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _title(t, 'Education'),
              for (final (i, s) in _schools.indexed) _schoolRow(t, i, s),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('add-school'),
                  onPressed: () => _edit(
                    () => _schools.add(_School(const {'level': 'Bachelor'})),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add education'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              key: const Key('save-profile'),
              onPressed: _saving || !_changed ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save and update score'),
            ),
            TextButton(
              onPressed: _saving || !_changed ? null : _undo,
              child: const Text('Undo changes'),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(fontSize: 14, color: t.danger)),
            if (_done != null)
              Text(_done!, style: TextStyle(fontSize: 14, color: t.success)),
          ],
        ),
      ],
    );
  }

  Widget _title(GlassTokens t, String text) => Text(
    text,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: t.text),
  );

  Widget _jobRow(GlassTokens t, int i, _Job j) {
    final rowKey = ObjectKey(j);
    Widget field(
      String key,
      String label,
      TextEditingController c, {
      int flex = 3,
    }) => Expanded(
      flex: flex,
      child: TextField(
        key: Key('job-$i-$key'),
        controller: c,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _edit(() {}),
      ),
    );
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          field('title', 'Job title', j.title, flex: 4),
          const SizedBox(width: 10),
          field('org', 'Company', j.organisation, flex: 4),
          const SizedBox(width: 10),
          field('start', 'From', j.start, flex: 2),
          const SizedBox(width: 10),
          field('end', 'To', j.end, flex: 2),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              key: Key('job-$i-type'),
              initialValue: j.type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final x in jobTypes)
                  DropdownMenuItem(value: x, child: Text(x)),
              ],
              onChanged: (v) => _edit(() => j.type = v ?? j.type),
            ),
          ),
          IconButton(
            key: Key('remove-job-$i'),
            tooltip: 'Remove this job',
            onPressed: () => _edit(() => _later(_jobs.removeAt(i).dispose)),
            icon: Icon(Icons.close, color: t.textSub),
          ),
        ],
      ),
    );
  }

  Widget _schoolRow(GlassTokens t, int i, _School s) {
    final rowKey = ObjectKey(s);
    Widget field(
      String key,
      String label,
      TextEditingController c, {
      int flex = 3,
    }) => Expanded(
      flex: flex,
      child: TextField(
        key: Key('school-$i-$key'),
        controller: c,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _edit(() {}),
      ),
    );
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              key: Key('school-$i-level'),
              initialValue: s.level,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Level'),
              items: [
                for (final x in educationLevels)
                  DropdownMenuItem(value: x, child: Text(x)),
              ],
              onChanged: (v) => _edit(() => s.level = v ?? s.level),
            ),
          ),
          const SizedBox(width: 10),
          field('field', 'Subject', s.field, flex: 4),
          const SizedBox(width: 10),
          field('institution', 'School or university', s.institution, flex: 4),
          const SizedBox(width: 10),
          field('year', 'Year finished', s.year, flex: 2),
          IconButton(
            key: Key('remove-school-$i'),
            tooltip: 'Remove',
            onPressed: () => _edit(() => _later(_schools.removeAt(i).dispose)),
            icon: Icon(Icons.close, color: t.textSub),
          ),
        ],
      ),
    );
  }
}

/// A list of short items (skills, languages…) shown as chips, with a box to add more.
class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.id,
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String id;
  final String label;
  final List<String> items;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final v = _input.text.trim();
    if (v.isEmpty || v.length > 80) return;
    widget.onAdd(v);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.label} (${widget.items.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: t.text,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.items.isEmpty)
          Text('None yet.', style: TextStyle(fontSize: 14, color: t.textSub)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in widget.items)
              InputChip(
                key: Key('tag-${widget.id}-$item'),
                label: Text(item),
                onDeleted: () => widget.onRemove(item),
                deleteButtonTooltipMessage: 'Remove',
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                key: Key('add-${widget.id}'),
                controller: _input,
                maxLength: 80,
                decoration: InputDecoration(
                  hintText:
                      'Add ${widget.label.toLowerCase()}, then press Enter',
                  counterText: '',
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: _add, child: const Text('Add')),
          ],
        ),
      ],
    );
  }
}
