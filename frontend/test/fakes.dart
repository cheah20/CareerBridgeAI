import 'dart:async';

import 'package:careerbridge_ai/features/auth/auth_backend.dart';

/// In-memory stand-in for Supabase Auth.
class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({Map<String, String>? accounts, this.needsConfirmation = true, String? savedToken})
      : accounts = accounts ?? {},
        _token = savedToken;

  /// email -> password of confirmed accounts.
  final Map<String, String> accounts;
  final bool needsConfirmation;
  final signUps = <Map<String, String>>[];

  final _changes = StreamController<String?>.broadcast();
  String? _token;

  @override
  String? get currentAccessToken => _token;

  @override
  Stream<String?> get tokenChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email] != password) throw const AuthFailure('Email or password is incorrect.');
    _token = 'token:$email';
    _changes.add(_token);
  }

  @override
  Future<bool> signUp({required String email, required String password, required String fullName, required String role}) async {
    signUps.add({'email': email, 'fullName': fullName, 'role': role});
    return needsConfirmation;
  }

  @override
  Future<void> signOut() async {
    _token = null;
    _changes.add(null);
  }
}

/// Stand-in for `GET /me`: token `token:<email>` -> role.
class FakeProfileApi implements ProfileApi {
  FakeProfileApi(this.rolesByEmail, {this.failWith});

  final Map<String, String> rolesByEmail;
  final String? failWith;

  @override
  Future<Me> fetchMe(String accessToken) async {
    if (failWith != null) throw AuthFailure(failWith!);
    final email = accessToken.replaceFirst('token:', '');
    final role = rolesByEmail[email];
    if (role == null) throw const AuthFailure('User profile not found.');
    return Me(id: 'id-$email', email: email, role: role);
  }
}
