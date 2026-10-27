import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import 'profile_editor.dart';
import 'testing_api.dart';

/// Result page: score banner on top, then Overview, Skills, Jobs, Details and Edit details tabs.
class AssessmentView extends ConsumerStatefulWidget {
  const AssessmentView({
    super.key,
    required this.entry,
    this.adviceLoading = false,
    this.onRequestAdvice,
    this.onEntryChanged,
  });

  final Map<String, dynamic> entry;
  final bool adviceLoading;
  final VoidCallback? onRequestAdvice;

  /// Called with the updated entry after the Job Seeker corrects their details.
  final ValueChanged<Map<String, dynamic>>? onEntryChanged;

  @override
  ConsumerState<AssessmentView> createState() => _AssessmentViewState();
}

const _levelNames = {
  'entry': 'Fresh graduate',
  'junior': 'Junior',
  'mid': 'Mid-level',
  'senior': 'Senior',
  'lead': 'Lead',
};

enum _Tab { overview, skills, jobs, details, edit }

class _AssessmentViewState extends ConsumerState<AssessmentView> {
  late String _level = widget.entry['level'] as String;
  final Set<String> _ticked = {};
  final Map<String, Map<String, dynamic>> _previews = {};
  final Set<int> _stepsDone = {};
  _Tab _tab = _Tab.overview;
  String? _selected;
  bool _previewBusy = false;
  String? _previewError;
  bool? _feedbackGiven;

  Map<String, dynamic> get _saved =>
      widget.entry['assessment'] as Map<String, dynamic>;
  String get _key => '$_level|${(_ticked.toList()..sort()).join(',')}';
  bool get _isSaved => _level == widget.entry['level'] && _ticked.isEmpty;

  /// The assessment on screen: the saved one, or a what-if preview.
  Map<String, dynamic> get _shown =>
      _isSaved ? _saved : (_previews[_key] ?? _saved);
  bool get _isPreview => !_isSaved && _previews.containsKey(_key);

  List<Map<String, dynamic>> get _skills =>
      ((_saved['skills_detail'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();

  @override
  void didUpdateWidget(covariant AssessmentView old) {
    super.didUpdateWidget(old);
    if (old.entry['id'] != widget.entry['id']) {
      _level = widget.entry['level'] as String;
      _ticked.clear();
      _previews.clear();
      _stepsDone.clear();
      _selected = null;
      _feedbackGiven = null;
      _tab = _Tab.overview;
    } else if (!identical(
      old.entry['assessment'],
      widget.entry['assessment'],
    )) {
      _previews.clear(); // details were corrected; old previews are out of date
    }
  }

  Future<String?> _saveProfile(Map<String, dynamic> profile) async {
    try {
      final entry = await ref
          .read(testingApiProvider)
          .saveProfile(widget.entry['id'] as String, profile);
      widget.onEntryChanged?.call(entry);
      ref.invalidate(logbookProvider);
      return null;
    } on TestingFailure catch (e) {
      return e.message;
    }
  }

  Future<void> _refreshPreview() async {
    if (_isSaved || _previews.containsKey(_key)) {
      setState(() {});
      return;
    }
    final key = _key;
    setState(() {
      _previewBusy = true;
      _previewError = null;
    });
    try {
      final result = await ref
          .read(testingApiProvider)
          .whatIf(
            widget.entry['id'] as String,
            level: _level,
            skills: _ticked.toList(),
          );
      if (mounted) setState(() => _previews[key] = result);
    } on TestingFailure catch (e) {
      if (mounted) setState(() => _previewError = e.message);
    } finally {
      if (mounted) setState(() => _previewBusy = false);
    }
  }

  void _setLevel(String level) {
    _level = level;
    _refreshPreview();
  }

  void _toggleSkill(String name, bool on) {
    on ? _ticked.add(name) : _ticked.remove(name);
    _selected = name;
    _refreshPreview();
  }

  Future<void> _sendFeedback(bool helpful) async {
    setState(() => _feedbackGiven = helpful);
    try {
      await ref
          .read(testingApiProvider)
          .feedback(
            widget.entry['id'] as String,
            section: 'result',
            helpful: helpful,
          );
    } on TestingFailure {
      // Feedback is a nice-to-have; the thank-you stays even if saving failed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final panel = switch (_tab) {
          _Tab.overview => _overview(wide),
          _Tab.skills => _skillsPanel(wide),
          _Tab.jobs => _jobsPanel(wide),
          _Tab.details => _detailsPanel(wide),
          _Tab.edit => ProfileEditor(
            profile: widget.entry['profile'] as Map<String, dynamic>?,
            editedAt: widget.entry['profile_edited_at'] as String?,
            onSave: _saveProfile,
          ),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _banner(wide),
            const SizedBox(height: 20),
            _tabs(),
            const SizedBox(height: 20),
            panel,
          ],
        );
      },
    );
  }

  // Banner

  Widget _banner(bool wide) {
    final t = GlassTokens.of(context);
    final a = _shown;
    final score = a['score'] as int;
    final band = _Band.of(score, t);
    final role = widget.entry['role'] as Map<String, dynamic>;
    final file = widget.entry['file'] as Map<String, dynamic>;
    final parts = (a['parts'] as Map).cast<String, dynamic>();
    final rescored = widget.entry['rescored_from'];

    final scoreText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$score',
            style: TextStyle(
              fontSize: wide ? 80 : 64,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -2,
              color: t.text,
            ),
          ),
          TextSpan(
            text: '%',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: t.textSub,
            ),
          ),
        ],
      ),
      key: const Key('result-score'),
    );
    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${role['title']}, ${role['field']}, ${file['name']}',
          style: TextStyle(fontSize: 15, color: t.textSub),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              band.headline,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: t.text,
                height: 1.25,
              ),
            ),
            _Pill(band.name, band.color),
            if (_isPreview)
              _Pill(
                'Preview ${_signed(score - (_saved['score'] as int))}',
                t.warning,
              ),
            if (_previewBusy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _verdict(a),
          style: TextStyle(fontSize: 17, height: 1.5, color: t.textSub),
        ),
        if (_previewError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _previewError!,
              style: TextStyle(fontSize: 14, color: t.danger),
            ),
          ),
      ],
    );
    final levels = _Segmented(
      options: _levelNames,
      selected: _level,
      onSelect: _setLevel,
      keyPrefix: 'level',
    );

    return GlassCard(
      padding: EdgeInsets.all(wide ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                scoreText,
                const SizedBox(width: 28),
                Expanded(child: headline),
                const SizedBox(width: 20),
                levels,
              ],
            )
          else ...[
            scoreText,
            const SizedBox(height: 12),
            headline,
            const SizedBox(height: 14),
            levels,
          ],
          if (rescored != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Re-scored with the current rules. The score saved at the time was $rescored%.',
                style: TextStyle(fontSize: 14, color: t.textSub),
              ),
            ),
          const SizedBox(height: 24),
          _StackBar(parts: parts),
          const SizedBox(height: 16),
          _Columns(
            wide: wide,
            gap: 24,
            children: [
              for (final name in const ['skills', 'experience', 'education'])
                _PartSummary(
                  name: name,
                  part: (parts[name] as Map).cast<String, dynamic>(),
                ),
            ],
          ),
          if ((a['notes'] as List? ?? const []).isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final n in a['notes'] as List)
              Text('• $n', style: TextStyle(fontSize: 14, color: t.textSub)),
          ],
          if (a['basic_mode'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Basic mode: the AI reader was unavailable, so this score uses simpler text rules.',
                style: TextStyle(fontSize: 14, color: t.warning),
              ),
            ),
          const SizedBox(height: 16),
          Divider(color: t.cardEdge),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _feedbackRow(),
              Text(
                'A guide for your next steps, not a hiring decision.',
                style: TextStyle(fontSize: 14, color: t.textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _verdict(Map<String, dynamic> a) {
    if (_isPreview && _ticked.isNotEmpty) {
      return 'Preview with the skills you ticked. Add them to your resume to make it count.';
    }
    final years = a['relevant_years'] as num?;
    final suggested = a['suggested_level'] as String?;
    final parts = (a['parts'] as Map).cast<String, dynamic>();
    final skills = (parts['skills'] as Map)['score'] as num?;
    if (suggested != null && years != null) {
      final up =
          _levelNames.keys.toList().indexOf(suggested) >
          _levelNames.keys.toList().indexOf(_level);
      return up
          ? 'Your ${years.toStringAsFixed(0)} years of related work read closer to ${_levelNames[suggested]}.'
          : 'Your related experience reads closer to ${_levelNames[suggested]} for now.';
    }
    if (skills != null && skills < 0.5) {
      return 'Adding a few of this role\'s key skills will raise your fit the most.';
    }
    return 'Your experience fits the level you chose.';
  }

  Widget _feedbackRow() {
    final t = GlassTokens.of(context);
    if (_feedbackGiven != null) {
      return Text(
        _feedbackGiven!
            ? 'Thanks, glad it looks right.'
            : 'Thanks. Your note is saved in the test logbook.',
        style: TextStyle(
          fontSize: 14,
          color: t.success,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Is this result right?',
          style: TextStyle(fontSize: 14, color: t.textSub),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          key: const Key('feedback-yes'),
          tooltip: 'Yes, this looks right',
          onPressed: () => _sendFeedback(true),
          icon: const Icon(Icons.thumb_up_outlined, size: 18),
        ),
        IconButton.outlined(
          key: const Key('feedback-no'),
          tooltip: 'No, something is wrong',
          onPressed: () => _sendFeedback(false),
          icon: const Icon(Icons.thumb_down_outlined, size: 18),
        ),
      ],
    );
  }

  // Tabs

  Widget _tabs() {
    final t = GlassTokens.of(context);
    final toAdd = _skills
        .where((s) => s['core'] == true && s['found'] == null)
        .length;
    final roles = (widget.entry['related_roles'] as List? ?? const []).length;
    final labels = <_Tab, (String, String?)>{
      _Tab.overview: ('Overview', null),
      _Tab.skills: ('Skills', toAdd > 0 ? '$toAdd to add' : null),
      _Tab.jobs: ('Jobs', roles > 0 ? '$roles roles' : null),
      _Tab.details: ('Details', null),
      if (widget.onEntryChanged != null)
        _Tab.edit: (
          'Edit details',
          widget.entry['profile_edited_at'] != null ? 'edited' : null,
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.cardEdge)),
      ),
      child: Wrap(
        children: [
          for (final e in labels.entries)
            InkWell(
              key: Key('tab-${e.key.name}'),
              onTap: () => setState(() => _tab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == e.key ? t.text : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value.$1,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _tab == e.key ? t.text : t.textSub,
                      ),
                    ),
                    if (e.value.$2 != null) ...[
                      const SizedBox(width: 6),
                      _Pill(e.value.$2!, t.textSub, filled: true),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Overview

  Widget _overview(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PairRow(wide: wide, left: _nextSteps(), right: _rolesCard(limit: 3)),
        const SizedBox(height: 20),
        _coachCard(),
      ],
    );
  }

  List<({String title, String detail})> _steps() {
    final advice = widget.entry['advice'] as Map<String, dynamic>?;
    final fromAi = (advice?['next_skills'] as List? ?? const []).cast<Map>();
    if (fromAi.isNotEmpty) {
      return [
        for (final s in fromAi.take(3))
          (title: 'Build ${s['skill']}', detail: '${s['how']}'),
      ];
    }
    final missing = _skills.where((s) => s['found'] == null).toList()
      ..sort(
        (a, b) =>
            ((b['gain'] as num?) ?? 0).compareTo((a['gain'] as num?) ?? 0),
      );
    final steps = [
      for (final s in missing.take(3))
        (
          title: 'Show ${s['name']} on your resume',
          detail:
              'If you already use it, name it in your skills and in one job line'
              '${s['gain'] != null && (s['gain'] as num) > 0 ? ' (+${s['gain']} points)' : ''}. If not, it is a good skill to learn next.',
        ),
    ];
    return steps.isEmpty
        ? [
            (
              title: 'Keep your resume up to date',
              detail: 'You already show every skill on this role\'s list.',
            ),
          ]
        : steps;
  }

  Widget _nextSteps() {
    final t = GlassTokens.of(context);
    final steps = _steps();
    final done = _stepsDone.where((i) => i < steps.length).length;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(
            title: 'Your next ${steps.length} steps',
            trailing: '$done of ${steps.length} done',
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: Key('step-$i'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(
                    () => _stepsDone.contains(i)
                        ? _stepsDone.remove(i)
                        : _stepsDone.add(i),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.cardEdge),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _stepsDone.contains(i)
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: _stepsDone.contains(i) ? t.success : t.textSub,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[i].title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _stepsDone.contains(i)
                                      ? t.textSub
                                      : t.text,
                                  decoration: _stepsDone.contains(i)
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                steps[i].detail,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: t.textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: steps.isEmpty ? 0 : done / steps.length,
              minHeight: 6,
              backgroundColor: t.row,
              color: t.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolesCard({required int limit}) {
    final t = GlassTokens.of(context);
    final roles = (widget.entry['related_roles'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(
            title: 'Other roles that fit you',
            trailing: _levelNames[widget.entry['level']],
          ),
          const SizedBox(height: 14),
          if (roles.isEmpty)
            Text(
              'No related roles to compare yet.',
              style: TextStyle(fontSize: 15, color: t.textSub),
            ),
          for (final r in roles.take(limit))
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.cardEdge),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['title']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        if ((r['to_add'] as List).isNotEmpty)
                          Text(
                            'To grow: ${(r['to_add'] as List).join(', ')}',
                            style: TextStyle(fontSize: 14, color: t.textSub),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${r['score']}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      Text(
                        '${r['label']}',
                        style: TextStyle(fontSize: 13, color: t.textSub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (roles.length > limit)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _tab = _Tab.jobs),
                child: Text(
                  'See all in Jobs →',
                  style: TextStyle(color: t.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coachCard() {
    final t = GlassTokens.of(context);
    final advice = widget.entry['advice'] as Map<String, dynamic>?;
    final error = widget.entry['advice_error'] as String?;
    Widget body;
    if (widget.adviceLoading) {
      body = Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Your coach is writing tips… (about 10 seconds)',
            style: TextStyle(fontSize: 15, color: t.textSub),
          ),
        ],
      );
    } else if (advice != null) {
      final strengths = (advice['strengths'] as List? ?? const [])
          .map((e) => '$e')
          .toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${advice['summary'] ?? ''}',
            style: TextStyle(fontSize: 16, height: 1.55, color: t.text),
          ),
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final s in strengths)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.check, size: 18, color: t.success),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: t.textSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (widget.entry['advice_stale'] == true) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'You changed your details after these tips were written.',
                  style: TextStyle(fontSize: 14, color: t.warning),
                ),
                if (widget.onRequestAdvice != null)
                  OutlinedButton(
                    key: const Key('refresh-tips'),
                    onPressed: widget.onRequestAdvice,
                    child: const Text('Get new tips'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _tab = _Tab.details),
              child: Text(
                'Resume tips, interview practice and roadmap in Details →',
                style: TextStyle(color: t.accent),
              ),
            ),
          ),
        ],
      );
    } else if (error != null) {
      body = Text(
        'Tips are not available right now: $error Your score and skills above are complete.',
        style: TextStyle(fontSize: 15, color: t.warning),
      );
    } else {
      body = Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Get short, friendly tips on what to do next.',
            style: TextStyle(fontSize: 15, color: t.textSub),
          ),
          if (widget.onRequestAdvice != null)
            OutlinedButton(
              key: const Key('get-tips'),
              onPressed: widget.onRequestAdvice,
              child: const Text('Get AI tips'),
            ),
        ],
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Head(title: 'AI coach'),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  // Skills

  Widget _skillsPanel(bool wide) {
    final t = GlassTokens.of(context);
    if (_skills.isEmpty) {
      return GlassCard(
        child: Text(
          'This job title has no skill list yet.',
          style: TextStyle(fontSize: 15, color: t.textSub),
        ),
      );
    }
    _selected ??=
        (_skills.firstWhere(
              (s) => s['found'] == null,
              orElse: () => _skills.first,
            ))['name']
            as String;
    final ads = _skills.any((s) => s['share'] != null);
    Widget group(bool core) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(core ? 'Core skills you have' : 'Bonus skills you have'),
        _haveTags(core),
        const SizedBox(height: 18),
        _Label(core ? 'Core skills to add' : 'Bonus skills to consider'),
        _needList(core),
      ],
    );
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(
            title: 'Skills for ${(widget.entry['role'] as Map)['title']}',
            trailing: ads
                ? 'From real job ads, click a skill to learn more'
                : 'Click a skill to learn more',
          ),
          const SizedBox(height: 18),
          _Columns(
            wide: wide,
            gap: 24,
            flex: const [10, 10, 11],
            children: [group(true), group(false), _inspector()],
          ),
          const SizedBox(height: 14),
          Text(
            'Already know one of the skills to add? Tick "I have this" to preview your new score. It only counts once it is on your resume.',
            style: TextStyle(fontSize: 14, color: t.textSub),
          ),
        ],
      ),
    );
  }

  Widget _haveTags(bool core) {
    final t = GlassTokens.of(context);
    final have = _skills
        .where((s) => s['core'] == core && s['found'] != null)
        .toList();
    if (have.isEmpty) {
      return Text(
        'None yet.',
        style: TextStyle(fontSize: 15, color: t.textSub),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in have)
          _SkillTag(
            label: '${s['name']}',
            selected: _selected == s['name'],
            onTap: () => setState(() => _selected = s['name'] as String),
          ),
      ],
    );
  }

  Widget _needList(bool core) {
    final t = GlassTokens.of(context);
    final need = _skills
        .where((s) => s['core'] == core && s['found'] == null)
        .toList();
    if (need.isEmpty) {
      return Text(
        core ? 'You have every core skill.' : 'Nothing else to add.',
        style: TextStyle(fontSize: 15, color: t.textSub),
      );
    }
    return Column(
      children: [
        for (final s in need)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: (_ticked.contains(s['name']) ? t.success : t.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selected = s['name'] as String),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${s['name']}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _ticked.contains(s['name'])
                                  ? t.success
                                  : t.warning,
                              decoration: _selected == s['name']
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          if (s['share'] != null)
                            TextSpan(
                              text: '  ${s['share']}% of ads',
                              style: TextStyle(fontSize: 13, color: t.textSub),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Checkbox(
                  key: Key('have-${s['name']}'),
                  value: _ticked.contains(s['name']),
                  activeColor: t.success,
                  onChanged: (v) =>
                      _toggleSkill(s['name'] as String, v ?? false),
                ),
                Text(
                  'I have this',
                  style: TextStyle(fontSize: 13, color: t.textSub),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
      ],
    );
  }

  Widget _inspector() {
    final t = GlassTokens.of(context);
    final s = _skills.firstWhere(
      (x) => x['name'] == _selected,
      orElse: () => _skills.first,
    );
    final name = s['name'] as String;
    final found = s['found'] as String?;
    final ticked = _ticked.contains(name);
    final status = switch (found) {
      'work' => 'Shown in your work',
      'listed' => 'Listed on your resume',
      _ =>
        ticked
            ? 'Ticked as known (preview only)'
            : (s['core'] == true
                  ? 'Core skill to add'
                  : 'Bonus skill to consider'),
    };
    final evidence = s['evidence'] as Map<String, dynamic>?;
    final share = s['share'] as int?;
    final gain = s['gain'] as num?;
    final advice = widget.entry['advice'] as Map<String, dynamic>?;
    final aiTip = (advice?['next_skills'] as List? ?? const [])
        .cast<Map>()
        .where(
          (x) => '${x['skill']}'.toLowerCase().contains(name.toLowerCase()),
        )
        .map((x) => '${x['how']}')
        .firstOrNull;
    return Container(
      key: const Key('skill-inspector'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.row,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: found != null || ticked ? t.success : t.warning,
            ),
          ),
          if (share != null) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Asked for in ',
                    style: TextStyle(fontSize: 14, color: t.textSub),
                  ),
                  TextSpan(
                    text: '$share%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' of ${(widget.entry['role'] as Map)['title']} job ads we studied',
                    style: TextStyle(fontSize: 14, color: t.textSub),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share / 100,
                minHeight: 8,
                backgroundColor: t.cardEdge,
                color: t.accent,
              ),
            ),
          ],
          if (evidence != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
                border: Border(left: BorderSide(color: t.success, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found in: ${evidence['where']}',
                    style: TextStyle(fontSize: 13, color: t.textSub),
                  ),
                  Text(
                    '${evidence['text']}',
                    style: TextStyle(fontSize: 15, height: 1.5, color: t.text),
                  ),
                ],
              ),
            ),
          ],
          if (found == 'listed') ...[
            const SizedBox(height: 10),
            Text(
              'Mention it in a job line where you used it. A skill shown in your work counts a little more.',
              style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub),
            ),
          ],
          if (found == null && !ticked && gain != null && gain > 0) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '+$gain points',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.success,
                    ),
                  ),
                  TextSpan(
                    text: ' if you add it to your resume.',
                    style: TextStyle(fontSize: 15, color: t.textSub),
                  ),
                ],
              ),
            ),
          ],
          if (found == null) ...[
            const SizedBox(height: 10),
            Text(
              aiTip ?? 'If you already use it, write it in your skills and in one job line. If not, a short course or small project is a good start.',
              style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub),
            ),
          ],
        ],
      ),
    );
  }

  // Jobs

  Widget _jobsPanel(bool wide) {
    final t = GlassTokens.of(context);
    final roles = (widget.entry['related_roles'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final openings = GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Head(title: 'Jobs that match you'),
          const SizedBox(height: 14),
          Icon(Icons.work_outline, size: 32, color: t.textSub),
          const SizedBox(height: 10),
          Text(
            'Open jobs will appear here, ranked by your fit, once recruiters post roles on CareerBridge.',
            style: TextStyle(fontSize: 16, height: 1.5, color: t.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Until then, the roles below show where your resume already fits.',
            style: TextStyle(fontSize: 15, color: t.textSub),
          ),
        ],
      ),
    );
    final visibility = GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Head(title: 'Let recruiters find you'),
          const SizedBox(height: 8),
          Text(
            'Recruiters can invite you to apply when your skills fit their roles.',
            style: TextStyle(fontSize: 15, color: t.textSub),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: t.row,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Available after you sign in',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                ),
                const Switch(value: false, onChanged: null),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Label('Recruiters would see'),
          _bullet('Your skills, experience and education summary'),
          _bullet('Your fit score for their role'),
          const SizedBox(height: 10),
          const _Label('They would not see'),
          _bullet('Your name, phone, email or address, until you accept'),
          _bullet('Your resume file'),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PairRow(
          wide: wide,
          left: openings,
          right: visibility,
          leftFlex: 3,
          rightFlex: 2,
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Head(
                title: 'Other roles to consider',
                trailing: 'Your fit at ${_levelNames[widget.entry['level']]}',
              ),
              const SizedBox(height: 14),
              if (roles.isEmpty)
                Text(
                  'No related roles to compare yet.',
                  style: TextStyle(fontSize: 15, color: t.textSub),
                ),
              _Columns(
                wide: wide,
                gap: 12,
                children: [
                  for (final r in roles)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.cardEdge),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['title']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: t.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${r['score']}%',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: t.text,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _Pill(
                                '${r['label']}',
                                _Band.of(r['score'] as int, t).color,
                              ),
                            ],
                          ),
                          if ((r['to_add'] as List).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'To grow: ${(r['to_add'] as List).join(', ')}',
                              style: TextStyle(fontSize: 14, color: t.textSub),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '•  $text',
        style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub),
      ),
    );
  }

  // Details

  Widget _detailsPanel(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PairRow(wide: wide, left: _experienceCard(), right: _educationCard()),
        const SizedBox(height: 20),
        _PairRow(
          wide: wide,
          left: _progressCard(),
          right: _moreCard(),
          stretch: false,
        ),
      ],
    );
  }

  Widget _experienceCard() {
    final t = GlassTokens.of(context);
    final p = widget.entry['profile'] as Map<String, dynamic>?;
    final years = _saved['relevant_years'] as num?;
    final jobs = (p?['experience'] as List? ?? const []).cast<Map>();
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(
            title: 'Experience',
            big: years == null
                ? null
                : '${years.toStringAsFixed(years % 1 == 0 ? 0 : 1)} yrs related',
          ),
          const SizedBox(height: 14),
          if (jobs.isEmpty)
            Text(
              'No work history was found.',
              style: TextStyle(fontSize: 15, color: t.textSub),
            ),
          for (final j in jobs)
            _TimelineItem(
              title: '${j['title']}',
              detail: [
                if (j['organisation'] != null) '${j['organisation']}',
                '${j['start'] ?? '?'} – ${j['end'] ?? '?'}',
                '${j['type']}',
              ].join(', '),
              faded: j['type'] == 'internship' || j['type'] == 'part-time',
            ),
          for (final r
              in ((_saved['parts'] as Map)['experience'] as Map)['reasons']
                  as List)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$r',
                style: TextStyle(fontSize: 14, color: t.textSub),
              ),
            ),
        ],
      ),
    );
  }

  Widget _educationCard() {
    final t = GlassTokens.of(context);
    final p = widget.entry['profile'] as Map<String, dynamic>?;
    final edu = (p?['education'] as List? ?? const []).cast<Map>();
    final certs = (p?['certifications'] as List? ?? const [])
        .map((e) => '$e')
        .toList();
    final langs = (p?['languages'] as List? ?? const [])
        .map((e) => '$e')
        .toList();
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(
            title: 'Education',
            big: edu.isEmpty ? null : '${edu.first['level']}',
          ),
          const SizedBox(height: 14),
          if (edu.isEmpty)
            Text(
              'No education was found.',
              style: TextStyle(fontSize: 15, color: t.textSub),
            ),
          for (final e in edu)
            _TimelineItem(
              title: [
                e['level'],
                if (e['field'] != null) e['field'],
              ].join(', '),
              detail:
                  '${e['institution'] ?? 'Institution not stated'}${e['end_year'] != null ? ', ${e['end_year']}' : ''}',
            ),
          if (certs.isNotEmpty)
            Text(
              'Certifications: ${certs.join(', ')}',
              style: TextStyle(fontSize: 15, color: t.textSub),
            ),
          if (langs.isNotEmpty)
            Text(
              'Languages: ${langs.join(', ')}',
              style: TextStyle(fontSize: 15, color: t.textSub),
            ),
          for (final r
              in ((_saved['parts'] as Map)['education'] as Map)['reasons']
                  as List)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$r',
                style: TextStyle(fontSize: 14, color: t.textSub),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final t = GlassTokens.of(context);
    final role = (widget.entry['role'] as Map)['title'];
    final name = (widget.entry['file'] as Map)['name'];
    final history = ref
        .watch(logbookProvider)
        .maybeWhen(
          data: (rows) =>
              rows
                  .where((r) => r['file_name'] == name && r['role'] == role)
                  .map(
                    (r) =>
                        (when: '${r['created_at']}', score: r['score'] as int),
                  )
                  .toList()
                ..sort((a, b) => a.when.compareTo(b.when)),
          orElse: () => <({String when, int score})>[],
        );
    final points = history.length > 6
        ? history.sublist(history.length - 6)
        : history;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Head(title: 'Your progress'),
          const SizedBox(height: 6),
          Text(
            'Your score each time you analyse this resume for $role.',
            style: TextStyle(fontSize: 15, color: t.textSub),
          ),
          const SizedBox(height: 12),
          if (points.length < 2)
            Text(
              'Analyse an updated version of this resume later to see your progress here.',
              style: TextStyle(fontSize: 15, color: t.textSub),
            )
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _HistoryPainter(
                  scores: [for (final p in points) p.score],
                  labels: [
                    for (final p in points)
                      p.when.length >= 10 ? p.when.substring(5, 10) : p.when,
                  ],
                  preview: _isPreview ? _shown['score'] as int : null,
                  tokens: t,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _moreCard() {
    final t = GlassTokens.of(context);
    final advice = widget.entry['advice'] as Map<String, dynamic>?;
    final directions = (widget.entry['directions'] as Map)['items'] as List;
    final file = widget.entry['file'] as Map<String, dynamic>;
    final uncertain =
        ((widget.entry['profile'] as Map?)?['uncertain'] as List? ?? const [])
            .map((e) => '$e')
            .toList();
    final total = (widget.entry['timings'] as Map).values.fold<num>(
      0,
      (a, b) => a + (b as num),
    );
    List<String> list(String key, String Function(dynamic) fmt) => [
      for (final x in (advice?[key] as List? ?? const [])) fmt(x),
    ];
    final questions = list(
      'interview_questions',
      (q) => '${q['question']} — ${q['tip']}',
    );
    final tips = list('resume_tips', (x) => '$x');
    final roadmap = list(
      'roadmap',
      (s) => '${s['step']}. ${s['focus']} (${s['weeks']} weeks)',
    );

    Widget section(String title, List<String> lines, {Key? key}) => Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: key,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 10),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: t.text,
          ),
        ),
        children: [for (final l in lines) _bullet(l)],
      ),
    );

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Head(title: 'More detail'),
            const SizedBox(height: 10),
            if (directions.isNotEmpty)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Your resume as a whole reads most like ',
                      style: TextStyle(fontSize: 15, color: t.textSub),
                    ),
                    TextSpan(
                      text: '${directions.first['name']}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' (${((directions.first['probability'] as num) * 100).round()}%). This looks at the whole resume, so it can differ from this role\'s score.',
                      style: TextStyle(fontSize: 15, color: t.textSub),
                    ),
                  ],
                ),
              ),
            if (questions.isNotEmpty)
              section('Practice interview questions', questions),
            if (tips.isNotEmpty) section('Optional resume tips', tips),
            if (roadmap.isNotEmpty) section('Your roadmap', roadmap),
            if (uncertain.isNotEmpty)
              section('Things we were not sure about', uncertain),
            section('How we read your file', [
              '${file['name']}, ${file['method']}, ${file['pages']} page(s), ${file['words']} words, ${(total / 1000).toStringAsFixed(1)} s',
            ]),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Text the AI read (personal details removed)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 360),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.row,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        '${widget.entry['clean_markdown'] ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: t.textSub,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _signed(int v) => v >= 0 ? '+$v' : '$v';
}

// ==================================================================== small parts

class _Band {
  const _Band(this.name, this.headline, this.color);
  final String name;
  final String headline;
  final Color color;

  static _Band of(int score, GlassTokens t) {
    if (score >= 80) {
      return _Band('Strong match', 'You are a strong match', t.success);
    }
    if (score >= 65) {
      return _Band('Good match', 'You are a good match', t.accent);
    }
    if (score >= 45) {
      return _Band('Partial match', 'You are part of the way there', t.warning);
    }
    return _Band('Low match', 'This role is a stretch for now', t.danger);
  }
}

const _partColors = {
  'skills': Color(0xFF2F6FDB),
  'experience': Color(0xFF0F9F8F),
  'education': Color(0xFF8B5CF6),
};
const _partLabels = {
  'skills': 'Skills',
  'experience': 'Experience',
  'education': 'Education',
};

/// Points each part adds to the score.
int _points(Map<String, dynamic> part) {
  final s = part['score'] as num?;
  return s == null ? 0 : (s * (part['weight'] as num) * 100).round();
}

class _StackBar extends StatelessWidget {
  const _StackBar({required this.parts});
  final Map<String, dynamic> parts;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final pts = {
      for (final k in _partColors.keys)
        k: _points((parts[k] as Map).cast<String, dynamic>()),
    };
    final rest = math.max(0, 100 - pts.values.fold(0, (a, b) => a + b)).toInt();
    return SizedBox(
      height: 12,
      child: Row(
        children: [
          for (final e in pts.entries)
            if (e.value > 0)
              Expanded(flex: e.value, child: _seg(_partColors[e.key]!)),
          if (rest > 0) Expanded(flex: rest, child: _seg(t.cardEdge)),
        ],
      ),
    );
  }

  Widget _seg(Color c) => Container(
    margin: const EdgeInsets.only(right: 3),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
  );
}

class _PartSummary extends StatelessWidget {
  const _PartSummary({required this.name, required this.part});
  final String name;
  final Map<String, dynamic> part;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final reasons = (part['reasons'] as List? ?? const [])
        .map((e) => '$e')
        .toList();
    final counted = part['score'] != null;
    final max = ((part['weight'] as num) * 100).round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: counted ? _partColors[name] : t.cardEdge,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _partLabels[name],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                    TextSpan(
                      text: counted
                          ? '   ${_points(part)} of $max'
                          : '   Not counted',
                      style: TextStyle(
                        fontSize: 15,
                        color: t.textSub,
                        fontStyle: counted ? null : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (reasons.isNotEmpty)
                Text(
                  reasons.first,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: t.textSub,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.keyPrefix,
  });
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.row,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardEdge),
      ),
      child: Wrap(
        spacing: 2,
        children: [
          for (final e in options.entries)
            Material(
              color: e.key == selected ? t.card : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              elevation: e.key == selected ? 1 : 0,
              child: InkWell(
                key: Key('$keyPrefix-${e.key}'),
                borderRadius: BorderRadius.circular(9),
                onTap: () => onSelect(e.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: e.key == selected ? t.text : t.textSub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color, {this.filled = false});
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? t.row : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  const _SkillTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Material(
      color: t.success.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? t.success : Colors.transparent),
      ),
      child: InkWell(
        key: Key('skill-$label'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            '✓ $label',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: t.success,
            ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.title, this.trailing, this.big});
  final String title;
  final String? trailing;
  final String? big;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: t.text,
          ),
        ),
        if (big != null)
          Text(
            big!,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
        if (trailing != null)
          Text(trailing!, style: TextStyle(fontSize: 14, color: t.textSub)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: t.text,
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.detail,
    this.faded = false,
  });
  final String title;
  final String detail;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: faded ? t.cardEdge : _partColors['experience']!,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          Text(detail, style: TextStyle(fontSize: 14, color: t.textSub)),
        ],
      ),
    );
  }
}

/// Side-by-side columns on wide screens, stacked on narrow ones.
class _Columns extends StatelessWidget {
  const _Columns({
    required this.wide,
    required this.children,
    this.gap = 20,
    this.flex,
  });
  final bool wide;
  final List<Widget> children;
  final double gap;
  final List<int>? flex;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(flex: flex?[i] ?? 1, child: children[i]),
        ],
      ],
    );
  }
}

/// Two cards in a row with equal height (stacked on narrow screens).
class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.wide,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.stretch = true,
  });
  final bool wide;
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, const SizedBox(height: 20), right],
      );
    }
    final row = Row(
      crossAxisAlignment: stretch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 20),
        Expanded(flex: rightFlex, child: right),
      ],
    );
    return stretch ? IntrinsicHeight(child: row) : row;
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({
    required this.scores,
    required this.labels,
    required this.preview,
    required this.tokens,
  });
  final List<int> scores;
  final List<String> labels;
  final int? preview;
  final GlassTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, right = 16.0, top = 18.0, bottom = 26.0;
    final all = [...scores, ?preview];
    final lo = (math.min(50, all.reduce(math.min)) ~/ 10 * 10).toDouble();
    double x(int i) =>
        left + i * (size.width - left - right) / math.max(1, all.length - 1);
    double y(num s) =>
        top + (100 - s) * (size.height - top - bottom) / (100 - lo);
    final grid = Paint()..color = tokens.cardEdge;
    final style = TextStyle(
      fontSize: 12,
      color: tokens.textSub,
      fontFamily: appFont,
    );

    void label(String text, Offset at, {TextStyle? s, bool center = true}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: s ?? style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        at - Offset(center ? tp.width / 2 : tp.width, tp.height / 2),
      );
    }

    for (final g in [lo, 65.0, 80.0, 100.0]) {
      if (g < lo) continue;
      if (g == 80) {
        final dash = Paint()
          ..color = tokens.success
          ..strokeWidth = 1.2;
        for (var dx = left; dx < size.width - right; dx += 9) {
          canvas.drawLine(
            Offset(dx, y(g)),
            Offset(math.min(dx + 5, size.width - right), y(g)),
            dash,
          );
        }
        label(
          'Strong',
          Offset(size.width - right - 20, y(g) - 9),
          s: style.copyWith(color: tokens.success),
        );
      } else {
        canvas.drawLine(
          Offset(left, y(g)),
          Offset(size.width - right, y(g)),
          grid,
        );
      }
      label(g.round().toString(), Offset(left - 6, y(g)), center: false);
    }
    final line = Paint()
      ..color = tokens.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(x(0), y(scores.first));
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(x(i), y(scores[i]));
    }
    canvas.drawPath(path, line);
    if (preview != null) {
      final a = scores.length - 1;
      canvas.drawLine(
        Offset(x(a), y(scores[a])),
        Offset(x(a + 1), y(preview!)),
        line..color = tokens.warning,
      );
    }
    for (var i = 0; i < all.length; i++) {
      final ghost = preview != null && i == all.length - 1;
      final c = ghost ? tokens.warning : tokens.accent;
      canvas.drawCircle(
        Offset(x(i), y(all[i])),
        5,
        Paint()..color = ghost ? tokens.card : c,
      );
      canvas.drawCircle(
        Offset(x(i), y(all[i])),
        5,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      label(
        '${all[i]}',
        Offset(x(i), y(all[i]) - 14),
        s: style.copyWith(color: tokens.text, fontWeight: FontWeight.w600),
      );
      label(ghost ? 'Preview' : labels[i], Offset(x(i), size.height - 8));
    }
  }

  @override
  bool shouldRepaint(_HistoryPainter old) =>
      old.scores != scores || old.preview != preview || old.tokens != tokens;
}
