import 'media_item_model.dart';
import 'more_models.dart';
import 'project_model.dart';
import 'service_model.dart';

/// A single line of the dashboard "Recent activity" feed (spec section 8).
class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final DashboardActivityKind kind;
}

/// Distinguishes the source of an activity entry so the dashboard can pick
/// an icon without the model depending on Flutter.
enum DashboardActivityKind { project, message }

/// Client-side dashboard summary (spec section 8).
///
/// Derived from the same admin streams the dashboard already subscribes to,
/// so every tile shows real numbers even before the `refreshPortfolioStats`
/// Cloud Function is deployed. The server document
/// (`analytics/portfolio_stats`) remains the source for the manual
/// "Refresh analytics" action and the sync indicator only.
class DashboardStats {
  const DashboardStats({
    this.projects = const [],
    this.services = const [],
    this.certificates = const [],
    this.achievements = const [],
    this.skills = const [],
    this.messages = const [],
    this.media = const [],
    this.unreadNotifications = 0,
  });

  final List<ProjectModel> projects;
  final List<ServiceModel> services;
  final List<CertificateModel> certificates;
  final List<AchievementModel> achievements;
  final List<SkillModel> skills;
  final List<ContactMessageModel> messages;
  final List<MediaItemModel> media;
  final int unreadNotifications;

  int get totalProjects => projects.length;

  int get publishedProjects =>
      projects.where((p) => p.isPublished).length;

  int get draftProjects => totalProjects - publishedProjects;

  int get totalServices => services.length;

  int get publishedServices =>
      services.where((s) => s.isPublished).length;

  int get totalCertificates => certificates.length;

  int get publishedCertificates =>
      certificates.where((c) => c.isPublished).length;

  int get totalAchievements => achievements.length;

  int get publishedAchievements =>
      achievements.where((a) => a.isPublished).length;

  int get totalSkills => skills.length;

  int get totalMessages => messages.length;

  /// Messages waiting for the first reply (status `new`).
  int get newMessages => messages.where((m) => m.status == 'new').length;

  /// Messages that are not closed yet (`new`, `read`, `in_progress`).
  int get openMessages =>
      messages.where((m) => m.status != 'closed' && m.status != 'replied').length;

  /// Sum of the per-project `viewsCount` field (spec section 27).
  int get totalViews =>
      projects.fold(0, (sum, p) => sum + p.viewsCount);

  /// Published projects ordered by views, most viewed first (spec section 8).
  List<ProjectModel> get popularProjects {
    final sorted = projects.where((p) => p.isPublished && p.viewsCount > 0)
        .toList()
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    return sorted.take(5).toList();
  }

  /// Total indexed media size in bytes.
  int get storageBytes => media.fold(0, (sum, m) => sum + m.size);

  /// Human-readable storage label, e.g. `12.4 MB`.
  String get storageUsageLabel => _formatBytes(storageBytes);

  /// Newest indexed uploads, most recent first (spec section 8).
  List<MediaItemModel> get recentUploads {
    final sorted = media.where((m) => m.uploadedAt != null).toList()
      ..sort((a, b) => b.uploadedAt!.compareTo(a.uploadedAt!));
    return sorted.take(6).toList();
  }

  /// Newest project edits merged with newest enquiries (spec section 8).
  List<DashboardActivity> recentActivity({int limit = 6}) {
    final items = <DashboardActivity>[
      for (final p in projects)
        DashboardActivity(
          title: p.title,
          subtitle: p.isPublished ? 'Project updated' : 'Draft updated',
          timestamp: p.updatedAt,
          kind: DashboardActivityKind.project,
        ),
      for (final m in messages)
        DashboardActivity(
          title: m.name.isEmpty ? m.email : m.name,
          subtitle: 'New enquiry: ${m.subject}',
          timestamp: m.createdAt,
          kind: DashboardActivityKind.message,
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(limit).toList();
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final rounded = size >= 100 ? size.roundToDouble() : (size * 10) / 10;
    return '${rounded.toStringAsFixed(rounded == rounded.truncateToDouble() ? 0 : 1)} ${units[unit]}';
  }
}
