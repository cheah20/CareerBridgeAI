import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'analysis_result_view.dart';
import 'testing_api.dart';

/// Testing mode: every analysis saved in the backend's local logbook.
class LogbookPage extends ConsumerStatefulWidget {
  const LogbookPage({super.key});

  @override
  ConsumerState<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends ConsumerState<LogbookPage> {
  String? _openId;
  Map<String, dynamic>? _entry;
  String? _error;
  bool _adviceLoading = false;

  Future<void> _requestAdvice() async {
    final id = _openId;
    if (id == null) return;
    setState(() => _adviceLoading = true);
    try {
      final reply = await ref.read(testingApiProvider).advice(id);
      if (mounted && _openId == id) {
        setState(
          () => _entry = {
            ..._entry!,
            'advice': reply['advice'],
            'advice_error': reply['advice_error'],
          },
        );
      }
      ref.invalidate(logbookProvider);
    } on TestingFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _adviceLoading = false);
    }
  }

  Future<void> _open(String id) async {
    setState(() {
      _openId = id;
      _entry = null;
      _error = null;
    });
    try {
      final entry = await ref.read(testingApiProvider).entry(id);
      if (mounted && _openId == id) setState(() => _entry = entry);
    } on TestingFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final entries = ref.watch(logbookProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: 'Testing mode',
          title: 'Test logbook.',
          subtitle: 'Every analysis run in testing mode, newest first. Stored on this computer only.',
          trailing: OutlinedButton(
            onPressed: () => ref.invalidate(logbookProvider),
            child: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: Gaps.section),
        GlassCard(
          child: entries.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e', style: TextStyle(color: t.danger)),
            data: (list) => list.isEmpty
                ? Text(
                    'No analyses yet. Run one on the Resume analysis page.',
                    style: TextStyle(color: t.textSub),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CardHeader(
                        title: '${list.length} analyses',
                        trailing: 'Select one to view',
                      ),
                      for (final e in list)
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _open(e['id'] as String),
                          child: GlassListRow(
                            initials: '${e['score']}',
                            title: '${e['role']} · ${e['level']}',
                            subtitle:
                                '${e['file_name']} · ${_when(e['created_at'] as String)}'
                                '${e['top_direction'] != null ? ' · direction: ${e['top_direction']}' : ''}'
                                '${e['with_advice'] == true ? ' · with AI advice' : ''}',
                            value: '${e['score']}%',
                            valueCaption: e['label'] as String,
                            progress: (e['score'] as num) / 100,
                            selected: e['id'] == _openId,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (_openId != null) ...[
          const SizedBox(height: Gaps.block),
          if (_error != null)
            Text(_error!, style: TextStyle(color: t.danger))
          else if (_entry == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            AnalysisResultView(
              entry: _entry!,
              adviceLoading: _adviceLoading,
              onRequestAdvice: _requestAdvice,
            ),
        ],
      ],
    );
  }

  static String _when(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
