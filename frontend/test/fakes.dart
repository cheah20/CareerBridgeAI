import 'dart:async';
import 'dart:typed_data';

import 'package:careerbridge_ai/features/auth/auth_backend.dart';
import 'package:careerbridge_ai/features/auth/session.dart';
import 'package:careerbridge_ai/features/shell/server_status.dart';
import 'package:careerbridge_ai/features/testing/testing_api.dart';

/// In-memory stand-in for Supabase Auth.
class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({
    Map<String, String>? accounts,
    this.needsConfirmation = true,
    String? savedToken,
  }) : accounts = accounts ?? {},
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
    if (accounts[email] != password) {
      throw const AuthFailure('Email or password is incorrect.');
    }
    _token = 'token:$email';
    _changes.add(_token);
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
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

/// Stand-in for the role home endpoints (`GET /<role>/home`).
class FakeHomeApi implements HomeApi {
  FakeHomeApi({this.failWith});

  final String? failWith;
  final calls = <UserRole>[];

  @override
  Future<HomeInfo> fetchHome(String accessToken, UserRole role) async {
    calls.add(role);
    if (failWith != null) throw AuthFailure(failWith!);
    return HomeInfo(role: role.apiValue, area: role.label);
  }
}

/// Stand-in for the testing-mode API.
class FakeTestingApi implements TestingApi {
  FakeTestingApi({List<Map<String, dynamic>>? entries})
    : entries = entries ?? [sampleEntry()];

  final List<Map<String, dynamic>> entries;

  @override
  Future<Catalog> catalog() async => const Catalog(
    [
      FieldOption('Data & Artificial Intelligence', [
        RoleOption('data-analyst', 'Data Analyst'),
      ]),
    ],
    {'entry': 'Internship / Fresh Graduate', 'junior': 'Junior'},
  );

  /// What the fake task reports on each poll, then 'completed'.
  List<Map<String, dynamic>> taskSteps = [];
  final List<Map<String, dynamic>> savedProfiles = [];
  int taskPolls = 0;

  @override
  Future<Map<String, dynamic>> startAnalysis({
    required Uint8List bytes,
    required String fileName,
    required String roleId,
    required String level,
    required bool useLlm,
  }) async => {'id': 't1', 'status': 'pending', 'step': 'Waiting to start'};

  @override
  Future<Map<String, dynamic>> task(String id) async {
    taskPolls++;
    if (taskPolls <= taskSteps.length) return taskSteps[taskPolls - 1];
    return {'id': id, 'status': 'completed', 'entry': sampleEntry()};
  }

  @override
  Future<Map<String, dynamic>> saveProfile(
    String id,
    Map<String, dynamic> profile,
  ) async {
    savedProfiles.add(profile);
    final entry = entries.firstWhere((e) => e['id'] == id);
    return {
      ...entry,
      'profile': profile,
      'profile_edited_at': '2026-10-25T09:30:00+00:00',
      'assessment': {
        ...(entry['assessment'] as Map).cast<String, dynamic>(),
        'score': 81,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> usage() async => {
    'used_today': 3,
    'daily_limit': 30,
    'left_today': 27,
    'monthly_alert': false,
    'monthly_limited': false,
  };

  @override
  Future<List<Map<String, dynamic>>> logbook() async => [
    for (final e in entries)
      {
        'id': e['id'],
        'created_at': e['created_at'],
        'file_name': e['file']['name'],
        'role': e['role']['title'],
        'level': e['level'],
        'score': e['fit']['score'],
        'label': e['fit']['label'],
        'top_direction': 'Data Science',
        'with_advice': false,
      },
  ];

  @override
  Future<Map<String, dynamic>> entry(String id) async =>
      entries.firstWhere((e) => e['id'] == id);

  @override
  Future<Map<String, dynamic>> advice(String id) async => {
    'advice': {'summary': 'Great start.'},
    'advice_error': null,
  };

  final List<({String level, List<String> skills})> whatIfCalls = [];
  final List<bool> feedbackSent = [];

  @override
  Future<Map<String, dynamic>> whatIf(
    String id, {
    required String level,
    List<String> skills = const [],
  }) async {
    whatIfCalls.add((level: level, skills: skills));
    final base = (entries.firstWhere((e) => e['id'] == id)['assessment'] as Map)
        .cast<String, dynamic>();
    return {
      ...base,
      'score': (base['score'] as int) + 6 * skills.length,
      'level': level,
    };
  }

  @override
  Future<void> feedback(
    String id, {
    required String section,
    required bool helpful,
  }) async => feedbackSent.add(helpful);
}

Map<String, dynamic> sampleEntry() => {
  'id': '20261018-120000-abc123',
  'created_at': '2026-10-18T12:00:00+00:00',
  'file': {
    'name': 'aina.pdf',
    'kind': 'pdf',
    'method': 'pdf-text',
    'pages': 1,
    'ocr_pages': 0,
    'warnings': [],
    'words': 120,
  },
  'text': 'Aina Rahman - Data Analyst',
  'role': {
    'id': 'data-analyst',
    'title': 'Data Analyst',
    'field': 'Data & Artificial Intelligence',
  },
  'level': 'junior',
  'level_label': 'Junior',
  'fit': {
    'score': 82,
    'label': 'Strong Match',
    'parts': {'skills': 0.8, 'experience': 0.9, 'education': 1.0},
    'matched': [
      {'name': 'SQL', 'source': 'market'},
    ],
    'missing': [
      {'name': 'Tableau', 'source': 'tool'},
    ],
    'soft_skills': [],
    'years_estimate': 2.0,
    'notes': [],
  },
  'directions': {
    'model_version': 'v2',
    'items': [
      {'name': 'Data Science', 'label': 'Data Science', 'probability': 0.75},
    ],
  },
  'advice_requested': false,
  'advice': null,
  'advice_error': null,
  'timings': {'extract_ms': 40, 'fit_ms': 5, 'directions_ms': 20},
};

Map<String, dynamic> sampleEntryV2() => {
  'format': 2,
  'id': '20261018-130000-def456',
  'created_at': '2026-10-18T13:00:00+00:00',
  'file': {
    'name': 'aina.pdf',
    'kind': 'pdf',
    'method': 'pdf-text',
    'pages': 1,
    'ocr_pages': 0,
    'warnings': [],
    'words': 120,
  },
  'markdown': '## Experience\n- Data Analyst',
  'clean_markdown': '## Experience\n- Data Analyst',
  'profile': {
    'headline': 'Data Analyst',
    'skills': ['SQL'],
    'soft_skills': [],
    'experience': [
      {
        'title': 'Data Analyst',
        'organisation': 'Maybank',
        'start': '2023-01',
        'end': 'present',
        'type': 'full-time',
        'highlights': [],
      },
    ],
    'education': [
      {
        'level': 'Bachelor',
        'field': 'Statistics',
        'institution': 'UTeM',
        'end_year': 2022,
      },
    ],
    'certifications': [],
    'languages': ['English', 'Malay'],
    'uncertain': [],
  },
  'profile_error': null,
  'role': {
    'id': 'data-analyst',
    'title': 'Data Analyst',
    'field': 'Data & Artificial Intelligence',
  },
  'level': 'junior',
  'level_label': 'Junior',
  'assessment': {
    'score': 74,
    'label': 'Good Match',
    'basic_mode': false,
    'parts': {
      'skills': {
        'score': 0.7,
        'weight': 0.8,
        'reasons': ['You show 2 of 3 core skills.'],
      },
      'experience': {
        'score': null,
        'weight': 0,
        'reasons': ['We could not read the dates of your work history.'],
      },
      'education': {'score': 1.0, 'weight': 0.2, 'reasons': []},
    },
    'core_found': ['SQL', 'Excel'],
    'core_missing': ['Tableau'],
    'bonus_found': [],
    'bonus_missing': ['Python'],
    'soft_skills': [],
    'relevant_years': null,
    'total_years': null,
    'suggested_level': null,
    'notes': [],
    'skills_detail': [
      {
        'name': 'SQL',
        'core': true,
        'share': 58,
        'found': 'work',
        'evidence': {'where': 'Maybank', 'text': 'Built SQL reports'},
      },
      {
        'name': 'Excel',
        'core': true,
        'share': 40,
        'found': 'listed',
        'evidence': {'where': 'Skills', 'text': 'Excel'},
      },
      {
        'name': 'Tableau',
        'core': true,
        'share': 35,
        'found': null,
        'evidence': null,
        'gain': 6,
      },
      {
        'name': 'Python',
        'core': false,
        'share': 30,
        'found': null,
        'evidence': null,
        'gain': 3,
      },
    ],
  },
  'level_scores': {
    'entry': 80,
    'junior': 74,
    'mid': 60,
    'senior': 45,
    'lead': 40,
  },
  'related_roles': [
    {
      'id': 'business-analyst',
      'title': 'Business Analyst',
      'score': 68,
      'label': 'Good Match',
      'to_add': ['Requirements'],
    },
  ],
  'feedback': [],
  'directions': {
    'model_version': 'v2',
    'items': [
      {'name': 'Data Science', 'label': 'Data Science', 'probability': 0.75},
    ],
  },
  'advice_requested': false,
  'advice': null,
  'advice_error': null,
  'timings': {
    'read_ms': 40,
    'profile_ms': 2000,
    'score_ms': 5,
    'directions_ms': 20,
  },
};
