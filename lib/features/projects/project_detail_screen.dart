import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/project_views_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/seo/seo_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/widgets/app_video_player.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/fullscreen_image_viewer.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/project_model.dart';
import '../../data/models/service_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(publishedProjectsProvider);
    final servicesAsync = ref.watch(publishedServicesProvider);

    // Publishes document-specific metadata once the project is loaded — e.g.
    // "Payments App | Solodev" rather than the generic section title — so a
    // shared link is described by the project it points at (spec section 44).
    _publishProjectMetadata(projectsAsync, projectId);
    ref.listen<AsyncValue<List<ProjectModel>>>(
      publishedProjectsProvider,
      (_, next) => _publishProjectMetadata(next, projectId),
    );

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Text(
                'This project could not be found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final index = projects.indexWhere((p) => p.id == projectId);
          if (index == -1) {
            // Never fall back to a different project: it would render (and
            // count views for) the wrong document when a link goes stale.
            return const Center(
              child: Text(
                'This project could not be found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final project = projects[index];
          AnalyticsService.logProjectView(projectId: project.id, title: project.title);
          // Count the view at most once per visitor per 30 minutes; the rules
          // allow this single-field +1 update on published projects only
          // (spec section 27).
          if (project.isPublished) {
            ProjectViewsService.recordView(project.id);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.darkSurface,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/projects'),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back to Projects'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: AppConstants.space8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    project.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accentCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (project.isFeatured)
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded,
                                            size: 16,
                                            color: Color(0xFFFBBF24)),
                                        SizedBox(width: 4),
                                        Text(
                                          'FEATURED',
                                          style: TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            _FavoriteButton(projectId: project.id),
                            const SizedBox(width: 8),
                            _ShareButton(project: project),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project.title,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          project.shortDescription,
                          style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryDark, height: 1.5),
                        ),
                        // Views and the created/updated stamps: the remaining
                        // public fields of ProjectModel.
                        const SizedBox(height: AppConstants.space12),
                        Wrap(
                          spacing: AppConstants.space16,
                          runSpacing: AppConstants.space8,
                          children: [
                            _metaItem(
                              icon: Icons.visibility_outlined,
                              label: '${project.viewsCount} '
                                  'view${project.viewsCount == 1 ? '' : 's'}',
                            ),
                            _metaItem(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Added '
                                  '${DateFormat.yMMMd().format(project.createdAt)}',
                            ),
                            _metaItem(
                              icon: Icons.update_rounded,
                              label: 'Updated '
                                  '${DateFormat.yMMMd().format(project.updatedAt)}',
                            ),
                          ],
                        ),
                        if (project.technologies.isNotEmpty ||
                            project.platforms.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: AppConstants.space8,
                            runSpacing: AppConstants.space8,
                            children: [
                              for (final tech in project.technologies)
                                _badge(tech, filled: false),
                              for (final platform in project.platforms)
                                _badge(platform, filled: true),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _ProjectGallery(project: project),
                if (project.videos
                    .any((v) => v.trim().isNotEmpty)) ...[
                  const SizedBox(height: 40),
                  ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video Demonstration',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        for (final url in project.videos
                            .where((v) => v.trim().isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppConstants.space16),
                            child: Stack(
                              children: [
                                AppVideoPlayer(url: url),
                                // Sits in the top-right, away from the
                                // player's centre play button and its bottom
                                // scrubber, so it never swallows a tap meant
                                // for playback.
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: _OpenFullscreenButton(
                                    onPressed: () => context.push(
                                      _watchLocation(url, project.title),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.fullDescription,
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryDark, height: 1.6),
                      ),
                      const SizedBox(height: 32),
                      if ((project.challenge ?? '').trim().isNotEmpty) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Technical Challenge',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              const SizedBox(height: 8),
                              Text(project.challenge!, style: const TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if ((project.solution ?? '').trim().isNotEmpty) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Engineered Solution',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                              const SizedBox(height: 8),
                              Text(project.solution!, style: const TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if ((project.result ?? '').trim().isNotEmpty) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Results & Impact',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
                              const SizedBox(height: 8),
                              Text(project.result!, style: const TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (project.features.isNotEmpty) ...[
                        const Text('Key Features',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        for (final feature in project.features)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 18, color: AppColors.accentCyan),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(
                                        color: AppColors.textSecondaryDark,
                                        height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (_hasAnyLink(project)) ...[
                        const Text('Live Preview',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: AppConstants.space12,
                          runSpacing: AppConstants.space12,
                          children: [
                            if ((project.projectUrl ?? '').trim().isNotEmpty)
                              _LinkButton(
                                label: 'Live Demo',
                                icon: Icons.open_in_new_rounded,
                                url: project.projectUrl!.trim(),
                              ),
                            if ((project.githubUrl ?? '').trim().isNotEmpty)
                              _LinkButton(
                                label: 'Source Code',
                                icon: Icons.code_rounded,
                                url: project.githubUrl!.trim(),
                              ),
                            if ((project.appStoreUrl ?? '').trim().isNotEmpty)
                              _LinkButton(
                                label: 'App Store',
                                icon: Icons.apple,
                                url: project.appStoreUrl!.trim(),
                              ),
                            if ((project.playStoreUrl ?? '').trim().isNotEmpty)
                              _LinkButton(
                                label: 'Google Play',
                                icon: Icons.shop_rounded,
                                url: project.playStoreUrl!.trim(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                      ..._relatedSections(
                        context: context,
                        project: project,
                        projects: projects,
                        services: servicesAsync.valueOrNull ?? const [],
                      ),
                      AppButton(
                        label: 'Discuss This Case Study',
                        icon: Icons.chat_bubble_outline,
                        onPressed: () => context.go('/contact'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                const PublicFooter(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Project not found')),
      ),
    );
  }

  /// True when at least one outbound project link is set (spec section 13).
  static bool _hasAnyLink(ProjectModel p) =>
      (p.projectUrl ?? '').trim().isNotEmpty ||
      (p.githubUrl ?? '').trim().isNotEmpty ||
      (p.appStoreUrl ?? '').trim().isNotEmpty ||
      (p.playStoreUrl ?? '').trim().isNotEmpty;

  /// Small rounded badge used in the hero for technologies and platforms.
  /// A small icon + label pair used for the views and date stamps.
  static Widget _metaItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondaryDark),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static Widget _badge(String label, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.accentCyan.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: filled
              ? AppColors.accentCyan.withValues(alpha: 0.5)
              : Colors.white24,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? AppColors.accentCyan : Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Related projects and services blocks (spec section 13).
  ///
  /// Projects are ordered same-category-first, services by shared technology;
  /// both fall back to the newest remaining entries so the section is never
  /// needlessly empty.
  List<Widget> _relatedSections({
    required BuildContext context,
    required ProjectModel project,
    required List<ProjectModel> projects,
    required List<ServiceModel> services,
  }) {
    final relatedProjects = <ProjectModel>[
      ...projects.where(
          (p) => p.id != project.id && p.category == project.category),
      ...projects.where(
          (p) => p.id != project.id && p.category != project.category),
    ].take(3).toList();

    final relatedServices = <ServiceModel>[
      ...services.where(
          (s) => s.technologies.any(project.technologies.contains)),
      ...services.where(
          (s) => !s.technologies.any(project.technologies.contains)),
    ].take(3).toList();

    return [
      if (relatedProjects.isNotEmpty) ...[
        const Text('Related Projects',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Wrap(
          spacing: AppConstants.space12,
          runSpacing: AppConstants.space12,
          children: [
            for (final p in relatedProjects)
              _relatedCard(
                context: context,
                title: p.title,
                subtitle: p.category,
                onTap: () => context.go('/projects/${p.id}'),
              ),
          ],
        ),
        const SizedBox(height: 32),
      ],
      if (relatedServices.isNotEmpty) ...[
        const Text('Related Services',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Wrap(
          spacing: AppConstants.space12,
          runSpacing: AppConstants.space12,
          children: [
            for (final s in relatedServices)
              _relatedCard(
                context: context,
                title: s.title,
                subtitle: s.shortDescription,
                onTap: () => context.go('/services/${s.id}'),
              ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    ];
  }

  static Widget _relatedCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 240,
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the deep link to the fullscreen viewer.
///
/// Both values are encoded because a video URL carries `://`, `?` and `&`
/// characters that would otherwise be parsed as query syntax.
String _watchLocation(String videoUrl, String title) {
  return '/watch'
      '?video=${Uri.encodeComponent(videoUrl)}'
      '&title=${Uri.encodeComponent(title)}';
}

/// Expand affordance overlaid on an embedded player.
class _OpenFullscreenButton extends StatelessWidget {
  const _OpenFullscreenButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Fullscreen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Heart toggle that stores the project id in local storage.
class _FavoriteButton extends ConsumerWidget {
  final String projectId;

  const _FavoriteButton({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.valueOrNull?.contains(projectId) ?? false;

    return Tooltip(
      message: isFavorite ? 'Remove from favourites' : 'Save to favourites',
      child: IconButton(
        onPressed: () async {
          final nowFavorite =
              await ref.read(favoritesProvider.notifier).toggle(projectId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.darkCard,
                content: Text(
                  nowFavorite
                      ? 'Added to your favourites'
                      : 'Removed from your favourites',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
        },
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.error : AppColors.accentCyan,
        ),
      ),
    );
  }
}

/// Share / copy-link action for the project (§27, §30).
class _ShareButton extends StatelessWidget {
  final ProjectModel project;

  const _ShareButton({required this.project});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Share / Copy link',
      child: IconButton(
        onPressed: () async {
          // Construct current URL path or share text
          final url = Uri.base.origin.isNotEmpty && !Uri.base.origin.startsWith('null')
              ? '${Uri.base.origin}/projects/${project.id}'
              : '/projects/${project.id}';

          await Clipboard.setData(ClipboardData(text: url));
          await AnalyticsService.logProjectShare(projectId: project.id);

          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.darkCard,
                content: Text(
                  'Project link copied to clipboard: $url',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
        },
        icon: const Icon(
          Icons.share_rounded,
          color: AppColors.accentCyan,
        ),
      ),
    );
  }
}

/// Screenshot gallery with a fullscreen zoomable lightbox on tap.
class _ProjectGallery extends StatelessWidget {
  final ProjectModel project;

  const _ProjectGallery({required this.project});

  List<String> get _images {
    final cover = project.coverImage;
    final rest = project.images;
    return <String>[
      if (cover.trim().isNotEmpty) cover,
      ...rest.where((e) => e.trim().isNotEmpty && e != cover),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) return const SizedBox.shrink();

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Screenshots',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => FullscreenImageViewer.show(
                  context,
                  images: images,
                  initialIndex: i,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  child: Stack(
                    children: [
                      Image.network(
                        images[i],
                        width: 340,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 340,
                          height: 240,
                          color: AppColors.darkCard,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.textSecondaryDark, size: 48),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(Icons.zoom_out_map,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Puts the loaded project into the page metadata (spec section 44).
///
/// A separate function rather than a closure inside `build` so the same logic
/// serves both the first frame (the provider may already be cached) and every
/// later emission. Riverpod 2's `Ref.listen` cannot fire immediately, so the
/// current value is applied explicitly before the listener is registered.
void _publishProjectMetadata(
  AsyncValue<List<ProjectModel>> value,
  String projectId,
) {
  for (final project in value.valueOrNull ?? const <ProjectModel>[]) {
    if (project.id != projectId) continue;
    SeoService.applyDetailPage(
      title: project.title,
      description: project.shortDescription,
    );
    return;
  }
}

/// Outbound link button used by the Live Preview section (spec section 13).
class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => _launchHttpUrl(url),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

/// Opens [url] in the external browser; only `http(s)` links are launched.
Future<void> _launchHttpUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      !uri.hasAuthority) {
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // A blocked or malformed link must never crash the detail page.
  }
}

