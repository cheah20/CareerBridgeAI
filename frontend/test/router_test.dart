import 'package:careerbridge_ai/app/router.dart';
import 'package:careerbridge_ai/features/auth/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guest = Session.guest();
  const loading = Session(status: SessionStatus.loading);
  const seeker = Session(
    status: SessionStatus.signedIn,
    role: UserRole.jobSeeker,
  );
  const recruiter = Session(
    status: SessionStatus.signedIn,
    role: UserRole.recruiter,
  );
  const admin = Session(status: SessionStatus.signedIn, role: UserRole.admin);

  String? go(Session s, String location) => redirectFor(s, Uri.parse(location));

  group('guests', () {
    test('can open public pages', () {
      for (final path in ['/', '/jobs', '/login', '/signup']) {
        expect(go(guest, path), isNull, reason: path);
      }
    });

    test('are sent to login, remembering the requested page', () {
      expect(go(guest, '/seeker/resume'), '/login?from=%2Fseeker%2Fresume');
      expect(go(guest, '/admin'), '/login?from=%2Fadmin');
    });

    test('leave the loading page when the login did not complete', () {
      expect(
        go(guest, '/loading?from=%2Fseeker%2Fjobs'),
        '/login?from=%2Fseeker%2Fjobs',
      );
    });
  });

  group('while the role is loading', () {
    test('everything waits on /loading, keeping the target', () {
      expect(go(loading, '/loading'), isNull);
      expect(
        go(loading, '/login?from=%2Fseeker%2Fjobs'),
        '/loading?from=%2Fseeker%2Fjobs',
      );
      expect(go(loading, '/login'), '/loading');
    });
  });

  group('signed-in users', () {
    test('skip login, sign-up and loading pages', () {
      expect(go(seeker, '/login'), '/seeker');
      expect(go(admin, '/signup'), '/admin');
      expect(go(recruiter, '/loading'), '/recruiter');
    });

    test('return to the page they asked for, if it is in their area', () {
      expect(go(seeker, '/loading?from=%2Fseeker%2Fjobs'), '/seeker/jobs');
      expect(go(seeker, '/loading?from=%2Fadmin%2Fusers'), '/seeker');
    });

    test('stay inside their own role area', () {
      expect(go(seeker, '/seeker/jobs'), isNull);
      expect(go(seeker, '/admin'), '/seeker');
      expect(go(seeker, '/recruiter/applicants'), '/seeker');
      expect(go(recruiter, '/admin/users'), '/recruiter');
      expect(go(admin, '/seeker'), '/admin');
    });

    test('a look-alike path is not treated as their area', () {
      expect(go(admin, '/administrator'), '/admin');
    });
  });
}
