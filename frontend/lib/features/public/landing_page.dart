import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/page_parts.dart';
import '../auth/session.dart';
import 'public_frame.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PublicFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const PageHeader(
            kicker: 'AI Resume and Career Recommendation System',
            title: 'Find the career your resume is ready for.',
            subtitle: 'Upload your resume to see suitable career directions, matching jobs, the skills to build next, '
                'and interview practice — explained in plain language.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(onPressed: () => context.go('/login'), child: const Text('Get started')),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 700 ? 1 : 3;
              final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final f in _features) SizedBox(width: width, child: _FeatureCard(feature: f)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const GlassCard(
            child: Text(
              'Recruiters: verify your company, publish jobs and review applicants with AI match results. '
              'Match scores are fit indicators, not hiring decisions.',
            ),
          ),
        ],
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
  _Feature(Icons.description_outlined, 'Resume analysis', 'PDF, DOCX or a photo of your resume becomes a clear profile you can correct.'),
  _Feature(Icons.work_outline, 'Job matching', 'See your match for each job, with matching skills, missing skills and why.'),
  _Feature(Icons.route_outlined, 'Grow your skills', 'Interview practice and a learning roadmap based on your target career.'),
];

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, color: t.accent),
          const SizedBox(height: 10),
          Text(feature.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: t.text)),
          const SizedBox(height: 4),
          Text(feature.text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
