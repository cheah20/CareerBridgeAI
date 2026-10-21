import 'package:careerbridge_ai/app/router.dart';
import 'package:careerbridge_ai/features/auth/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_flow_test.dart'
    show accounts, desktop, logIn, recruiterEmail, roles, seekerEmail;
import 'fakes.dart';
import 'helpers.dart';

void main() {
  testWidgets('after login the home page checks its own area on the server', (
    tester,
  ) async {
    final home = FakeHomeApi();
    final container = await pumpApp(
      tester,
      desktop,
      auth: accounts(),
      profiles: roles,
      home: home,
    );
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();

    await logIn(tester, recruiterEmail, 'correct-password');

    expect(find.text('Server connected'), findsOneWidget);
    expect(home.calls, [UserRole.recruiter]);
  });

  testWidgets(
    'a server problem is shown on the home page, not a blank screen',
    (tester) async {
      final container = await pumpApp(
        tester,
        desktop,
        auth: accounts(),
        profiles: roles,
        home: FakeHomeApi(failWith: 'Cannot reach the CareerBridge server.'),
      );
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();

      await logIn(tester, seekerEmail, 'correct-password');

      expect(find.text('Your career this week.'), findsOneWidget);
      expect(find.text('Server offline · retry'), findsOneWidget);
    },
  );
}
