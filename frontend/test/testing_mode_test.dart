import 'package:careerbridge_ai/app/router.dart';
import 'package:careerbridge_ai/app/theme/glass_tokens.dart';
import 'package:careerbridge_ai/features/testing/analysis_result_view.dart';
import 'package:careerbridge_ai/features/testing/resume_analysis_page.dart';
import 'package:careerbridge_ai/features/testing/testing_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpers.dart';

const wide = Size(1440, 1000);

void main() {
  testWidgets('Testing mode opens the resume analysis page without login', (
    tester,
  ) async {
    final container = await pumpApp(tester, wide);
    container.read(routerProvider).go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('testing-mode')));
    await tester.pumpAndSettle();

    expect(find.text('Resume analysis'), findsWidgets); // page title and menu item
    expect(find.text('Choose resume (PDF, DOCX, JPG, PNG)'), findsOneWidget);
    expect(
      find.text('Test logbook (dev)'),
      findsOneWidget,
    ); // sidebar item, Developer group
  });

  testWidgets('an analysis shows the score, skills and directions', (
    tester,
  ) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [GlassTokens.night]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnalysisResultView(entry: sampleEntry()),
          ),
        ),
      ),
    );

    expect(find.text('82%, Strong Match'), findsOneWidget);
    expect(find.text('SQL'), findsOneWidget);
    expect(find.text('Tableau'), findsOneWidget);
    expect(find.text('Data Science'), findsWidgets);
    expect(find.textContaining('Not requested'), findsOneWidget);
  });

  Future<FakeTestingApi> pumpResult(
    WidgetTester tester, {
    VoidCallback? onTips,
    ValueChanged<Map<String, dynamic>>? onChanged,
    Map<String, dynamic>? entry,
  }) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final shown = entry ?? sampleEntryV2();
    final api = FakeTestingApi(entries: [shown]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [testingApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [GlassTokens.paper]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalysisResultView(
                entry: shown,
                onRequestAdvice: onTips,
                onEntryChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets(
    'a format 2 result opens on the score, next steps and the tips button',
    (tester) async {
      var asked = false;
      await pumpResult(tester, onTips: () => asked = true);

      expect(find.text('You are a good match'), findsOneWidget);
      expect(
        find.textContaining('Not counted'),
        findsOneWidget,
      ); // experience dates unreadable
      expect(
        find.text('Show Tableau on your resume'),
        findsOneWidget,
      ); // biggest gain first
      expect(find.text('Business Analyst'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('get-tips')));
      await tester.tap(find.byKey(const Key('get-tips')));
      expect(asked, isTrue);
    },
  );

  testWidgets('ticking a missing skill previews the new score', (tester) async {
    final api = await pumpResult(tester);
    await tester.tap(find.byKey(const Key('tab-skills')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skill-SQL')));
    await tester.pumpAndSettle();
    expect(
      find.text('Built SQL reports'),
      findsOneWidget,
    ); // where the skill was found
    await tester.ensureVisible(find.byKey(const Key('have-Tableau')));
    await tester.tap(find.byKey(const Key('have-Tableau')));
    await tester.pumpAndSettle();

    expect(api.whatIfCalls.single.skills, ['Tableau']);
    expect(find.text('Preview +6'), findsOneWidget);
    expect(find.text('80%', findRichText: true), findsOneWidget);
  });

  testWidgets('switching level and sending feedback', (tester) async {
    final api = await pumpResult(tester);
    await tester.tap(find.byKey(const Key('level-mid')));
    await tester.pumpAndSettle();
    expect(api.whatIfCalls.single.level, 'mid');

    await tester.ensureVisible(find.byKey(const Key('feedback-no')));
    await tester.tap(find.byKey(const Key('feedback-no')));
    await tester.pumpAndSettle();
    expect(api.feedbackSent, [false]);
    expect(find.textContaining('saved in the test logbook'), findsOneWidget);
  });

  testWidgets('the logbook lists past analyses and opens one', (tester) async {
    final container = await pumpApp(tester, wide);
    container.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('testing-mode')));
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/seeker/logbook');
    await tester.pumpAndSettle();

    expect(find.text('1 analyses'), findsOneWidget);
    await tester.tap(find.text('Data Analyst, junior'));
    await tester.pumpAndSettle();
    expect(find.text('82%, Strong Match'), findsOneWidget);
  });

  testWidgets('corrected details are saved and the new result is passed up', (
    tester,
  ) async {
    Map<String, dynamic>? updated;
    final api = await pumpResult(tester, onChanged: (e) => updated = e);
    await tester.tap(find.byKey(const Key('tab-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Check your details'), findsOneWidget);
    expect(find.byKey(const Key('tag-skills-SQL')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('add-skills')), 'Tableau');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();

    expect(api.savedProfiles.single['skills'], ['SQL', 'Tableau']);
    expect(api.savedProfiles.single['experience'][0]['end'], 'present');
    expect(updated?['assessment']['score'], 81);
    expect(find.text('Saved. Your score has been updated.'), findsOneWidget);
  });

  testWidgets('a wrongly written date is explained and not sent', (
    tester,
  ) async {
    final api = await pumpResult(tester, onChanged: (_) {});
    await tester.tap(find.byKey(const Key('tab-edit')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('job-0-start')), 'Jan 2023');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();

    expect(api.savedProfiles, isEmpty);
    expect(find.textContaining('Write dates like 2023-01'), findsOneWidget);
  });

  testWidgets('without a callback there is no edit tab', (tester) async {
    await pumpResult(tester);
    expect(find.byKey(const Key('tab-edit')), findsNothing);
  });

  testWidgets('old tips after an edit offer new tips', (tester) async {
    var asked = false;
    await pumpResult(
      tester,
      onTips: () => asked = true,
      entry: {
        ...sampleEntryV2(),
        'advice': {'summary': 'Nice work.'},
        'advice_stale': true,
      },
    );
    expect(find.textContaining('changed your details'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('refresh-tips')));
    await tester.tap(find.byKey(const Key('refresh-tips')));
    expect(asked, isTrue);
  });

  Future<void> pumpStatus(
    WidgetTester tester,
    Map<String, dynamic> task, {
    VoidCallback? onRetry,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [GlassTokens.paper]),
      home: Scaffold(
        body: TaskStatusCard(task: task, onRetry: onRetry),
      ),
    ),
  );

  testWidgets('task status shows the step while processing', (tester) async {
    await pumpStatus(tester, {
      'status': 'processing',
      'step': 'Reading the details with AI',
    });
    expect(find.text('Reading the details with AI…'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Failed'), findsNothing);
  });

  testWidgets('a failed task explains why and can be tried again', (
    tester,
  ) async {
    var retried = false;
    await pumpStatus(tester, {
      'status': 'failed',
      'error': 'This file type is not supported.',
    }, onRetry: () => retried = true);
    expect(find.text('We could not finish this analysis'), findsOneWidget);
    expect(find.text('This file type is not supported.'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('the analysis page shows AI requests left today', (tester) async {
    final container = await pumpApp(tester, wide);
    container.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('testing-mode')));
    await tester.pumpAndSettle();
    expect(find.text('AI requests left today: 27 of 30'), findsOneWidget);
  });
}
