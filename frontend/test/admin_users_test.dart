import 'package:careerbridge_ai/app/theme/glass_tokens.dart';
import 'package:careerbridge_ai/features/admin/admin_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUsers(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [GlassTokens.paper]),
      home: const Scaffold(
        body: SingleChildScrollView(child: AdminUsersPage()),
      ),
    ),
  );
}

void main() {
  testWidgets('search narrows the user list', (tester) async {
    await pumpUsers(tester);
    expect(find.text('Showing 1–20 of 240'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('user-search')), 'priya');
    await tester.pump();
    expect(find.text('Showing 1–20 of 20'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('user-search')), 'nobody here');
    await tester.pump();
    expect(
      find.text('No accounts match. Try a shorter search or another role.'),
      findsOneWidget,
    );
  });

  testWidgets('disabling an account asks first', (tester) async {
    await pumpUsers(tester);
    final before = find.text('Disabled').evaluate().length;

    await tester.tap(find.widgetWithText(TextButton, 'Disable').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('will not be able to log in'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Disabled').evaluate().length, before);

    await tester.tap(find.widgetWithText(TextButton, 'Disable').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Disable'));
    await tester.pumpAndSettle();
    expect(find.text('Disabled').evaluate().length, before + 1);
  });
}
