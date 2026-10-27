import 'package:careerbridge_ai/app/router.dart';
import 'package:careerbridge_ai/features/auth/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'helpers.dart';

const desktop = Size(1280, 900);
const seekerEmail = 'seeker@example.test';
const recruiterEmail = 'hr@example.test';

FakeAuthBackend accounts({bool needsConfirmation = true, String? savedToken}) =>
    FakeAuthBackend(
      accounts: {
        seekerEmail: 'correct-password',
        recruiterEmail: 'correct-password',
      },
      needsConfirmation: needsConfirmation,
      savedToken: savedToken,
    );

final roles = FakeProfileApi({
  seekerEmail: 'job_seeker',
  recruiterEmail: 'recruiter',
});

Future<void> logIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.ensureVisible(find.byKey(const Key('login-submit')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('logging in takes each role to its own home', (tester) async {
    final container = await pumpApp(
      tester,
      desktop,
      auth: accounts(),
      profiles: roles,
    );
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();

    await logIn(tester, recruiterEmail, 'correct-password');

    expect(find.text('Hiring at a glance'), findsOneWidget);
    expect(container.read(sessionProvider).role, UserRole.recruiter);
  });

  testWidgets('after login the user returns to the page they asked for', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      desktop,
      auth: accounts(),
      profiles: roles,
    );
    container.read(routerProvider).go('/seeker/applications');
    await tester.pumpAndSettle();
    expect(find.text('Log in to CareerBridge'), findsOneWidget);

    await logIn(tester, seekerEmail, 'correct-password');

    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      '/seeker/applications',
    );
  });

  testWidgets('a wrong password shows a clear message and stays on login', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      desktop,
      auth: accounts(),
      profiles: roles,
    );
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();

    await logIn(tester, seekerEmail, 'wrong');

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(container.read(sessionProvider).isLoggedIn, isFalse);
  });

  testWidgets(
    'if the server cannot load the account, the user is logged out with a message',
    (tester) async {
      final container = await pumpApp(
        tester,
        desktop,
        auth: accounts(),
        profiles: FakeProfileApi(
          {},
          failWith: 'Cannot reach the CareerBridge server. Please try again in a moment.',
        ),
      );
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();

      await logIn(tester, seekerEmail, 'correct-password');

      expect(
        find.text(
          'Cannot reach the CareerBridge server. Please try again in a moment.',
        ),
        findsOneWidget,
      );
      expect(container.read(sessionProvider).isLoggedIn, isFalse);
    },
  );

  testWidgets('a saved login is restored when the app opens', (tester) async {
    final container = await pumpApp(
      tester,
      desktop,
      auth: accounts(savedToken: 'token:$seekerEmail'),
      profiles: roles,
    );

    expect(container.read(sessionProvider).role, UserRole.jobSeeker);
    expect(find.text('Your career this week'), findsOneWidget);
  });

  testWidgets('sign-up sends the chosen role and asks to confirm the email', (
    tester,
  ) async {
    final auth = accounts();
    final container = await pumpApp(
      tester,
      desktop,
      auth: auth,
      profiles: roles,
    );
    container.read(routerProvider).go('/signup');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recruiter'));
    await tester.enterText(find.byKey(const Key('signup-name')), 'Nur Aisyah');
    await tester.enterText(
      find.byKey(const Key('signup-email')),
      'new@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password')),
      'long-enough-1',
    );
    await tester.enterText(
      find.byKey(const Key('signup-confirm')),
      'long-enough-1',
    );
    await tester.ensureVisible(find.byKey(const Key('signup-submit')));
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();

    expect(auth.signUps.single, {
      'email': 'new@example.test',
      'fullName': 'Nur Aisyah',
      'role': 'recruiter',
    });
    expect(find.text('Check your inbox'), findsOneWidget);
  });

  testWidgets('sign-up checks the form before sending anything', (
    tester,
  ) async {
    final auth = accounts();
    final container = await pumpApp(
      tester,
      desktop,
      auth: auth,
      profiles: roles,
    );
    container.read(routerProvider).go('/signup');
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signup-name')), 'Ali');
    await tester.enterText(
      find.byKey(const Key('signup-email')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const Key('signup-password')), 'short');
    await tester.enterText(
      find.byKey(const Key('signup-confirm')),
      'different',
    );
    await tester.ensureVisible(find.byKey(const Key('signup-submit')));
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.signUps, isEmpty);
  });

  testWidgets('signing out returns to the landing page', (tester) async {
    final container = await pumpApp(
      tester,
      desktop,
      auth: accounts(savedToken: 'token:$seekerEmail'),
      profiles: roles,
    );
    expect(find.text('Your career this week'), findsOneWidget);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider).isLoggedIn, isFalse);
    expect(
      find.text('Find the career your resume is ready for'),
      findsOneWidget,
    );
  });
}
