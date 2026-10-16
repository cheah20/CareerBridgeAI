import 'package:careerbridge_ai/app/router.dart';
import 'package:careerbridge_ai/features/auth/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guest = Session.guest();
  const seeker = Session(role: UserRole.jobSeeker);
  const recruiter = Session(role: UserRole.recruiter);
  const admin = Session(role: UserRole.admin);

  String? go(Session s, String location) => redirectFor(s, Uri.parse(location));

  group('guests', () {
    test('can open public pages', () {
      expect(go(guest, '/'), isNull);
      expect(go(guest, '/jobs'), isNull);
      expect(go(guest, '/login'), isNull);
    });

    test('are sent to login, remembering the requested page', () {
      expect(go(guest, '/seeker/resume'), '/login?from=%2Fseeker%2Fresume');
      expect(go(guest, '/admin'), '/login?from=%2Fadmin');
    });
  });

  group('signed-in users', () {
    test('skip the login page', () {
      expect(go(seeker, '/login'), '/seeker');
      expect(go(admin, '/login'), '/admin');
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
