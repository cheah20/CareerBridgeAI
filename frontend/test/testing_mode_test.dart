import 'package:careerbridge_ai/app/router.dart';
import 'package:careerbridge_ai/app/theme/glass_tokens.dart';
import 'package:careerbridge_ai/features/testing/analysis_result_view.dart';
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

    expect(find.text('Resume analysis.'), findsOneWidget);
    expect(find.text('Choose resume (PDF, DOCX, JPG, PNG)'), findsOneWidget);
    expect(find.text('Test logbook (dev)'), findsOneWidget); // sidebar item, Developer group
  });

  testWidgets('an analysis shows the score, skills and directions', (
    tester,
  ) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [GlassTokens.smoke]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnalysisResultView(entry: sampleEntry()),
          ),
        ),
      ),
    );

    expect(find.text('82% · Strong Match'), findsOneWidget);
    expect(find.text('SQL'), findsOneWidget);
    expect(find.text('Tableau'), findsOneWidget);
    expect(find.text('Data Science'), findsWidgets);
    expect(find.textContaining('Not requested'), findsOneWidget);
  });

  Future<FakeTestingApi> pumpResult(
    WidgetTester tester, {
    VoidCallback? onTips,
  }) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeTestingApi(entries: [sampleEntryV2()]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [testingApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [GlassTokens.paper]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalysisResultView(
                entry: sampleEntryV2(),
                onRequestAdvice: onTips,
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
    await tester.tap(find.text('Data Analyst · junior'));
    await tester.pumpAndSettle();
    expect(find.text('82% · Strong Match'), findsOneWidget);
  });
}
