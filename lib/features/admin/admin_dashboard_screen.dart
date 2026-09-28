import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/backend_callables.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/dashboard_stats.dart';
import '../search/global_search_dialog.dart';
import 'admin_notifications_screen.dart';
import 'admin_widgets.dart';

/// Admin landing page: headline metrics, quick actions, activity feeds and
/// the latest enquiries (spec section 8).
///
/// Every tile is derived from [dashboardStatsProvider] — the admin Firestore
/// streams — so the numbers are correct even before the analytics Cloud
/// Functions are deployed. The `analytics/portfolio_stats` document only
/// drives the manual "Refresh analytics" action and the server-sync
/// indicator.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _refreshingStats = false;

  int _columns(double width) {
    if (width >= 1200) return 4;
    if (width >= 720) return 2;
    return 1;
  }

  /// Refreshes the live streams first, then retries the server rollup.
  ///
  /// The refresh provider must be invalidated *before* it is read: it caches
  /// failures, so once "function not deployed" has been thrown the old code
  /// could never recover even after a deploy.
  Future<void> _handleRefresh() async {
    setState(() => _refreshingStats = true);

    ref.invalidate(contactMessagesProvider);
    ref.invalidate(allProjectsProvider);
    ref.invalidate(allServicesProvider);
    ref.invalidate(allCertificatesProvider);
    ref.invalidate(allAchievementsProvider);
    ref.invalidate(allSkillsProvider);
    ref.invalidate(adminMediaStreamProvider);
    ref.invalidate(adminNotificationsStreamProvider);

    try {
      ref.invalidate(portfolioStatsRefreshProvider);
      final stats = await ref.read(portfolioStatsRefreshProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server counters refreshed: ${stats.publishedProjects} published / ${stats.totalProjects} total projects, ${stats.newMessages} new messages.',
          ),
          backgroundColor: AppColors.accentCyan,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final notDeployed =
          error.code == 'not-found' || error.code == 'unimplemented';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notDeployed
                ? 'Server counters are unavailable — deploy the Cloud Functions '
                    '(firebase deploy --only functions). The live tiles above '
                    'are already up to date.'
                : 'Server refresh failed (${error.code}). The live tiles above '
                    'are already up to date.',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh stats: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshingStats = false);
    }
  }

  /// Shows `--` until a stream has produced its first value, so a loading or
  /// failed collection never masquerades as a genuine zero.
  String _tileValue(AsyncValue<List<Object?>> async, String Function() compute) {
    return async.valueOrNull == null ? '--' : compute();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final projectsAsync = ref.watch(allProjectsProvider);
    final servicesAsync = ref.watch(allServicesProvider);
    final certificatesAsync = ref.watch(allCertificatesProvider);
    final achievementsAsync = ref.watch(allAchievementsProvider);
    final skillsAsync = ref.watch(allSkillsProvider);
    final messagesAsync = ref.watch(contactMessagesProvider);
    final mediaAsync = ref.watch(adminMediaStreamProvider);
    final serverStatsAsync = ref.watch(portfolioStatsStreamProvider);

    final loadErrors = <String>[
      if (projectsAsync.hasError) 'projects',
      if (servicesAsync.hasError) 'services',
      if (certificatesAsync.hasError) 'certificates',
      if (achievementsAsync.hasError) 'achievements',
      if (skillsAsync.hasError) 'skills',
      if (messagesAsync.hasError) 'messages',
      if (mediaAsync.hasError) 'media',
    ];

    return AdminShell(
      title: 'Dashboard',
      actions: [
        IconButton(
          tooltip: 'Search portfolio',
          icon: const Icon(Icons.search_rounded),
          onPressed: () => GlobalSearchDialog.show(context),
        ),
        IconButton(
          tooltip: 'Refresh analytics & counters',
          icon: _refreshingStats
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          onPressed: _refreshingStats ? null : _handleRefresh,
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loadErrors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.space16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppConstants.space12),
                    onTap: _handleRefresh,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: AppConstants.space8),
                        Expanded(
                          child: Text(
                            'Failed to load: ${loadErrors.join(', ')}. '
                            'Tiles may be incomplete — tap to retry.',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _serverStatusRow(serverStatsAsync),
              const SizedBox(height: AppConstants.space16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _columns(constraints.maxWidth);
                  final cards = <Widget>[
                    StatCard(
                      label: 'Projects',
                      value: _tileValue(
                          projectsAsync, () => '${stats.totalProjects}'),
                      icon: Icons.folder_outlined,
                      onTap: () => context.go('/admin/projects'),
                    ),
                    StatCard(
                      label: 'Published',
                      value: _tileValue(
                          projectsAsync, () => '${stats.publishedProjects}'),
                      icon: Icons.visibility_outlined,
                      color: const Color(0xFF22C55E),
                      onTap: () => context.go('/admin/projects'),
                    ),
                    StatCard(
                      label: 'Drafts',
                      value: _tileValue(
                          projectsAsync, () => '${stats.draftProjects}'),
                      icon: Icons.description_outlined,
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.go('/admin/projects'),
                    ),
                    StatCard(
                      label: 'Services',
                      value: _tileValue(
                          servicesAsync, () => '${stats.totalServices}'),
                      icon: Icons.design_services_outlined,
                      onTap: () => context.go('/admin/services'),
                    ),
                    StatCard(
                      label: 'Certificates',
                      value: _tileValue(
                          certificatesAsync, () => '${stats.totalCertificates}'),
                      icon: Icons.workspace_premium_outlined,
                      onTap: () => context.go('/admin/certificates'),
                    ),
                    StatCard(
                      label: 'Achievements',
                      value: _tileValue(
                          achievementsAsync, () => '${stats.totalAchievements}'),
                      icon: Icons.emoji_events_outlined,
                      onTap: () => context.go('/admin/achievements'),
                    ),
                    StatCard(
                      label: 'Views',
                      value: _tileValue(
                          projectsAsync, () => '${stats.totalViews}'),
                      icon: Icons.insights_rounded,
                      color: const Color(0xFFA78BFA),
                      onTap: () => context.go('/admin/projects'),
                    ),
                    StatCard(
                      label: 'Enquiries',
                      value: _tileValue(
                          messagesAsync, () => '${stats.totalMessages}'),
                      icon: Icons.mail_outline_rounded,
                      onTap: () => context.go('/admin/messages'),
                    ),
                    StatCard(
                      label: 'Unread',
                      value: _tileValue(
                          messagesAsync, () => '${stats.newMessages}'),
                      icon: Icons.mark_email_unread_outlined,
                      color: const Color(0xFFF97316),
                      onTap: () => context.go('/admin/messages'),
                    ),
                    StatCard(
                      label: 'Storage used',
                      value: _tileValue(
                          mediaAsync, () => stats.storageUsageLabel),
                      icon: Icons.sd_storage_outlined,
                      color: const Color(0xFF38BDF8),
                    ),
                    StatCard(
                      label: 'Notifications',
                      value: '${stats.unreadNotifications}',
                      icon: Icons.notifications_none_rounded,
                      color: const Color(0xFFE879F9),
                      onTap: () => context.go('/admin/notifications'),
                    ),
                    StatCard(
                      label: 'Skills',
                      value: _tileValue(
                          skillsAsync, () => '${stats.totalSkills}'),
                      icon: Icons.psychology_outlined,
                      color: const Color(0xFF34D399),
                      onTap: () => context.go('/admin/skills'),
                    ),
                  ];

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppConstants.space12,
                    mainAxisSpacing: AppConstants.space12,
                    childAspectRatio: 2.6,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: AppConstants.space32),
              const Text(
                'Quick actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              _quickActions(context),
              const SizedBox(height: AppConstants.space32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final popular = _popularProjectsCard(stats);
                  final activity = _recentActivityCard(stats);
                  if (constraints.maxWidth >= 860) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: popular),
                        const SizedBox(width: AppConstants.space16),
                        Expanded(child: activity),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      popular,
                      const SizedBox(height: AppConstants.space16),
                      activity,
                    ],
                  );
                },
              ),
              const SizedBox(height: AppConstants.space32),
              Row(
                children: [
                  const Text(
                    'Latest enquiries',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/admin/messages'),
                    child: const Text('Open inbox'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space12),
              messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(contactMessagesProvider),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const EmptyState(
                      icon: Icons.mail_outline_rounded,
                      title: 'No enquiries yet',
                      message:
                          'Messages sent from the contact form land here instantly.',
                    );
                  }
                  return Column(
                    children: [
                      for (final message in messages.take(5))
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppConstants.space8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppConstants.space12),
                            onTap: () => context.go('/admin/messages'),
                            child: Row(
                              children: [
                                if (message.status == 'new')
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.circle,
                                      size: 9,
                                      color: AppColors.accentCyan,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        message.message,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppConstants.space12),
                                Text(
                                  DateFormat.Md().format(message.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppConstants.space32),
              _recentUploadsCard(stats),
            ],
          ),
        ),
      ),
    );
  }

  /// Server-rollup sync indicator (spec section 8 "Server status").
  Widget _serverStatusRow(AsyncValue<PortfolioStats?> serverStatsAsync) {
    final IconData icon;
    final String text;
    final Color color;
    if (serverStatsAsync.isLoading) {
      icon = Icons.sync_rounded;
      text = 'Checking server counters…';
      color = AppColors.textSecondaryDark;
    } else {
      final serverStats = serverStatsAsync.valueOrNull;
      if (serverStats == null) {
        icon = Icons.cloud_off_rounded;
        text =
            'Server counters not synced yet — deploy the Cloud Functions to enable them. '
            'Live tiles below come straight from Firestore.';
        color = Colors.amber;
      } else {
        icon = Icons.cloud_done_rounded;
        text =
            'Server counters synced: ${serverStats.publishedProjects} published / '
            '${serverStats.totalProjects} total projects, '
            '${serverStats.newMessages} new messages.';
        color = const Color(0xFF22C55E);
      }
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppConstants.space8),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return GlassCard(
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.space12),
          if (children.isEmpty)
            const Text(
              'Nothing to show yet.',
              style:
                  TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            )
          else
            ...children,
        ],
      ),
    );
  }

  Widget _popularProjectsCard(DashboardStats stats) {
    final popular = stats.popularProjects;
    if (popular.isEmpty) {
      return _sectionCard(
        'Popular projects',
        const [
          Text(
            'No views recorded yet. Counts appear once visitors open a '
            'published project (spec 27).',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
        ],
      );
    }
    return _sectionCard(
      'Popular projects',
      [
        for (final project in popular)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.space8),
            child: InkWell(
              onTap: () => context.go('/admin/projects/${project.id}/edit'),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 18, color: Color(0xFF22C55E)),
                  const SizedBox(width: AppConstants.space8),
                  Expanded(
                    child: Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${project.viewsCount} views',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentActivityCard(DashboardStats stats) {
    final activity = stats.recentActivity();
    return _sectionCard(
      'Recent activity',
      [
        for (final item in activity)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.space8),
            child: Row(
              children: [
                Icon(
                  switch (item.kind) {
                    DashboardActivityKind.project =>
                      item.subtitle.startsWith('Draft')
                          ? Icons.edit_outlined
                          : Icons.folder_outlined,
                    DashboardActivityKind.message =>
                      Icons.mail_outline_rounded,
                  },
                  size: 18,
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: AppConstants.space8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.space8),
                Text(
                  DateFormat.Md().format(item.timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _recentUploadsCard(DashboardStats stats) {
    final uploads = stats.recentUploads;
    return _sectionCard(
      'Recent uploads',
      [
        if (uploads.isEmpty)
          const Text(
            'No uploads indexed yet. The `onObjectFinalized` Cloud Function '
            'indexes every upload — deploy the functions to populate this list.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          )
        else
          for (final item in uploads)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.space8),
              child: Row(
                children: [
                  Icon(
                    item.isVideo
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    size: 18,
                    color: AppColors.accentCyan,
                  ),
                  const SizedBox(width: AppConstants.space8),
                  Expanded(
                    child: Text(
                      item.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    item.uploadedAt == null
                        ? '--'
                        : '${_formatSize(item.size)} · ${DateFormat.Md().format(item.uploadedAt!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  static String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unit]}';
  }

  Widget _quickActions(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onTap) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accentCyan),
            const SizedBox(height: AppConstants.space8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppConstants.space12,
          mainAxisSpacing: AppConstants.space12,
          childAspectRatio: 2.2,
          children: [
            action(Icons.add_rounded, 'New project',
                () => context.go('/admin/projects/new')),
            action(Icons.design_services_outlined, 'Add service',
                () => context.go('/admin/services')),
            action(Icons.workspace_premium_outlined, 'Add certificate',
                () => context.go('/admin/certificates')),
            action(Icons.emoji_events_outlined, 'Add achievement',
                () => context.go('/admin/achievements')),
            action(Icons.mail_outline_rounded, 'Inbox',
                () => context.go('/admin/messages')),
            action(Icons.folder_outlined, 'Projects',
                () => context.go('/admin/projects')),
            action(Icons.campaign_outlined, 'Send notification',
                () => showComposeNotificationDialog(context)),
            action(Icons.format_quote_rounded, 'Testimonials',
                () => context.go('/admin/testimonials')),
            action(Icons.public_rounded, 'View site', () => context.go('/')),
          ],
        );
      },
    );
  }
}