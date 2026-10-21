import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/page_parts.dart';
import '../features/admin/admin_overview_page.dart';
import '../features/auth/loading_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/session.dart';
import '../features/auth/signup_page.dart';
import '../features/public/landing_page.dart';
import '../features/public/public_jobs_page.dart';
import '../features/recruiter/recruiter_overview_page.dart';
import '../features/seeker/seeker_overview_page.dart';
import '../features/testing/logbook_page.dart';
import '../features/testing/resume_analysis_page.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/nav_items.dart';

const _publicPaths = {'/', '/jobs', '/login', '/signup'};
const _authPaths = {'/login', '/signup', '/loading'};

/// Decides where a request may go.
String? redirectFor(Session session, Uri uri) {
  final path = uri.path;
  // Remember where the user was going across /login and /loading.
  final from = uri.queryParameters['from'] ?? (_publicPaths.contains(path) || path == '/loading' ? null : uri.toString());

  if (session.status == SessionStatus.loading) {
    return path == '/loading' ? null : Uri(path: '/loading', queryParameters: from == null ? null : {'from': from}).toString();
  }

  final role = session.isLoggedIn ? session.role : null;
  if (role == null) {
    if (path == '/loading') return Uri(path: '/login', queryParameters: from == null ? null : {'from': from}).toString();
    if (_publicPaths.contains(path)) return null;
    return Uri(path: '/login', queryParameters: {'from': uri.toString()}).toString();
  }

  bool inArea(String p) => p == role.homePath || p.startsWith('${role.homePath}/');
  if (_authPaths.contains(path)) {
    final target = from == null ? null : Uri.parse(from).path;
    return target != null && inArea(target) ? from : role.homePath;
  }
  if (!_publicPaths.contains(path) && !inArea(path)) return role.homePath;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) => redirectFor(ref.read(sessionProvider), state.uri),
    routes: [
      GoRoute(path: '/', pageBuilder: (context, state) => _fade(state, const LandingPage())),
      GoRoute(path: '/jobs', pageBuilder: (context, state) => _fade(state, const PublicJobsPage())),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fade(state, LoginPage(redirectTo: state.uri.queryParameters['from'])),
      ),
      GoRoute(path: '/signup', pageBuilder: (context, state) => _fade(state, const SignUpPage())),
      GoRoute(path: '/loading', pageBuilder: (context, state) => _fade(state, const LoadingPage())),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          for (final entry in navItemsByRole.entries)
            for (final item in entry.value)
              GoRoute(
                path: item.path,
                pageBuilder: (context, state) => _fade(state, _pageFor(entry.key, item)),
              ),
        ],
      ),
    ],
  );
  // Re-run the redirect when the user logs in or out.
  ref.listen(sessionProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

Widget _pageFor(UserRole role, NavItem item) {
  if (item.path == role.homePath) {
    return switch (role) {
      UserRole.jobSeeker => const SeekerOverviewPage(),
      UserRole.recruiter => const RecruiterOverviewPage(),
      UserRole.admin => const AdminOverviewPage(),
    };
  }
  return switch (item.path) {
    '/seeker/analyse' => const ResumeAnalysisPage(),
    '/seeker/logbook' => const LogbookPage(),
    _ => ComingSoonPage(title: item.label, description: item.description, phase: item.phase),
  };
}

/// Pages fade and rise slightly into place.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
