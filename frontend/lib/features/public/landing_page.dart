import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../auth/session.dart';
import 'public_frame.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = GlassTokens.of(context);

    final hero = GlassPanel(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find the career your resume is ready for',
            style: theme.textTheme.displaySmall?.copyWith(color: t.text, fontSize: 42, height: 1.08, letterSpacing: -1),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Upload your resume and see which jobs fit you today, what to learn next, '
              'and how to prepare for the interview. Everything is explained in plain language.',
              style: theme.textTheme.bodyLarge?.copyWith(color: t.textSub, fontSize: 17),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(onPressed: () => context.go('/login'), child: const Text('Check my resume')),
              OutlinedButton(onPressed: () => context.go('/jobs'), child: const Text('Browse jobs')),
              if (kDebugMode)
                OutlinedButton.icon(
                  key: const Key('testing-mode'),
                  icon: const Icon(Icons.science_outlined, size: 18),
                  onPressed: () {
                    // Testing mode: the Job Seeker area without login; results go to the local logbook.
                    ref.read(sessionProvider.notifier).previewAs(UserRole.jobSeeker);
                    context.go('/seeker/analyse');
                  },
                  label: const Text('Testing mode'),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: t.cardEdge),
          const SizedBox(height: 20),
          for (final f in _features) _FeatureRow(feature: f),
        ],
      ),
    );

    return PublicFrame(
      panel: false,
      centerContent: true,
      maxWidth: 1240,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 980) {
            return Column(children: [hero, const SizedBox(height: 20), const _SampleResult()]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 7, child: hero),
              const SizedBox(width: 24),
              const Expanded(flex: 5, child: _SampleResult()),
            ],
          );
        },
      ),
    );
  }
}

class _Feature {
  const _Feature(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

const _features = [
  _Feature(Icons.description_outlined, 'Your resume, read for you', 'PDF, Word or a photo. You can fix anything we read wrong.'),
  _Feature(Icons.work_outline, 'Jobs that fit', 'Your match for each job, with the skills you have and the ones you are missing.'),
  _Feature(Icons.route_outlined, 'What to do next', 'Interview practice and a learning plan for the job you want.'),
];

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, size: 22, color: t.success),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${feature.title}. ', style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                TextSpan(text: feature.text, style: TextStyle(color: t.textSub)),
              ]),
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// A made-up result, so visitors see what they get before signing up.
class _SampleResult extends StatelessWidget {
  const _SampleResult();

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    Widget chip(String s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: t.successSoft, borderRadius: BorderRadius.circular(6)),
      child: Text('✓ $s', style: TextStyle(fontSize: 14, color: t.success)),
    );
    return GlassPanel(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Example result', style: TextStyle(fontSize: 13, color: t.textFaint)),
          const SizedBox(height: 2),
          Text('Junior Web Developer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.text)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('57', style: TextStyle(fontSize: 64, height: 1, fontWeight: FontWeight.w700, color: t.text, letterSpacing: -2)),
              Text('%', style: TextStyle(fontSize: 24, color: t.textFaint)),
              const SizedBox(width: 12),
              Flexible(child: Text('Partial match', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.success))),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: 0.57, minHeight: 8, color: t.ink, backgroundColor: t.row),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 6, runSpacing: 6, children: [chip('HTML'), chip('JavaScript'), chip('Python')]),
          const SizedBox(height: 16),
          Divider(color: t.cardEdge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Learn next: SQL', style: TextStyle(fontSize: 15, color: t.text))),
              Text('+6 points', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.warning)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Asked for in 58% of web developer ads', style: TextStyle(fontSize: 13, color: t.textSub)),
        ],
      ),
    );
  }
}
