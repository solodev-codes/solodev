import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(publishedAchievementsProvider);

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              color: AppColors.darkSurface,
              child: const ResponsiveContainer(
                child: SectionHeader(
                  tag: 'Milestones & Recognition',
                  title: 'Engineering Honors & Industry Achievements',
                  subtitle:
                      'Recognitions, competition wins, and technical milestones.',
                ),
              ),
            ),
            const SizedBox(height: 36),
            ResponsiveContainer(
              child: achievementsAsync.when(
                data: (achievements) {
                  if (achievements.isEmpty) {
                    return const EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'No achievements published yet',
                      message:
                          'Awards, recognitions and technical milestones will appear here once they are published from the admin dashboard.',
                    );
                  }
                  return _buildList(achievements);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: 'Achievements could not be loaded. $error',
                  onRetry: () => ref.invalidate(publishedAchievementsProvider),
                ),
              ),
            ),
            const SizedBox(height: 60),
            const PublicFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AchievementModel> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final a = list[index];
        final dateStr = DateFormat('MMMM yyyy').format(a.date);

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a.category.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                          ),
                        ),
                        const Spacer(),
                        Text(dateStr, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(a.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(a.description, style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.4)),
                    if (a.externalUrl != null && a.externalUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse(a.externalUrl!)),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Verify Credential'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
