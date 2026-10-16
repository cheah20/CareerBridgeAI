import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three roles in CareerBridge AI (matches `user_role` in the database).
enum UserRole {
  jobSeeker('Job seeker', 'seeker'),
  recruiter('Recruiter', 'recruiter'),
  admin('Admin', 'admin');

  const UserRole(this.label, this.pathSegment);

  final String label;

  /// URL area for this role, e.g. `/seeker`.
  final String pathSegment;

  String get homePath => '/$pathSegment';
}

/// Who is using the app. `role == null` means a guest (not logged in).
class Session {
  const Session({this.role, this.displayName});

  const Session.guest() : this();

  final UserRole? role;
  final String? displayName;

  bool get isLoggedIn => role != null;
}

/// Current session.
///
/// Task 1.4 only has a developer preview: [signInAs] switches roles without a
/// real login so the layout can be checked. Task 1.5 replaces this with
/// Supabase Auth, where the role comes from `GET /me`.
final sessionProvider = NotifierProvider<SessionNotifier, Session>(SessionNotifier.new);

class SessionNotifier extends Notifier<Session> {
  @override
  Session build() => const Session.guest();

  void signInAs(UserRole role) => state = Session(role: role, displayName: 'Preview ${role.label}');

  void signOut() => state = const Session.guest();
}
