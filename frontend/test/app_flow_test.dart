import 'package:careerbridge_ai/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('guest opening a role page lands on login, then the preview opens that page', (tester) async {
    final container = await pumpApp(tester, const Size(1280, 860));

    container.read(routerProvider).go('/seeker/resume');
    await tester.pumpAndSettle();
    expect(find.text('Log in to CareerBridge.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('preview-seeker')));
    await tester.tap(find.byKey(const Key('preview-seeker')));
    await tester.pumpAndSettle();
    expect(find.text('Coming in Phase 2'.toUpperCase()), findsOneWidget);
    expect(find.text('Resume profile'), findsWidgets);
  });

  testWidgets('desktop shows the sidebar, not the bottom bar', (tester) async {
    final container = await pumpApp(tester, const Size(1280, 860));
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('preview-recruiter')));
    await tester.tap(find.byKey(const Key('preview-recruiter')));
    await tester.pumpAndSettle();

    expect(find.text('Hiring at a glance.'), findsOneWidget);
    expect(find.text('Company profile'), findsOneWidget); // sidebar entry
    expect(find.byKey(const Key('bottom-nav')), findsNothing);
  });

  testWidgets('theme toggle switches between smoke and ice glass', (tester) async {
    final container = await pumpApp(tester, const Size(1280, 860));
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('preview-admin')));
    await tester.tap(find.byKey(const Key('preview-admin')));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('Everything running smoothly.'))).brightness, Brightness.dark);
    await tester.tap(find.byTooltip('Switch to light glass'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Everything running smoothly.'))).brightness, Brightness.light);
  });
}
