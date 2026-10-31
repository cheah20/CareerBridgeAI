import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import '../shell/server_status.dart';

/// Admin dashboard with sample numbers (real data arrives in Phases 5 and 6).
class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  DateTime _refreshed = DateTime.now();
  bool _refreshing = false;

  // Short wait so the admin can see the refresh happen (idea from Ong's page).
  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _refreshed = DateTime.now();
    });
  }

  // Sample counts per application status; they add up to the active total.
  static const _statuses = [
    ('Applied', 1420),
    ('Under review', 980),
    ('Shortlisted', 512),
    ('Interview', 301),
    ('Offer', 96),
    ('Hired', 74),
    ('Rejected', 88),
    ('Withdrawn', 20),
  ];

  String get _time {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(_refreshed.hour)}:${two(_refreshed.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final total = _statuses.fold<int>(0, (sum, s) => sum + s.$2);
    final most = _statuses.map((s) => s.$2).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: 'Admin dashboard',
          title: 'Everything running smoothly',
          subtitle: 'System overview and numbers at a glance. Last refreshed at $_time.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ServerStatusChip(),
              const SizedBox(width: 8),
              const GlassChip(label: 'Sample data'),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _refreshing ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 18),
                label: Text(_refreshing ? 'Refreshing…' : 'Refresh data'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.section),
        const _SectionTitle('Users per role'),
        const StatStrip(items: [
          StatItem('Total users', '12,845', 'All accounts'),
          StatItem('Job seekers', '10,240', '80% of users'),
          StatItem('Recruiters', '2,580', 'From verified companies'),
          StatItem('Admins', '25', 'Granted by the developer'),
        ]),
        const SizedBox(height: Gaps.block),
        _SectionTitle('System operations'),
        StatStrip(items: [
          const StatItem('Company reviews', '18', 'Waiting for checking'),
          const StatItem('Job reviews', '42', 'New posts to approve'),
          StatItem('Active applications', _format(total), 'Across all jobs'),
          const StatItem('API requests today', '842k', 'Within the daily limit'),
        ]),
        const SizedBox(height: Gaps.block),
        TwoPane(
          main: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader(title: 'Applications by status', trailing: 'All open jobs'),
                for (final (label, count) in _statuses)
                  _StatusRow(label: label, count: count, share: count / most, color: _statusColor(t, label)),
              ],
            ),
          ),
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Current AI model'),
                    const _Fact(label: 'Version', value: 'v2, linear SVM with TF-IDF'),
                    const _Fact(label: 'Deployed', value: '18 Oct 2026'),
                    _Fact(label: 'Status', badge: GlassChip(label: 'Online', color: t.success)),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.block),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Recent errors', trailing: 'Last 24 hours'),
                    _Fact(label: 'Critical errors', badge: GlassChip(label: '0', color: t.textSub)),
                    _Fact(label: 'Warnings', badge: GlassChip(label: '3', color: t.warning)),
                    _Fact(label: 'System health', badge: GlassChip(label: 'Good', color: t.success)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _format(int n) {
    final s = n.toString();
    return s.length > 3 ? '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}' : s;
  }

  // Green for good outcomes, amber while waiting, red for rejected, grey for the rest.
  static Color _statusColor(GlassTokens t, String status) => switch (status) {
    'Offer' || 'Hired' => t.success,
    'Shortlisted' || 'Interview' => t.accent,
    'Rejected' => t.danger,
    'Withdrawn' => t.textFaint,
    _ => t.warning,
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
    );
  }
}

/// One application status: name, a bar against the largest status, and the count.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.count, required this.share, required this.color});

  final String label;
  final int count;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 14, color: t.text))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: share, minHeight: 8, backgroundColor: t.row, color: color),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              _AdminOverviewPageState._format(count),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label with either a plain value or a small badge.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, this.value, this.badge});

  final String label;
  final String? value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: t.textSub))),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: badge ?? Text(value ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.text)),
            ),
          ),
        ],
      ),
    );
  }
}
