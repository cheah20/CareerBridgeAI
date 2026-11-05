import 'package:careerbridge_ai/app/theme/glass_tokens.dart';
import 'package:careerbridge_ai/features/recruiter/applicant_detail_page.dart';
import 'package:careerbridge_ai/features/recruiter/applicant_manage_page.dart';
import 'package:careerbridge_ai/features/recruiter/applicants_page.dart';
import 'package:careerbridge_ai/features/recruiter/company_profile_page.dart';
import 'package:careerbridge_ai/features/recruiter/job_form_page.dart';
import 'package:careerbridge_ai/features/recruiter/job_posts_page.dart';
import 'package:careerbridge_ai/features/recruiter/recruiter_sample.dart';
import 'package:careerbridge_ai/features/recruiter/recruiter_support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// opens one recruiter page with its own fresh sample data
Future<RecruiterSample> pumpAt(WidgetTester tester, String path) async {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = RecruiterSample();
  int id(GoRouterState st) => int.parse(st.pathParameters['id']!);
  Widget page(Widget child) => Scaffold(body: SingleChildScrollView(child: child));
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(
        path: '/recruiter/company',
        builder: (c, st) => page(CompanyProfilePage(store: s)),
      ),
      GoRoute(
        path: '/recruiter/jobs',
        builder: (c, st) => page(JobPostsPage(store: s)),
      ),
      GoRoute(
        path: '/recruiter/jobs/new',
        builder: (c, st) => page(JobFormPage(store: s)),
      ),
      GoRoute(
        path: '/recruiter/jobs/:id/edit',
        builder: (c, st) => page(JobFormPage(jobId: id(st), store: s)),
      ),
      GoRoute(
        path: '/recruiter/applicants',
        builder: (c, st) => page(ApplicantsPage(jobId: int.tryParse(st.uri.queryParameters['job'] ?? ''), store: s)),
      ),
      GoRoute(
        path: '/recruiter/applicants/:id',
        builder: (c, st) => page(ApplicantDetailPage(applicantId: id(st), store: s)),
      ),
      GoRoute(
        path: '/recruiter/applicants/:id/manage',
        builder: (c, st) => page(ApplicantManagePage(applicantId: id(st), store: s)),
      ),
      GoRoute(
        path: '/recruiter/support',
        builder: (c, st) => page(RecruiterSupportPage(store: s)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: ThemeData(extensions: const [GlassTokens.paper]),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return s;
}

void main() {
  testWidgets('applicants are sorted by match and can be filtered by skill', (tester) async {
    await pumpAt(tester, '/recruiter/applicants?job=1');
    expect(find.text('4 applicants'), findsOneWidget);
    final first = tester.getTopLeft(find.text('94%')).dy;
    expect(first, lessThan(tester.getTopLeft(find.text('55%')).dy));

    await tester.enterText(find.byKey(const Key('skill-filter')), 'php');
    await tester.pump();
    expect(find.text('1 applicant'), findsOneWidget);
    expect(find.text('Hafiz Example'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await tester.pump();
    expect(find.text('4 applicants'), findsOneWidget);
  });

  testWidgets('closing a job asks first', (tester) async {
    final s = await pumpAt(tester, '/recruiter/jobs');
    await tester.tap(find.widgetWithText(TextButton, 'Close').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('can no longer apply'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Close job'));
    await tester.pumpAndSettle();
    expect(s.job(1)!.status, JobStatus.closed);
  });

  testWidgets('submitting a job needs the required fields, a draft needs only a title', (tester) async {
    final s = await pumpAt(tester, '/recruiter/jobs/new');
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a job title.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('job-title')), 'Junior Data Analyst');
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    expect(find.text('Fill this in before submitting.'), findsNWidgets(3));
    expect(s.jobs.length, 4);

    await tester.tap(find.text('Save as draft'));
    await tester.pumpAndSettle();
    expect(s.jobs.first.title, 'Junior Data Analyst');
    expect(s.jobs.first.status, JobStatus.draft);
    expect(find.text('Job postings'), findsOneWidget);
  });

  testWidgets('changing status is saved and shown in the history', (tester) async {
    final s = await pumpAt(tester, '/recruiter/applicants/2/manage');
    await tester.tap(find.byType(DropdownButtonFormField<AppStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shortlisted').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update status'));
    await tester.pumpAndSettle();

    final a = s.applicant(2)!;
    expect(a.status, AppStatus.shortlisted);
    expect(a.history.last.status, 'Shortlisted');
    expect(find.text('Now: Shortlisted'), findsOneWidget);
  });

  testWidgets('an interview needs a date, time and place', (tester) async {
    final s = await pumpAt(tester, '/recruiter/applicants/3/manage');
    await tester.tap(find.text('Set interview'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a place or link.'), findsOneWidget);
    expect(s.applicant(3)!.interview, isNull);
  });

  testWidgets('a support report gets a reference number', (tester) async {
    final s = await pumpAt(tester, '/recruiter/support');
    await tester.enterText(find.byKey(const Key('report-subject')), 'Score looks wrong');
    await tester.enterText(find.byKey(const Key('report-message')), 'The missing skills list shows an optional skill.');
    await tester.tap(find.text('Send to Admin'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your reference is ${s.tickets.first.ref}'), findsOneWidget);
    expect(s.tickets.first.subject, 'Score looks wrong');
  });

  testWidgets('company profile edits are saved', (tester) async {
    final s = await pumpAt(tester, '/recruiter/company');
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('company-name')), 'Example Logistics Sdn Bhd');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(s.company.name, 'Example Logistics Sdn Bhd');
    expect(find.text('Edit profile'), findsOneWidget);
  });
}
