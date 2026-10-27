import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/config.dart';
import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../auth/auth_backend.dart';
import '../auth/session.dart';

/// Data from the role's home endpoint.
class HomeInfo {
  const HomeInfo({required this.role, required this.area});

  final String role;
  final String area;
}

abstract class HomeApi {
  Future<HomeInfo> fetchHome(String accessToken, UserRole role);
}

final homeApiProvider = Provider<HomeApi>((ref) => HttpHomeApi(AppConfig.apiBaseUrl));

class HttpHomeApi implements HomeApi {
  HttpHomeApi(this._baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<HomeInfo> fetchHome(String accessToken, UserRole role) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/${role.pathSegment}/home'), headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthFailure('Cannot reach the CareerBridge server.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final error = body['error'] as Map<String, dynamic>?;
      throw AuthFailure(error?['message'] as String? ?? 'The server refused this request.');
    }
    return HomeInfo(role: body['role'] as String, area: body['area'] as String);
  }
}

/// Checks the signed-in user's own home endpoint.
final serverCheckProvider = FutureProvider.autoDispose<HomeInfo?>((ref) async {
  final session = ref.watch(sessionProvider);
  final role = session.role;
  if (!session.isLoggedIn || session.isPreview || role == null) return null;
  final token = ref.read(authBackendProvider).currentAccessToken;
  if (token == null) return null;
  return ref.read(homeApiProvider).fetchHome(token, role);
  // No automatic retry: show the problem at once; the user taps the chip to try again.
}, retry: (_, _) => null);

/// Small header chip: is this role's area connected to the backend?
class ServerStatusChip extends ConsumerWidget {
  const ServerStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GlassTokens.of(context);
    final session = ref.watch(sessionProvider);
    if (!session.isLoggedIn || session.isPreview) return const SizedBox.shrink(); // nothing to check
    final chip = ref.watch(serverCheckProvider).when(
          data: (info) => info == null
              ? const SizedBox.shrink() // guest or developer preview: nothing to check
              : GlassChip(label: 'Server connected', color: t.success),
          loading: () => const GlassChip(label: 'Checking server…'),
          error: (error, _) => Tooltip(
            message: '$error Tap to try again.',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => ref.invalidate(serverCheckProvider),
              child: GlassChip(label: 'Server offline, retry', color: t.danger),
            ),
          ),
        );
    return Padding(padding: const EdgeInsets.only(right: 8), child: chip);
  }
}
