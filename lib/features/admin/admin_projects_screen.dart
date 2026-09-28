import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/model_copy_with.dart';
import '../../data/models/project_model.dart';
import 'admin_widgets.dart';

/// Project catalogue management: publish, edit and delete (spec section 8).
class AdminProjectsScreen extends ConsumerStatefulWidget {
  const AdminProjectsScreen({super.key});

  @override
  ConsumerState<AdminProjectsScreen> createState() =>
      _AdminProjectsScreenState();
}

class _AdminProjectsScreenState extends ConsumerState<AdminProjectsScreen> {
  String _query = '';
  bool? _publishedFilter;
  bool _busy = false;

  void _snack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              isError ? AppColors.error : AppColors.darkCardBorder,
        ),
      );
  }

  bool _matches(ProjectModel p) {
    if (_publishedFilter != null && p.isPublished != _publishedFilter) {
      return false;
    }
    if (_query.isEmpty) return true;
    final haystack =
        '${p.title} ${p.category} ${p.technologies.join(' ')}'.toLowerCase();
    return haystack.contains(_query);
  }

  Future<void> _togglePublished(ProjectModel project) async {
    setState(() => _busy = true);
    try {
      await ref.read(portfolioRepositoryProvider).saveProject(
            project.copyWith(
              isPublished: !project.isPublished,
              updatedAt: DateTime.now(),
            ),
          );
      _snack(project.isPublished ? 'Draft saved' : 'Project published');
    } catch (e) {
      _snack('Could not update the project: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ProjectModel project) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete "${project.title}"?',
      message: 'The project record is removed permanently. Uploaded media '
          'stays in Storage until it is cleaned up separately.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(portfolioRepositoryProvider).deleteProject(project.id);
      _snack('Project deleted');
    } catch (e) {
      _snack('Could not delete: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);

    return AdminShell(
      title: 'Projects',
      child: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allProjectsProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.space32),
                child: EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'No projects yet',
                  message: 'Create your first case study to populate the '
                      'portfolio work grid.',
                  action: AppButton(
                    label: 'New project',
                    icon: Icons.add_rounded,
                    onPressed: () => context.go('/admin/projects/new'),
                  ),
                ),
              ),
            );
          }

          final visible = all.where(_matches).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  title: '${all.length} project${all.length == 1 ? '' : 's'}',
                  trailing: AppButton(
                    label: 'New project',
                    icon: Icons.add_rounded,
                    onPressed: () => context.go('/admin/projects/new'),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Search title, category, technology...',
                          prefixIcon: Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    _filterChip('All', null),
                    _filterChip('Published', true),
                    _filterChip('Draft', false),
                  ],
                ),
                const SizedBox(height: AppConstants.space16),
                if (visible.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching projects',
                    message: 'Try a different search term or clear the filter.',
                  )
                else
                  Column(
                    children: [
                      for (final project in visible)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.space12,
                          ),
                          child: _tile(project),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, bool? value) {
    return Padding(
      padding: const EdgeInsets.only(left: AppConstants.space8),
      child: FilterChip(
        label: Text(label),
        selected: _publishedFilter == value,
        onSelected: (_) => setState(() => _publishedFilter = value),
        selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _tile(ProjectModel project) {
    return GlassCard(
      padding: const EdgeInsets.all(AppConstants.space12),
      child: Row(
        children: [
          _cover(project.coverImage),
          const SizedBox(width: AppConstants.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.space4),
                Text(
                  project.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppConstants.space8),
                Wrap(
                  spacing: AppConstants.space8,
                  runSpacing: AppConstants.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(label: project.category),
                    if (!project.isPublished)
                      const _Pill(label: 'Draft', muted: false),
                    if (project.isFeatured)
                      const _Pill(label: 'Featured', muted: false),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.space8),
          IconButton(
            tooltip: 'Edit',
            onPressed: _busy
                ? null
                : () => context.go('/admin/projects/${project.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            enabled: !_busy,
            onSelected: (value) {
              if (value == 'toggle') {
                _togglePublished(project);
              } else if (value == 'delete') {
                _delete(project);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  project.isPublished ? 'Move to draft' : 'Publish',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cover(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      child: SizedBox(
        width: 88,
        height: 66,
        child: url.isEmpty
            ? Container(
                color: AppColors.darkBackground,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondaryDark,
                  size: 20,
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.darkBackground,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondaryDark,
                    size: 20,
                  ),
                ),
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.muted = true});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textSecondaryDark : AppColors.accentCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}