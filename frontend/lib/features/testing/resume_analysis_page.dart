import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'analysis_result_view.dart';
import 'testing_api.dart';

/// Testing mode: upload a resume, choose a job title and level, see the analysis.
class ResumeAnalysisPage extends ConsumerStatefulWidget {
  const ResumeAnalysisPage({super.key});

  @override
  ConsumerState<ResumeAnalysisPage> createState() => _ResumeAnalysisPageState();
}

class _ResumeAnalysisPageState extends ConsumerState<ResumeAnalysisPage> {
  String? _fileName;
  Uint8List? _bytes;
  String? _field;
  String? _roleId;
  String _level = 'junior';
  bool _useLlm = false;
  bool _busy = false;
  bool _adviceLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  /// The running analysis: status pending / processing / completed / failed.
  Map<String, dynamic>? _task;

  static const _maxBytes = 10 * 1024 * 1024;

  Future<void> _pickFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (picked == null) return;
    final bytes = await picked.xFile.readAsBytes();
    setState(() {
      _error = bytes.length > _maxBytes
          ? 'The file is larger than 10 MB.'
          : null;
      _fileName = picked.name;
      _bytes = bytes.length > _maxBytes ? null : bytes;
    });
  }

  static const _pollEvery = Duration(seconds: 1);
  static const _giveUpAfter = Duration(minutes: 4);

  Future<void> _analyse() async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _task = null;
    });
    final api = ref.read(testingApiProvider);
    try {
      var task = await api.startAnalysis(
        bytes: _bytes!,
        fileName: _fileName!,
        roleId: _roleId!,
        level: _level,
        useLlm: _useLlm,
      );
      final started = DateTime.now();
      while (mounted) {
        setState(() => _task = task);
        if (task['status'] == 'completed' || task['status'] == 'failed') break;
        if (DateTime.now().difference(started) > _giveUpAfter) {
          setState(
            () => _task = {
              ...task,
              'status': 'failed',
              'error': 'This is taking longer than usual. Please check the logbook later, or try again.',
            },
          );
          break;
        }
        await Future<void>.delayed(_pollEvery);
        task = await api.task(task['id'] as String);
      }
      if (!mounted || task['status'] != 'completed') return;
      setState(() => _result = task['entry'] as Map<String, dynamic>);
      ref.invalidate(logbookProvider);
      ref.invalidate(usageProvider);
      if (_useLlm) _requestAdvice(); // the score shows first; tips follow
    } on TestingFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestAdvice() async {
    final id = _result?['id'] as String?;
    if (id == null) return;
    setState(() => _adviceLoading = true);
    try {
      final reply = await ref.read(testingApiProvider).advice(id);
      if (!mounted) return;
      setState(
        () => _result = {
          ..._result!,
          'advice': reply['advice'],
          'advice_error': reply['advice_error'],
          'advice_stale': false,
        },
      );
      ref.invalidate(logbookProvider);
      ref.invalidate(usageProvider);
    } on TestingFailure catch (e) {
      if (mounted) {
        setState(() => _result = {..._result!, 'advice_error': e.message});
      }
    } finally {
      if (mounted) setState(() => _adviceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final catalog = ref.watch(catalogProvider);
    final ready = _bytes != null && _roleId != null && !_busy;

    final form = GlassCard(
      child: catalog.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$e', style: TextStyle(color: t.danger, fontSize: 13)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => ref.invalidate(catalogProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
        data: (cat) {
          final roles = cat.fields
              .where((f) => f.name == _field)
              .expand((f) => f.roles)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader(title: 'New analysis'),
              OutlinedButton.icon(
                key: const Key('pick-resume'),
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  _fileName ?? 'Choose resume (PDF, DOCX, JPG, PNG)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const Key('field'),
                initialValue: _field,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Field'),
                items: [
                  for (final f in cat.fields)
                    DropdownMenuItem(
                      value: f.name,
                      child: Text(f.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() {
                        _field = v;
                        _roleId = null;
                      }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('role-$_field'),
                initialValue: _roleId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _field == null
                      ? 'Job title (choose a field first)'
                      : 'Job title',
                ),
                items: [
                  for (final r in roles)
                    DropdownMenuItem(
                      value: r.id,
                      child: Text(r.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _busy || _field == null
                    ? null
                    : (v) => setState(() => _roleId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('level'),
                initialValue: _level,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Experience level',
                ),
                items: [
                  for (final e in cat.levels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _level = v ?? _level),
              ),
              const SizedBox(height: 8),
              Material(
                type: MaterialType.transparency, // list tiles draw on the nearest Material, not on glass
                child: CheckboxListTile(
                  key: const Key('use-llm'),
                  contentPadding: EdgeInsets.zero,
                  value: _useLlm,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _useLlm = v ?? false),
                  title: Text(
                    'Include AI coach tips',
                    style: TextStyle(fontSize: 14, color: t.text),
                  ),
                  subtitle: Text(
                    'Short tips, interview practice and a roadmap. They appear after your score.',
                    style: TextStyle(fontSize: 12, color: t.textSub),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const _UsageLine(),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('analyse'),
                onPressed: ready ? _analyse : null,
                child: Text(_busy ? 'Reading your resume…' : 'Analyse resume'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: t.danger, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Text(
                'Testing mode: results are saved to the local logbook on this computer, not to the database.',
                style: TextStyle(fontSize: 11.5, color: t.textFaint),
              ),
            ],
          );
        },
      ),
    );

    final Widget results = _result != null
        ? AnalysisResultView(
            entry: _result!,
            adviceLoading: _adviceLoading,
            onRequestAdvice: _requestAdvice,
            onEntryChanged: (e) => setState(() => _result = e),
          )
        : _task != null
        ? TaskStatusCard(task: _task!, onRetry: _busy ? null : _analyse)
        : GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    _busy
                        ? Icons.hourglass_top_outlined
                        : Icons.insights_outlined,
                    size: 36,
                    color: t.textSub,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _busy
                        ? 'Reading the resume and scoring it…'
                        : 'Results appear here after you analyse a resume.',
                    style: TextStyle(color: t.textSub),
                  ),
                ],
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          kicker: 'Testing mode',
          title: 'Resume analysis.',
          subtitle: 'Upload a resume, choose the job you are aiming for, and see how it fits.',
          trailing: GlassChip(label: 'Local logbook'),
        ),
        const SizedBox(height: Gaps.section),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 1100
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 340, child: form),
                    const SizedBox(width: Gaps.block),
                    Expanded(child: results),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: Gaps.block),
                    results,
                  ],
                ),
        ),
      ],
    );
  }
}

/// Shows where a background analysis is: Pending, Processing, Completed or Failed.
class TaskStatusCard extends StatelessWidget {
  const TaskStatusCard({super.key, required this.task, this.onRetry});

  final Map<String, dynamic> task;
  final VoidCallback? onRetry;

  static const _steps = ['Pending', 'Processing', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final status = task['status'] as String? ?? 'pending';
    final failed = status == 'failed';
    final reached = switch (status) {
      'pending' => 0,
      'processing' => 1,
      _ => 2,
    };
    return GlassCard(
      key: const Key('task-status'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            failed
                ? 'We could not finish this analysis'
                : 'Analysing your resume',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (i, name) in _steps.indexed) ...[
                if (i > 0)
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      color: !failed && i <= reached ? t.accent : t.cardEdge,
                    ),
                  ),
                _StepDot(
                  label: failed && i == 2 ? 'Failed' : name,
                  done: !failed && i < reached || status == 'completed',
                  active: !failed && i == reached && status != 'completed',
                  failed: failed && i == 2,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (failed) ...[
            Text(
              '${task['error'] ?? 'Something went wrong.'}',
              key: const Key('task-error'),
              style: TextStyle(fontSize: 15, color: t.danger),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ),
          ] else
            Row(
              children: [
                if (status != 'completed') ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    status == 'completed'
                        ? 'Done. Opening your result…'
                        : '${task['step'] ?? 'Waiting to start'}…',
                    key: const Key('task-step'),
                    style: TextStyle(fontSize: 15, color: t.textSub),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.done,
    required this.active,
    required this.failed,
  });

  final String label;
  final bool done, active, failed;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final color = failed ? t.danger : (done || active ? t.accent : t.textFaint);
    return Column(
      children: [
        Icon(
          failed
              ? Icons.error_outline
              : done
              ? Icons.check_circle
              : active
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: color,
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active || failed ? FontWeight.w600 : FontWeight.w400,
            color: failed ? t.danger : (active || done ? t.text : t.textSub),
          ),
        ),
      ],
    );
  }
}

/// "AI requests left today: 27 of 30" under the AI tips box.
class _UsageLine extends ConsumerWidget {
  const _UsageLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GlassTokens.of(context);
    return ref
        .watch(usageProvider)
        .maybeWhen(
          data: (u) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              u['monthly_limited'] == true
                  ? 'AI tips are paused for this month. Your score still works.'
                  : 'AI requests left today: ${u['left_today']} of ${u['daily_limit']}',
              key: const Key('usage-line'),
              style: TextStyle(
                fontSize: 12,
                color:
                    (u['left_today'] as num? ?? 1) == 0 ||
                        u['monthly_limited'] == true
                    ? t.warning
                    : t.textFaint,
              ),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        );
  }
}
