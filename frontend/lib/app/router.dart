import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/page_parts.dart';
import '../features/admin/admin_overview_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/session.dart';
import '../features/public/landing_page.dart';
import '../features/public/public_jobs_page.dart';
import '../features/recruiter/recruiter_overview_page.dart';
import '../features/seeker/seeker_overview_page.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/nav_items.dart';

const _publicPaths = {'/', '/jobs', '/login'};

/// Decides where a request may go. Pure function so it is easy to test.
///
/// * Guests may only see public pages; anything else sends them to /login.
/// * Signed-in users stay inside their own role's area (/seeker, /recruiter, /admin).
/// * The frontend check is for navigation only — the backend and RLS
///   enforce the real permissions.
String? redirectFor(Session session, Uri uri) {
  final path = uri.path;
  final role = session.role;
  final isPublic = _publicPaths.contains(path);

  if (role == null) {
    if (isPublic) return null;
    return Uri(path: '/login', queryParameters: {'from': uri.toString()}).toString();
  }
  if (path == '/login') return role.homePath;
  if (!isPublic && path != role.homePath && !path.startsWith('${role.homePath}/')) return role.homePath;
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
  return ComingSoonPage(title: item.label, description: item.description, phase: item.phase);
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
