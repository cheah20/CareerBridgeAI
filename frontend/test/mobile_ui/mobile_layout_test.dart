import 'package:careerbridge_ai/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

// Parked mobile fallback (lib/mobile_ui): keep it from breaking.
void main() {
  testWidgets('phone shows the bottom bar, and pages fit without overflow', (
    tester,
  ) async {
    final container = await pumpApp(tester, const Size(390, 844));
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('preview-seeker')));
    await tester.tap(find.byKey(const Key('preview-seeker')));
    await tester.pumpAndSettle();

    expect(find.text('Your career this week.'), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav')), findsOneWidget);

    // Every role's home must lay out cleanly on a phone (overflow fails the test).
    container.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    expect(
      find.text('Find the career your resume is ready for.'),
      findsOneWidget,
    );
  });
}
