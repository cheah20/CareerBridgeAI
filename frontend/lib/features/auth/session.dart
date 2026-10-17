import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_backend.dart';

/// The three roles in CareerBridge AI (matches `user_role` in the database).
enum UserRole {
  jobSeeker('Job seeker', 'seeker', 'job_seeker'),
  recruiter('Recruiter', 'recruiter', 'recruiter'),
  admin('Admin', 'admin', 'admin');

  const UserRole(this.label, this.pathSegment, this.apiValue);

  final String label;

  /// URL area for this role, e.g. `/seeker`.
  final String pathSegment;

  /// Value used by the database and the API.
  final String apiValue;

  String get homePath => '/$pathSegment';

  static UserRole fromApi(String value) => UserRole.values.firstWhere((r) => r.apiValue == value);
}

enum SessionStatus {
  /// Not logged in.
  guest,

  /// Logged in with Supabase; loading the role from the backend.
  loading,

  /// Logged in and the role is known.
  signedIn,
}

/// Who is using the app.
class Session {
  const Session({this.status = SessionStatus.guest, this.role, this.email, this.isPreview = false, this.error});

  const Session.guest({String? error}) : this(error: error);

  final SessionStatus status;
  final UserRole? role;
  final String? email;

  /// Why the last login could not be completed (shown on the login page).
  final String? error;

  /// Developer preview (debug builds only): a role without a real login.
  final bool isPreview;

  bool get isLoggedIn => status == SessionStatus.signedIn && role != null;

  String get displayName => isPreview ? 'Preview ${role?.label ?? ''}' : (email ?? role?.label ?? '');
}

/// Current session. Follows Supabase login state and asks the backend
/// (`GET /me`) for the user's role.
final sessionProvider = NotifierProvider<SessionNotifier, Session>(SessionNotifier.new);

class SessionNotifier extends Notifier<Session> {
  @override
  Session build() {
    final backend = ref.watch(authBackendProvider);
    final sub = backend.tokenChanges.listen(_onToken);
    ref.onDispose(sub.cancel);

    final token = backend.currentAccessToken;
    if (token == null) return const Session.guest();
    Future.microtask(() => _loadRole(token));
    return const Session(status: SessionStatus.loading);
  }

  void _onToken(String? token) {
    if (state.isPreview) return;
    if (token == null) {
      if (state.status != SessionStatus.guest) state = const Session.guest();
    } else if (state.status == SessionStatus.guest) {
      state = const Session(status: SessionStatus.loading);
      _loadRole(token);
    }
  }

  Future<void> _loadRole(String token) async {
    try {
      final me = await ref.read(profileApiProvider).fetchMe(token);
      state = Session(status: SessionStatus.signedIn, role: UserRole.fromApi(me.role), email: me.email);
    } on AuthFailure catch (e) {
      state = Session.guest(error: e.message);
      await ref.read(authBackendProvider).signOut();
    }
  }

  /// Logs in; throws [AuthFailure] with a user-friendly message.
  Future<void> signIn(String email, String password) async {
    await ref.read(authBackendProvider).signIn(email: email, password: password);
  }

  /// Creates an account. Returns true when the email must be confirmed first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) {
    assert(role != UserRole.admin, 'Admins are created by the developer, not by sign-up.');
    return ref.read(authBackendProvider).signUp(
          email: email,
          password: password,
          fullName: fullName,
          role: role.apiValue,
        );
  }

  Future<void> signOut() async {
    final wasPreview = state.isPreview;
    state = const Session.guest();
    if (!wasPreview) await ref.read(authBackendProvider).signOut();
  }

  /// Developer preview: open a role's layout without logging in (debug only).
  /// Backend calls are not authorised in this mode.
  void previewAs(UserRole role) {
    assert(kDebugMode, 'Developer preview is only available in debug builds.');
    state = Session(status: SessionStatus.signedIn, role: role, isPreview: true);
  }
}
