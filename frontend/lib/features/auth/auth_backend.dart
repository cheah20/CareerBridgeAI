import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../app/config.dart';

/// Login/sign-up operations. An interface so tests can use a fake instead of
/// the real Supabase project.
abstract class AuthBackend {
  /// Access token of the current login, or null when logged out.
  String? get currentAccessToken;

  /// Emits the new access token on login / token refresh, and null on logout.
  Stream<String?> get tokenChanges;

  Future<void> signIn({required String email, required String password});

  /// Returns true when the account must confirm its email before logging in.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  });

  Future<void> signOut();
}

/// Profile data from the backend (`GET /me`).
class Me {
  const Me({required this.id, required this.email, required this.role});

  final String id;
  final String? email;

  /// `job_seeker`, `recruiter` or `admin`.
  final String role;
}

abstract class ProfileApi {
  Future<Me> fetchMe(String accessToken);
}

/// A failure the user should see, with a plain-language message.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final authBackendProvider = Provider<AuthBackend>(
  (ref) => AppConfig.isComplete ? SupabaseAuthBackend(sb.Supabase.instance.client) : const UnconfiguredAuthBackend(),
);

/// Used when the app was started without config/dev.json: the UI still works,
/// and login explains what is missing.
class UnconfiguredAuthBackend implements AuthBackend {
  const UnconfiguredAuthBackend();

  static const _failure = AuthFailure(
    'Login is not configured. Start the app with --dart-define-from-file=config/dev.json.',
  );

  @override
  String? get currentAccessToken => null;

  @override
  Stream<String?> get tokenChanges => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) => Future.error(_failure);

  @override
  Future<bool> signUp({required String email, required String password, required String fullName, required String role}) =>
      Future.error(_failure);

  @override
  Future<void> signOut() async {}
}
final profileApiProvider = Provider<ProfileApi>((ref) => HttpProfileApi(AppConfig.apiBaseUrl));

class SupabaseAuthBackend implements AuthBackend {
  SupabaseAuthBackend(this._client);

  final sb.SupabaseClient _client;

  @override
  String? get currentAccessToken => _client.auth.currentSession?.accessToken;

  @override
  Stream<String?> get tokenChanges => _client.auth.onAuthStateChange.map((state) => state.session?.accessToken);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on sb.AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Read by the database sign-up trigger; "admin" is never accepted there.
        data: {'full_name': fullName, 'role': role},
        emailRedirectTo: Uri.base.origin,
      );
      return response.session == null;
    } on sb.AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  static String _friendly(sb.AuthException e) => switch (e.code) {
    'invalid_credentials' => 'Email or password is incorrect.',
    'email_not_confirmed' => 'Please confirm your email first. Check your inbox for the link.',
    'user_already_exists' || 'email_exists' => 'An account with this email already exists. Try logging in.',
    'weak_password' => 'Choose a stronger password (at least 8 characters).',
    'over_email_send_rate_limit' || 'over_request_rate_limit' => 'Too many attempts. Please wait a few minutes and try again.',
    _ => e.message,
  };
}

class HttpProfileApi implements ProfileApi {
  HttpProfileApi(this._baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<Me> fetchMe(String accessToken) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/me'), headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthFailure('Cannot reach the CareerBridge server. Please try again in a moment.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final error = body['error'] as Map<String, dynamic>?;
      throw AuthFailure(error?['message'] as String? ?? 'Could not load your account.');
    }
    return Me(id: body['id'] as String, email: body['email'] as String?, role: body['role'] as String);
  }
}
