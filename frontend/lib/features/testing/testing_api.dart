import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/config.dart';

/// Testing mode API (backend `/testing/...`, only on this computer, no login).

class RoleOption {
  const RoleOption(this.id, this.title);
  final String id;
  final String title;
}

class FieldOption {
  const FieldOption(this.name, this.roles);
  final String name;
  final List<RoleOption> roles;
}

class Catalog {
  const Catalog(this.fields, this.levels);
  final List<FieldOption> fields;

  /// level id -> label, in order (entry ... lead).
  final Map<String, String> levels;
}

class TestingFailure implements Exception {
  const TestingFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class TestingApi {
  Future<Catalog> catalog();

  /// Full analysis; the returned map is the logbook entry.
  Future<Map<String, dynamic>> analyse({
    required Uint8List bytes,
    required String fileName,
    required String roleId,
    required String level,
    required bool useLlm,
  });

  Future<List<Map<String, dynamic>>> logbook();

  Future<Map<String, dynamic>> entry(String id);

  /// Ask the AI coach for tips on a saved analysis; returns {advice, advice_error}.
  Future<Map<String, dynamic>> advice(String id);

  /// Preview the score at another level or with extra skills (nothing is saved).
  Future<Map<String, dynamic>> whatIf(String id, {required String level, List<String> skills = const []});

  /// A thumbs up or down on part of the result, kept in the logbook.
  Future<void> feedback(String id, {required String section, required bool helpful});
}

final testingApiProvider = Provider<TestingApi>(
  (ref) => HttpTestingApi(AppConfig.apiBaseUrl),
);

final catalogProvider = FutureProvider<Catalog>(
  (ref) => ref.read(testingApiProvider).catalog(),
  retry: (_, _) => null,
);

final logbookProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(testingApiProvider).logbook(),
  retry: (_, _) => null,
);

class HttpTestingApi implements TestingApi {
  HttpTestingApi(this._baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$_baseUrl/testing$path');

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } catch (_) {
      throw const TestingFailure(
        'Cannot reach the CareerBridge server. Is the backend running with TESTING_MODE=true?',
      );
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body;
    if (response.statusCode == 404 &&
        response.request?.url.path.endsWith('/catalog') == true) {
      throw const TestingFailure(
        'Testing mode is off on the server. Set TESTING_MODE=true in ai_backend/.env.',
      );
    }
    throw TestingFailure(_message(body) ?? 'The server could not do this.');
  }

  static String? _message(dynamic body) {
    if (body is! Map) return null;
    final error = body['error'];
    return error is Map ? error['message'] as String? : null;
  }

  @override
  Future<Catalog> catalog() async {
    final body = await _send(
      () => _client.get(_uri('/catalog')),
    ) as Map<String, dynamic>;
    final fields = [
      for (final f in body['fields'] as List)
        FieldOption(f['field'] as String, [
          for (final r in f['roles'] as List)
            RoleOption(r['id'] as String, r['title'] as String),
        ]),
    ];
    final levels = {
      for (final l in body['levels'] as List)
        l['id'] as String: l['label'] as String,
    };
    return Catalog(fields, levels);
  }

  @override
  Future<Map<String, dynamic>> analyse({
    required Uint8List bytes,
    required String fileName,
    required String roleId,
    required String level,
    required bool useLlm,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/analyse'))
      ..fields.addAll({'role_id': roleId, 'level': level, 'use_llm': '$useLlm'})
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
    // OCR and the AI explanation can take a while.
    final body = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
      timeout: const Duration(seconds: 180),
    );
    return body as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> logbook() async {
    final body = await _send(() => _client.get(_uri('/logbook'))) as List;
    return body.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> advice(String id) async => await _send(
    () => _client.post(_uri('/logbook/$id/advice')),
    timeout: const Duration(seconds: 120),
  ) as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> whatIf(String id, {required String level, List<String> skills = const []}) async =>
      await _send(() => _client.post(_uri('/logbook/$id/whatif'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'level': level, 'skills': skills}))) as Map<String, dynamic>;

  @override
  Future<void> feedback(String id, {required String section, required bool helpful}) async {
    await _send(() => _client.post(_uri('/logbook/$id/feedback'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'section': section, 'helpful': helpful})));
  }

  @override
  Future<Map<String, dynamic>> entry(String id) async =>
      await _send(() => _client.get(_uri('/logbook/$id')))
          as Map<String, dynamic>;
}
