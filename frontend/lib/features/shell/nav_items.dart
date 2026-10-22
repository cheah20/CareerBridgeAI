import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../auth/session.dart';

/// One destination in a role's navigation.
class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.group,
    this.description = '',
    this.phase = '',
  });

  final String path;
  final String label;
  final IconData icon;

  /// Sidebar section heading.
  final String group;

  /// Shown on the placeholder page until the feature is built.
  final String description;
  final String phase;
}

/// Items shown in the sidebar: the Testing and Developer groups exist in debug builds only.
List<NavItem> navItemsFor(UserRole role) => [
  for (final item in navItemsByRole[role]!)
    if (kDebugMode || (item.group != 'Testing' && item.group != 'Developer')) item,
];

/// Navigation for each role.
const Map<UserRole, List<NavItem>> navItemsByRole = {
  UserRole.jobSeeker: [
    NavItem(path: '/seeker/analyse', label: 'Resume analysis', icon: Icons.science_outlined, group: 'Testing'),
    NavItem(path: '/seeker', label: 'Overview', icon: Icons.space_dashboard_outlined, group: 'Job seeker'),
    NavItem(
      path: '/seeker/resume',
      label: 'Resume profile',
      icon: Icons.description_outlined,
      group: 'Job seeker',
      description: 'Upload resumes, review the extracted information and correct it before it updates your profile.',
      phase: 'Phase 2',
    ),
    NavItem(
      path: '/seeker/jobs',
      label: 'Job matches',
      icon: Icons.work_outline,
      group: 'Job seeker',
      description: 'Career directions and job openings sorted by match, with filters for location, salary, work type and more.',
      phase: 'Phase 3–4',
    ),
    NavItem(
      path: '/seeker/applications',
      label: 'Applications',
      icon: Icons.assignment_outlined,
      group: 'Job seeker',
      description: 'Track every application from Applied to Hired, and withdraw an application that has not ended.',
      phase: 'Phase 4',
    ),
    NavItem(
      path: '/seeker/interview',
      label: 'Interview prep',
      icon: Icons.forum_outlined,
      group: 'Grow',
      description: 'Practice questions and preparation tips generated from the job description and your resume.',
      phase: 'Phase 3',
    ),
    NavItem(
      path: '/seeker/roadmap',
      label: 'Learning roadmap',
      icon: Icons.route_outlined,
      group: 'Grow',
      description: 'A step-by-step plan for the skills your target career still needs.',
      phase: 'Phase 3',
    ),
    NavItem(
      path: '/seeker/support',
      label: 'Help & bug report',
      icon: Icons.support_agent_outlined,
      group: 'Account',
      description: 'Report a problem or contact the Admin, and follow the status of your reports.',
      phase: 'Phase 6',
    ),
    NavItem(path: '/seeker/logbook', label: 'Test logbook (dev)', icon: Icons.menu_book_outlined, group: 'Developer'),
  ],
  UserRole.recruiter: [
    NavItem(path: '/recruiter', label: 'Overview', icon: Icons.space_dashboard_outlined, group: 'Recruiter'),
    NavItem(
      path: '/recruiter/company',
      label: 'Company profile',
      icon: Icons.apartment_outlined,
      group: 'Recruiter',
      description: 'Manage your companies and submit proof documents for Admin verification.',
      phase: 'Phase 5',
    ),
    NavItem(
      path: '/recruiter/jobs',
      label: 'Job postings',
      icon: Icons.work_outline,
      group: 'Recruiter',
      description: 'Create drafts, submit jobs for review, publish and close job postings.',
      phase: 'Phase 4',
    ),
    NavItem(
      path: '/recruiter/applicants',
      label: 'Applicants',
      icon: Icons.groups_outlined,
      group: 'Hiring',
      description: 'Review applicants, their authorised resumes and AI match results, and update application status.',
      phase: 'Phase 5',
    ),
    NavItem(
      path: '/recruiter/interviews',
      label: 'Interviews',
      icon: Icons.event_outlined,
      group: 'Hiring',
      description: 'Arrange interviews and send notices to candidates.',
      phase: 'Phase 5',
    ),
    NavItem(
      path: '/recruiter/support',
      label: 'Help & bug report',
      icon: Icons.support_agent_outlined,
      group: 'Account',
      description: 'Report a problem or contact the Admin, and follow the status of your reports.',
      phase: 'Phase 6',
    ),
  ],
  UserRole.admin: [
    NavItem(path: '/admin', label: 'Overview', icon: Icons.space_dashboard_outlined, group: 'Admin'),
    NavItem(
      path: '/admin/users',
      label: 'Users & roles',
      icon: Icons.manage_accounts_outlined,
      group: 'Admin',
      description: 'Manage user accounts, roles and permissions.',
      phase: 'Phase 5',
    ),
    NavItem(
      path: '/admin/companies',
      label: 'Company verification',
      icon: Icons.verified_outlined,
      group: 'Governance',
      description: 'Review company information and proof documents, then verify or reject.',
      phase: 'Phase 5',
    ),
    NavItem(
      path: '/admin/jobs',
      label: 'Job review',
      icon: Icons.fact_check_outlined,
      group: 'Governance',
      description: 'Review new job postings and govern published content.',
      phase: 'Phase 4',
    ),
    NavItem(
      path: '/admin/models',
      label: 'AI models & datasets',
      icon: Icons.model_training_outlined,
      group: 'AI',
      description: 'Datasets, training, evaluation metrics, model versions, deployment and rollback.',
      phase: 'Phase 5',
    ),
    NavItem(
      path: '/admin/monitoring',
      label: 'Alerts & API usage',
      icon: Icons.monitor_heart_outlined,
      group: 'System',
      description: 'System errors, alerts, LLM API usage, cost and budget.',
      phase: 'Phase 6',
    ),
    NavItem(
      path: '/admin/bug-reports',
      label: 'Bug reports',
      icon: Icons.bug_report_outlined,
      group: 'System',
      description: 'View bug reports, assign severity and update their status.',
      phase: 'Phase 6',
    ),
  ],
};
