import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'app_route_observer.dart';
import '../../features/home/home_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/services/service_detail_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/video_view_screen.dart';
import '../../features/certificates/certificates_screen.dart';
import '../../features/certificates/certificate_detail_screen.dart';
import '../../features/contact/contact_screen.dart';
import '../../features/about/about_screen.dart';
import '../../features/experience/experience_screen.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/admin/admin_login_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_messages_screen.dart';
import '../../features/admin/admin_notifications_screen.dart';
import '../../features/admin/admin_projects_screen.dart';
import '../../features/admin/admin_settings_screen.dart';
import '../../features/admin/admin_skills_screen.dart';
import '../../features/admin/admin_achievements_screen.dart';
import '../../features/admin/admin_testimonials_screen.dart';
import '../../features/admin/admin_certificates_screen.dart';
import '../../features/admin/admin_experience_screen.dart';
import '../../features/admin/admin_services_screen.dart';
import '../../features/admin/project_editor_screen.dart';

/// Bridges a [Stream] to the [Listenable] that [GoRouter] expects, so the
/// router re-evaluates its redirect on every auth state change.
///
/// Implemented locally rather than relying on `GoRouterRefreshStream`, which is
/// not exported by every `go_router` release.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Rebuilds [appRouter] whenever the Firebase auth session changes, so the
/// redirect below is re-evaluated on both sign-in and sign-out.
final _AuthRefreshNotifier _authRefresh =
    _AuthRefreshNotifier(FirebaseAuth.instance.authStateChanges());

/// Routes under this prefix require an authenticated session.
const String _adminPrefix = '/admin';

/// Single sign-in entry point for the admin area.
const String _adminLoginPath = '/admin/login';

/// Landing page after a successful sign-in.
const String _adminHomePath = '/admin/dashboard';

/// The single router instance for the app.
///
/// The explicit [GoRouter] type breaks the inference cycle created by the
/// observer below, which reads its own delegate to resolve the current
/// location.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _authRefresh,

  // Publishes page titles and meta descriptions on every navigation
  // (spec section 44). The resolver reads the router's live match list, so the
  // metadata follows the address bar rather than `go_router`'s route patterns.
  observers: <NavigatorObserver>[
    AppRouteObserver(
      locationResolver: () =>
          appRouter.routerDelegate.currentConfiguration.uri.toString(),
    ),
  ],

  /// Blocks anonymous access to every `/admin/**` route.
  ///
  /// This is a navigation guard only. Real authorisation is enforced
  /// server-side by the Firestore and Storage security rules, which require an
  /// `admins/{uid}` document or a `role: 'admin'` custom claim. A signed-in
  /// non-admin therefore still sees only empty states, never protected data.
  redirect: (context, state) {
    final location = state.matchedLocation;
    final isAdminArea =
        location == _adminPrefix || location.startsWith('$_adminPrefix/');
    if (!isAdminArea) return null;

    final isLoginRoute = location == _adminLoginPath;
    final isSignedIn = FirebaseAuth.instance.currentUser != null;

    if (!isSignedIn) {
      return isLoginRoute ? null : _adminLoginPath;
    }
    // Already authenticated: skip the login form.
    if (isLoginRoute) return _adminHomePath;
    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => const ServicesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ServiceDetailScreen(serviceId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => const ProjectsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ProjectDetailScreen(projectId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/watch',
      builder: (context, state) => VideoViewScreen(
        url: state.uri.queryParameters['video'] ?? '',
        title: state.uri.queryParameters['title'] ?? '',
      ),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/experience',
      builder: (context, state) => const ExperienceScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/certificates',
      builder: (context, state) => const CertificatesScreen(),
    ),
    GoRoute(
      path: '/certificates/:id',
      builder: (context, state) => CertificateDetailScreen(
        certificateId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactScreen(),
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/projects',
      builder: (context, state) => const AdminProjectsScreen(),
    ),
    GoRoute(
      path: '/admin/services',
      builder: (context, state) => const AdminServicesScreen(),
    ),
    GoRoute(
      path: '/admin/experience',
      builder: (context, state) => const AdminExperienceScreen(),
    ),
    GoRoute(
      path: '/admin/certificates',
      builder: (context, state) => const AdminCertificatesScreen(),
    ),
    GoRoute(
      path: '/admin/achievements',
      builder: (context, state) => const AdminAchievementsScreen(),
    ),
    GoRoute(
      path: '/admin/testimonials',
      builder: (context, state) => const AdminTestimonialsScreen(),
    ),
    GoRoute(
      path: '/admin/skills',
      builder: (context, state) => const AdminSkillsScreen(),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsScreen(),
    ),
    GoRoute(
      path: '/admin/messages',
      builder: (context, state) => const AdminMessagesScreen(),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const AdminNotificationsScreen(),
    ),
    GoRoute(
      path: '/admin/projects/new',
      builder: (context, state) => const ProjectEditorScreen(),
    ),
    GoRoute(
      path: '/admin/projects/:id/edit',
      builder: (context, state) =>
          ProjectEditorScreen(projectId: state.pathParameters['id']),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('404 — Page Not Found', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    ),
  ),
);
