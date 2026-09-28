import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/backend_callables.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/messaging_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/portfolio_repository.dart';
import '../models/project_model.dart';
import '../models/service_model.dart';
import '../models/more_models.dart';
import '../models/media_item_model.dart';
import '../models/dashboard_stats.dart';
import '../models/testimonial_model.dart';

// Repository Provider
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository();
});

// Auth Provider
final authStateProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream.value(null);
  }
});

// Published Services Provider
final publishedServicesProvider = StreamProvider<List<ServiceModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamPublishedServices();
});

// Published Projects Provider
final publishedProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamPublishedProjects();
});

// Published Certificates Provider
final publishedCertificatesProvider = StreamProvider<List<CertificateModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamPublishedCertificates();
});

// Admin Providers
final allProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllProjects();
});

final allServicesProvider = StreamProvider<List<ServiceModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllServices();
});

final contactMessagesProvider = StreamProvider<List<ContactMessageModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamContactMessages();
});

// Achievements Providers
final publishedAchievementsProvider = StreamProvider<List<AchievementModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamPublishedAchievements();
});

final allAchievementsProvider = StreamProvider<List<AchievementModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllAchievements();
});

// Experiences Providers
final publishedExperiencesProvider = StreamProvider<List<ExperienceModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamPublishedExperiences();
});

final allExperiencesProvider = StreamProvider<List<ExperienceModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllExperiences();
});

// Skills Provider (public: published only)
final skillsProvider = StreamProvider<List<SkillModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamSkills();
});

// All Skills Provider (Admin)
final allSkillsProvider = StreamProvider<List<SkillModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllSkills();
});

// Portfolio Settings Provider
final portfolioSettingsProvider = StreamProvider<PortfolioSettingsModel>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamSettings();
});

// All Certificates Provider (Admin)
final allCertificatesProvider = StreamProvider<List<CertificateModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllCertificates();
});

// Testimonials Providers (spec sections 9/23)
final publishedTestimonialsProvider = StreamProvider<List<TestimonialModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamPublishedTestimonials();
});

final allTestimonialsProvider = StreamProvider<List<TestimonialModel>>((ref) {
  return ref.watch(portfolioRepositoryProvider).streamAllTestimonials();
});







// Backend Callables Provider
final backendCallablesProvider = Provider<BackendCallables>((ref) {
  return BackendCallables();
});

// Admin Stats Refresh FutureProvider (triggers Cloud Function callable)
final portfolioStatsRefreshProvider = FutureProvider<PortfolioStats>((ref) async {
  final callables = ref.watch(backendCallablesProvider);
  return callables.refreshPortfolioStats();
});

// Admin Stats StreamProvider (watches analytics/portfolio_stats Firestore document)
//
// Yields `null` while the document does not exist — i.e. before the
// `refreshPortfolioStats` / `dailyStatsRollup` Cloud Functions have ever run.
// `PortfolioStats.empty()` must never be returned here: a missing document and
// a genuine "all zeroes" document are different states, and conflating them is
// what made the dashboard show zeros permanently (spec section 8).
final portfolioStatsStreamProvider = StreamProvider<PortfolioStats?>((ref) {
  return FirebaseFirestore.instance
      .collection('analytics')
      .doc('portfolio_stats')
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return PortfolioStats.fromMap(snapshot.data()!);
      });
});

// Indexed uploads (spec sections 8/47). Admin-only read, written by the
// `onObjectFinalized` Cloud Function.
final adminMediaStreamProvider = StreamProvider<List<MediaItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('media')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map(MediaItemModel.fromDoc).toList());
});

// Client-side dashboard summary (spec section 8).
//
// Derived from the admin streams above so every tile shows real numbers even
// when the stats document has never been written (functions not deployed).
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  return DashboardStats(
    projects: ref.watch(allProjectsProvider).valueOrNull ?? const [],
    services: ref.watch(allServicesProvider).valueOrNull ?? const [],
    certificates: ref.watch(allCertificatesProvider).valueOrNull ?? const [],
    achievements: ref.watch(allAchievementsProvider).valueOrNull ?? const [],
    skills: ref.watch(allSkillsProvider).valueOrNull ?? const [],
    messages: ref.watch(contactMessagesProvider).valueOrNull ?? const [],
    media: ref.watch(adminMediaStreamProvider).valueOrNull ?? const [],
    unreadNotifications:
        ref.watch(adminNotificationsStreamProvider).valueOrNull?.length ?? 0,
  );
});

// Admin Notifications StreamProvider (streams admin notification centre docs)
final adminNotificationsStreamProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
  }
  return MessagingService.notificationHistory(user.uid);
});

// Connectivity Provider (device transport availability, spec section 61)
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// Connectivity Status StreamProvider (true while a network is available)
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineChanges;
});
