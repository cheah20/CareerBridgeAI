import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

// made-up recruiter data until phases 4–5

enum JobStatus {
  draft('Draft'),
  review('Waiting review'),
  open('Open'),
  closed('Closed');

  const JobStatus(this.label);
  final String label;

  Color color(GlassTokens t) => switch (this) {
    JobStatus.open => t.success,
    JobStatus.review => t.warning,
    JobStatus.closed => t.danger,
    JobStatus.draft => t.textSub,
  };
}

enum AppStatus {
  applied('Applied'),
  underReview('Under review'),
  shortlisted('Shortlisted'),
  interview('Interview'),
  offer('Offer'),
  hired('Hired'),
  rejected('Rejected');

  const AppStatus(this.label);
  final String label;

  Color color(GlassTokens t) => switch (this) {
    AppStatus.shortlisted || AppStatus.interview || AppStatus.offer || AppStatus.hired => t.success,
    AppStatus.rejected => t.danger,
    _ => t.textSub,
  };
}

enum MatchLevel {
  strong('Strong'),
  moderate('Moderate'),
  low('Low');

  const MatchLevel(this.label);
  final String label;

  static MatchLevel of(int match) => match >= 80 ? strong : (match >= 60 ? moderate : low);

  Color color(GlassTokens t) => switch (this) {
    MatchLevel.strong => t.success,
    MatchLevel.moderate => t.warning,
    MatchLevel.low => t.danger,
  };
}

const experienceLevels = ['Fresh graduate', 'Junior (1–2 years)', 'Mid level (3–5 years)', 'Senior (5+ years)'];
const educationLevels = ['Diploma', "Bachelor's degree", "Master's degree", 'No degree required'];
const workModes = ['On-site', 'Hybrid', 'Remote'];
const workTypes = ['Full-time', 'Part-time', 'Contract', 'Internship'];

class Job {
  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.skills,
    required this.experience,
    required this.education,
    required this.workMode,
    required this.workType,
    required this.location,
    required this.vacancies,
    required this.salary,
    required this.closing,
    required this.status,
  });

  final int id;
  String title;
  String description;
  List<String> skills;
  String experience;
  String education;
  String workMode;
  String workType;
  String location;
  int vacancies;
  String salary;
  DateTime? closing;
  JobStatus status;
}

class StatusChange {
  const StatusChange(this.date, this.status, this.by);

  final DateTime date;
  final String status;
  final String by;
}

class Interview {
  const Interview(this.when, this.place, this.notes);

  final DateTime when;
  final String place;
  final String notes;
}

class ResumeSection {
  const ResumeSection(this.heading, this.lines);

  final String heading;
  final List<String> lines;
}

class Applicant {
  Applicant({
    required this.id,
    required this.jobId,
    required this.name,
    required this.match,
    required this.skills,
    required this.education,
    required this.educationLevel,
    required this.experience,
    required this.experienceLevel,
    required this.status,
    required this.matched,
    required this.missing,
    required this.summary,
    required this.resume,
    required this.history,
    this.interview,
  });

  final int id;
  final int jobId;
  final String name;
  final int match;
  final String skills;
  final String education;
  final String educationLevel;
  final String experience;
  final String experienceLevel;
  AppStatus status;
  final List<String> matched;
  final List<String> missing;
  final String summary;
  final List<ResumeSection> resume;
  final List<StatusChange> history;
  Interview? interview;

  String get initials => name.split(' ').take(2).map((w) => w[0]).join();
  MatchLevel get level => MatchLevel.of(match);
}

class Company {
  Company({
    required this.name,
    required this.industry,
    required this.size,
    required this.address,
    required this.website,
    required this.email,
    required this.about,
    required this.culture,
    required this.vision,
    required this.workArrangement,
    required this.benefits,
  });

  String name;
  String industry;
  String size;
  String address;
  String website;
  String email;
  String about;
  String culture;
  String vision;
  String workArrangement;
  String? logo;
  String? photos;
  Set<String> benefits;
  final bool verified = true;
  final verifiedOn = DateTime(2026, 10, 14);
}

class Ticket {
  const Ticket(this.ref, this.subject, this.status, this.date);

  final String ref;
  final String subject;
  final String status;
  final DateTime date;
}

const industries = [
  'Information technology and services',
  'Financial services',
  'Telecommunications',
  'Manufacturing',
  'Logistics',
];
const companySizes = ['1–50 employees', '51–200 employees', '201–500 employees', '500+ employees'];
const workArrangements = ['On-site', 'Hybrid', 'Fully remote', 'Flexible hours'];
const allBenefits = ['Medical and dental', 'Parking allowance', 'Performance bonus', 'Training sponsorship'];

// one shared copy so every page sees the same changes
class RecruiterSample extends ChangeNotifier {
  final company = Company(
    name: 'Zenith Global Solutions Sdn Bhd',
    industry: industries.first,
    size: companySizes[1],
    address: 'Level 14, Tower A, Bangsar South, 59200 Kuala Lumpur',
    website: 'https://www.zenithsolutions.example.my',
    email: 'recruitment@zenithsolutions.example.my',
    about:
        'Zenith Global Solutions builds AI and cloud tools for businesses across Southeast Asia. '
        'We work hybrid, sponsor technical certificates and cover medical care.',
    culture: 'Collaborative and fast-paced, with steady learning and clear career steps.',
    vision: 'Make everyday business work simpler with responsible AI.',
    workArrangement: workArrangements[1],
    benefits: {...allBenefits},
  );

  final jobs = <Job>[
    Job(
      id: 1,
      title: 'Junior Mobile App Developer',
      description:
          'Build cross-platform apps with Flutter and Dart. Work with the backend team, use REST APIs '
          'and deliver friendly, readable screens.',
      skills: ['Flutter', 'Dart', 'REST API', 'Git', 'Firebase'],
      experience: experienceLevels[1],
      education: educationLevels[1],
      workMode: 'Hybrid',
      workType: 'Full-time',
      location: 'Kuala Lumpur',
      vacancies: 2,
      salary: '3,500 – 4,800',
      closing: DateTime(2026, 11, 30),
      status: JobStatus.open,
    ),
    Job(
      id: 2,
      title: 'Backend Engineer (Python)',
      description: 'Design and run Python services and databases for our client platforms.',
      skills: ['Python', 'FastAPI', 'PostgreSQL', 'Docker'],
      experience: experienceLevels[1],
      education: educationLevels[1],
      workMode: 'Remote',
      workType: 'Full-time',
      location: 'Kuala Lumpur',
      vacancies: 1,
      salary: '4,500 – 6,000',
      closing: DateTime(2026, 12, 15),
      status: JobStatus.review,
    ),
    Job(
      id: 3,
      title: 'Data Analyst Intern',
      description: 'Help the analytics team clean data and build weekly reports.',
      skills: ['Excel', 'SQL', 'Power BI'],
      experience: experienceLevels[0],
      education: educationLevels[0],
      workMode: 'On-site',
      workType: 'Internship',
      location: 'Bangsar South',
      vacancies: 1,
      salary: '',
      closing: null,
      status: JobStatus.draft,
    ),
    Job(
      id: 4,
      title: 'UI/UX Designer',
      description: 'Design web and mobile screens with clear, accessible layouts.',
      skills: ['Figma', 'User research', 'Prototyping'],
      experience: experienceLevels[1],
      education: educationLevels[1],
      workMode: 'Hybrid',
      workType: 'Contract',
      location: 'Petaling Jaya',
      vacancies: 1,
      salary: '3,800 – 5,000',
      closing: DateTime(2026, 10, 1),
      status: JobStatus.closed,
    ),
  ];

  final applicants = <Applicant>[
    Applicant(
      id: 1,
      jobId: 1,
      name: 'Aina Example',
      match: 94,
      skills: 'Flutter, Dart, REST API, Git',
      education: 'Bachelor of Computer Science',
      educationLevel: "Bachelor's degree",
      experience: '1 year mobile development',
      experienceLevel: '1–2 years',
      status: AppStatus.shortlisted,
      matched: ['Flutter', 'Dart', 'REST API', 'Git', 'Firebase'],
      missing: ['Swift or Kotlin', 'CI/CD pipelines'],
      summary: 'Covers every required skill, with Flutter work from a six-month internship and a final year project.',
      resume: const [
        ResumeSection('Education', [
          'Bachelor of Computer Science (Software Engineering), 2022–2026',
          "CGPA 3.82, Dean's List for five semesters",
        ]),
        ResumeSection('Skills', [
          'Mobile: Flutter, Dart, Android Studio, Provider, Bloc',
          'Backend: REST APIs, Firebase Auth and Firestore, SQLite',
          'Tools: Git, GitHub Actions, Postman, Figma',
        ]),
        ResumeSection('Experience', [
          'Mobile Developer Intern, Example Tech Sdn Bhd, Mar–Aug 2026',
          'Built four Flutter screens for a logistics tracking app',
          'Connected REST endpoints with an offline SQLite cache',
        ]),
        ResumeSection('Projects', ['Campus parcel tracker (final year project): Flutter app with push notifications']),
      ],
      history: [
        StatusChange(DateTime(2026, 10, 25), 'Applied', 'Aina Example'),
        StatusChange(DateTime(2026, 10, 27), 'Under review', 'Recruiter'),
        StatusChange(DateTime(2026, 10, 30), 'Shortlisted', 'Recruiter'),
      ],
      interview: Interview(
        DateTime(2026, 11, 10, 10, 30),
        'Google Meet (link sent with the invitation)',
        'Bring your parcel tracker app and be ready to talk about state management.',
      ),
    ),
    Applicant(
      id: 2,
      jobId: 1,
      name: 'Danial Example',
      match: 88,
      skills: 'Flutter, Firebase, Java, SQLite',
      education: 'Diploma in Information Technology',
      educationLevel: 'Diploma',
      experience: 'Fresh graduate, internship done',
      experienceLevel: 'Fresh graduate',
      status: AppStatus.applied,
      matched: ['Flutter', 'Firebase', 'Git', 'REST API'],
      missing: ['Dart (not stated)'],
      summary: 'Strong Flutter and Firebase projects. Dart is not named in the resume, though Flutter uses it.',
      resume: const [
        ResumeSection('Education', ['Diploma in Information Technology, 2023–2026']),
        ResumeSection('Skills', ['Flutter, Firebase, Java, SQLite, Git']),
        ResumeSection('Experience', ['Intern, Example Apps Sdn Bhd, 3 months']),
      ],
      history: [StatusChange(DateTime(2026, 10, 28), 'Applied', 'Danial Example')],
    ),
    Applicant(
      id: 3,
      jobId: 1,
      name: 'Farah Example',
      match: 72,
      skills: 'React Native, JavaScript, API integration',
      education: 'Bachelor of Information Technology',
      educationLevel: "Bachelor's degree",
      experience: '2 years web and mobile',
      experienceLevel: '1–2 years',
      status: AppStatus.underReview,
      matched: ['REST API', 'Git'],
      missing: ['Flutter', 'Dart', 'Firebase'],
      summary: 'Mobile experience is in React Native, not Flutter. API skills carry over.',
      resume: const [
        ResumeSection('Education', ['Bachelor of Information Technology, 2020–2024']),
        ResumeSection('Skills', ['React Native, JavaScript, API integration, Git']),
        ResumeSection('Experience', ['Web Developer, Example Media Sdn Bhd, 2024–2026']),
      ],
      history: [
        StatusChange(DateTime(2026, 10, 26), 'Applied', 'Farah Example'),
        StatusChange(DateTime(2026, 10, 29), 'Under review', 'Recruiter'),
      ],
    ),
    Applicant(
      id: 4,
      jobId: 1,
      name: 'Hafiz Example',
      match: 55,
      skills: 'HTML, CSS, PHP, MySQL',
      education: 'Diploma in Computer Science',
      educationLevel: 'Diploma',
      experience: 'Fresh graduate',
      experienceLevel: 'Fresh graduate',
      status: AppStatus.applied,
      matched: ['Git'],
      missing: ['Flutter', 'Dart', 'REST API', 'Firebase'],
      summary: 'Web skills (HTML, CSS, PHP, MySQL). Few of the required mobile skills yet.',
      resume: const [
        ResumeSection('Education', ['Diploma in Computer Science, 2023–2026']),
        ResumeSection('Skills', ['HTML, CSS, PHP, MySQL, Git']),
      ],
      history: [StatusChange(DateTime(2026, 10, 31), 'Applied', 'Hafiz Example')],
    ),
    Applicant(
      id: 5,
      jobId: 4,
      name: 'Mei Example',
      match: 81,
      skills: 'Figma, prototyping, user research',
      education: 'Bachelor of Design',
      educationLevel: "Bachelor's degree",
      experience: '2 years product design',
      experienceLevel: '1–2 years',
      status: AppStatus.hired,
      matched: ['Figma', 'Prototyping', 'User research'],
      missing: [],
      summary: 'Covers every required skill.',
      resume: const [
        ResumeSection('Skills', ['Figma, prototyping, user interviews']),
      ],
      history: [
        StatusChange(DateTime(2026, 9, 2), 'Applied', 'Mei Example'),
        StatusChange(DateTime(2026, 9, 20), 'Hired', 'Recruiter'),
      ],
    ),
  ];

  final tickets = <Ticket>[
    Ticket('TKT-2041', 'Company verification document', 'Resolved', DateTime(2026, 10, 14)),
    Ticket('TKT-1982', 'Job post status did not refresh', 'Resolved', DateTime(2026, 10, 2)),
  ];

  Job? job(int id) => jobs.where((j) => j.id == id).firstOrNull;
  Applicant? applicant(int id) => applicants.where((a) => a.id == id).firstOrNull;

  // highest match first
  List<Applicant> applicantsFor(int jobId) =>
      applicants.where((a) => a.jobId == jobId).toList()..sort((a, b) => b.match.compareTo(a.match));

  int rankOf(Applicant a) => applicantsFor(a.jobId).indexOf(a) + 1;

  void saveCompany() => notifyListeners();

  Job addJob(Job draft) {
    final job = Job(
      id: jobs.fold(0, (m, j) => j.id > m ? j.id : m) + 1,
      title: draft.title,
      description: draft.description,
      skills: draft.skills,
      experience: draft.experience,
      education: draft.education,
      workMode: draft.workMode,
      workType: draft.workType,
      location: draft.location,
      vacancies: draft.vacancies,
      salary: draft.salary,
      closing: draft.closing,
      status: draft.status,
    );
    jobs.insert(0, job);
    notifyListeners();
    return job;
  }

  void setJobStatus(Job job, JobStatus status) {
    job.status = status;
    notifyListeners();
  }

  void deleteJob(Job job) {
    jobs.remove(job);
    notifyListeners();
  }

  void changed() => notifyListeners();

  void setStatus(Applicant a, AppStatus status) {
    a.status = status;
    a.history.add(StatusChange(DateTime.now(), status.label, 'You'));
    notifyListeners();
  }

  void schedule(Applicant a, Interview interview) {
    a.interview = interview;
    if (a.status != AppStatus.interview) {
      a.status = AppStatus.interview;
      a.history.add(StatusChange(DateTime.now(), AppStatus.interview.label, 'You'));
    }
    notifyListeners();
  }

  Ticket addTicket(String subject) {
    final ticket = Ticket('TKT-${2042 + tickets.length}', subject, 'Open', DateTime.now());
    tickets.insert(0, ticket);
    notifyListeners();
    return ticket;
  }
}

final recruiterSample = RecruiterSample();

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String clock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
