import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';

class ExperienceScreen extends ConsumerWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expAsync = ref.watch(publishedExperiencesProvider);

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
                  tag: 'Career Journey',
                  title: 'Professional Experience & Engineering Leadership',
                  subtitle:
                      'A chronological chronicle of senior cross-platform architecture, system engineering, and production delivery.',
                ),
              ),
            ),
            const SizedBox(height: 36),
            ResponsiveContainer(
              child: expAsync.when(
                data: (experiences) {
                  if (experiences.isEmpty) {
                    return const EmptyState(
                      icon: Icons.timeline_rounded,
                      title: 'No experience published yet',
                      message:
                          'Roles and engagements will appear here once they are added and published from the admin dashboard.',
                    );
                  }
                  return _buildTimeline(experiences);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: 'The experience timeline could not be loaded. $error',
                  onRetry: () => ref.invalidate(publishedExperiencesProvider),
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
  Widget _buildTimeline(List<ExperienceModel> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final exp = list[index];
        final dateFormat = DateFormat('MMM yyyy');
        final startStr = dateFormat.format(exp.startDate);
        final endStr = exp.isCurrent ? 'Present' : (exp.endDate != null ? dateFormat.format(exp.endDate!) : '');

        return GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_outline, color: AppColors.accentCyan, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.position,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exp.organization,
                          style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: exp.isCurrent ? AppColors.accentCyan.withValues(alpha: 0.2) : AppColors.darkCardBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$startStr - $endStr',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: exp.isCurrent ? AppColors.accentCyan : AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                exp.description,
                style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
              ),
              if (exp.responsibilities.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...exp.responsibilities.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(r, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      ),
                    ],
                  ),
                )),
              ],
              if (exp.technologies.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: exp.technologies.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
