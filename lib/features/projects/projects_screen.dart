import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/favorites_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(publishedProjectsProvider);

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: const ResponsiveContainer(
                child: SectionHeader(
                  tag: 'Production Work',
                  title: 'Engineering Showcase',
                  subtitle: 'A curated collection of scalable cross-platform applications and cloud architectures.',
                ),
              ),
            ),
            ResponsiveContainer(
              child: projectsAsync.when(
                data: (projects) {
                  final favoriteIds =
                      ref.watch(favoritesProvider).valueOrNull ?? <String>{};
                  final categories = [
                    'All',
                    'Favourites',
                    ...{...projects.map((p) => p.category)},
                  ];
                  final filtered = switch (_selectedCategory) {
                    'All' => projects,
                    'Favourites' =>
                      projects.where((p) => favoriteIds.contains(p.id)).toList(),
                    _ => projects
                        .where((p) => p.category == _selectedCategory)
                        .toList(),
                  };

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = cat == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: AppColors.primary,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return GlassCard(
                            onTap: () => context.go('/projects/${p.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.category.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.accentCyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    _FavoriteToggle(projectId: p.id),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(p.shortDescription, style: const TextStyle(color: AppColors.textSecondaryDark)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Unable to load projects.'),
              ),
            ),
            const SizedBox(height: 60),
            const PublicFooter(),
          ],
        ),
      ),
    );
  }
}

/// Compact heart toggle shown on each project card.
class _FavoriteToggle extends ConsumerWidget {
  final String projectId;

  const _FavoriteToggle({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite =
        ref.watch(favoritesProvider).valueOrNull?.contains(projectId) ?? false;

    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: isFavorite ? 'Remove from favourites' : 'Save to favourites',
      onPressed: () =>
          ref.read(favoritesProvider.notifier).toggle(projectId),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 20,
        color: isFavorite ? AppColors.error : AppColors.textSecondaryDark,
      ),
    );
  }
}

