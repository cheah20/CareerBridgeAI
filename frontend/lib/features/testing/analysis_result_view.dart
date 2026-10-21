import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'assessment_view.dart';

/// Shows one analysis (a logbook entry from the testing API).
class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({
    super.key,
    required this.entry,
    this.adviceLoading = false,
    this.onRequestAdvice,
  });

  final Map<String, dynamic> entry;
  final bool adviceLoading;
  final VoidCallback? onRequestAdvice;

  @override
  Widget build(BuildContext context) {
    if (entry['format'] == 2) {
      return AssessmentView(
        entry: entry,
        adviceLoading: adviceLoading,
        onRequestAdvice: onRequestAdvice,
      );
    }
    final t = GlassTokens.of(context);
    final fit = entry['fit'] as Map<String, dynamic>;
    final parts = (fit['parts'] as Map).cast<String, num>();
    final role = entry['role'] as Map<String, dynamic>;
    final file = entry['file'] as Map<String, dynamic>;
    final directions = (entry['directions']['items'] as List)
        .cast<Map<String, dynamic>>();
    final matched = (fit['matched'] as List)
        .map((m) => m['name'] as String)
        .toList();
    final missing = (fit['missing'] as List)
        .map((m) => m['name'] as String)
        .toList();
    final score = fit['score'] as int;
    final scoreColor = score >= 80
        ? t.success
        : (score >= 65 ? t.text : (score >= 45 ? t.warning : t.danger));

    Color partColor(num v) =>
        v >= 0.7 ? t.success : (v >= 0.4 ? t.warning : t.danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatStrip(
          items: [
            StatItem(
              'Fit for ${role['title']}',
              '$score%',
              fit['label'] as String,
            ),
            StatItem(
              'Level',
              entry['level_label'] as String,
              _years(fit['years_estimate']),
            ),
            StatItem(
              'Skills found',
              '${matched.length}',
              '${missing.length} missing',
            ),
            StatItem(
              'Top direction',
              directions.isEmpty ? '—' : directions.first['name'] as String,
              directions.isEmpty
                  ? ''
                  : '${((directions.first['probability'] as num) * 100).round()}% model confidence',
            ),
          ],
        ),
        const SizedBox(height: Gaps.block),
        TwoPane(
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardHeader(
                      title: 'Fit score breakdown',
                      trailing: '${role['field']}',
                    ),
                    Text(
                      '$score% · ${fit['label']}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System fit indicator, not a hiring prediction.',
                      style: TextStyle(fontSize: 12, color: t.textSub),
                    ),
                    const SizedBox(height: 14),
                    for (final p in const ['skills', 'experience', 'education'])
                      LevelBar(
                        label: '${p[0].toUpperCase()}${p.substring(1)}',
                        value: (parts[p] ?? 0).toDouble(),
                        color: partColor(parts[p] ?? 0),
                        caption: '${((parts[p] ?? 0) * 100).round()}%',
                      ),
                    for (final note in (fit['notes'] as List).cast<String>())
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '• $note',
                          style: TextStyle(fontSize: 13, color: t.textSub),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.block),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CardHeader(
                      title: 'Skills',
                      trailing: 'from the role catalogue',
                    ),
                    _ChipGroup(
                      title: 'Found in the resume',
                      items: matched,
                      color: t.success,
                      empty: 'None of the listed skills were found.',
                    ),
                    const SizedBox(height: 12),
                    _ChipGroup(
                      title: 'Missing',
                      items: missing,
                      color: t.warning,
                      empty: 'Nothing important is missing.',
                    ),
                    if ((fit['soft_skills'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ChipGroup(
                        title: 'Soft skills mentioned',
                        items: (fit['soft_skills'] as List).cast<String>(),
                        color: t.textSub,
                        empty: '',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Gaps.block),
              _AdviceCard(entry: entry),
            ],
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardHeader(
                      title: 'Other directions',
                      trailing:
                          'model ${entry['directions']['model_version'] ?? '—'}',
                    ),
                    for (final d in directions)
                      GlassListRow(
                        initials: _initials(d['name'] as String),
                        title: d['name'] as String,
                        subtitle: 'Career direction',
                        value: '${((d['probability'] as num) * 100).round()}%',
                        progress: (d['probability'] as num).toDouble(),
                      ),
                    if (directions.isEmpty)
                      Text(
                        'No model is deployed.',
                        style: TextStyle(color: t.textSub),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.block),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CardHeader(title: 'Resume reading'),
                    _Fact('File', file['name'] as String),
                    _Fact('Read with', file['method'] as String),
                    _Fact(
                      'Pages',
                      '${file['pages']}${(file['ocr_pages'] as int? ?? 0) > 0 ? ' (${file['ocr_pages']} by OCR)' : ''}',
                    ),
                    _Fact('Words', '${file['words']}'),
                    _Fact('Time', _timings(entry['timings'] as Map)),
                    for (final w in (file['warnings'] as List).cast<String>())
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '⚠ $w',
                          style: TextStyle(fontSize: 12.5, color: t.warning),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Material(
                      type: MaterialType.transparency,
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Text read from the file',
                            style: TextStyle(fontSize: 13.5, color: t.text),
                          ),
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxHeight: 360),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: t.row,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  entry['text'] as String? ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: t.textSub,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _years(dynamic years) => years == null
      ? 'experience not found'
      : '≈ ${(years as num).toStringAsFixed(1)} yrs found';

  static String _initials(String name) {
    final words = name
        .split(RegExp(r'[\s/&]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return (words.length > 1
            ? '${words[0][0]}${words[1][0]}'
            : name.substring(0, name.length < 2 ? name.length : 2))
        .toUpperCase();
  }

  static String _timings(Map timings) {
    final total = timings.values.fold<num>(0, (a, b) => a + (b as num));
    return '${(total / 1000).toStringAsFixed(1)} s';
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: t.textSub),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12.5, color: t.text)),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.title,
    required this.items,
    required this.color,
    required this.empty,
  });
  final String title;
  final List<String> items;
  final Color color;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: t.textSub,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(empty, style: TextStyle(fontSize: 12.5, color: t.textSub))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final i in items) GlassChip(label: i, color: color),
            ],
          ),
      ],
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final advice = entry['advice'] as Map<String, dynamic>?;
    final error = entry['advice_error'] as String?;
    Widget body;
    if (advice != null) {
      List<String> list(String key, String Function(dynamic) fmt) => [
        for (final x in (advice[key] as List? ?? [])) fmt(x),
      ];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            advice['summary'] as String? ?? '',
            style: TextStyle(fontSize: 14, height: 1.5, color: t.text),
          ),
          _Section('Strengths', list('strengths', (x) => '$x')),
          _Section(
            'Gaps and how to close them',
            list(
              'gaps',
              (g) =>
                  '${g['skill']}: ${g['why_it_matters']} → ${g['how_to_improve']}',
            ),
          ),
          _Section(
            'Improve your resume',
            list('resume_improvements', (x) => '$x'),
          ),
          _Section(
            'Interview practice',
            list(
              'interview_questions',
              (q) => '${q['question']}  (${q['what_it_tests']})',
            ),
          ),
          _Section(
            'Learning roadmap',
            list(
              'learning_roadmap',
              (s) =>
                  '${s['step']}. ${s['focus']} · ${s['weeks']} wk — ${s['activities']}',
            ),
          ),
        ],
      );
    } else if (error != null) {
      body = Text(
        'AI advice was not available: $error The score and skills above are still valid.',
        style: TextStyle(fontSize: 13, color: t.warning),
      );
    } else {
      body = Text(
        'Not requested for this analysis. Tick "Include AI coach tips" to add it.',
        style: TextStyle(fontSize: 13, color: t.textSub),
      );
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(title: 'AI advice', trailing: 'DeepSeek'),
          body,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.lines);
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          const SizedBox(height: 6),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $l',
                style: TextStyle(fontSize: 13, height: 1.45, color: t.textSub),
              ),
            ),
        ],
      ),
    );
  }
}
