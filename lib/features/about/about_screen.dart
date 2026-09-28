import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: PublicNavbar(),
      drawer: PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _AboutHeader(),
            SizedBox(height: 36),
            _AboutContent(),
            SizedBox(height: 60),
            PublicFooter(),
          ],
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: AppColors.darkSurface,
      child: const ResponsiveContainer(
        child: SectionHeader(
          tag: 'Architect & Creator',
          title: 'Engineering the Future of Cross-Platform Apps',
          subtitle:
              'Designing and developing cloud-integrated, high-speed Flutter, Firebase, and AI applications.',
        ),
      ),
    );
  }
}

/// Administrator-authored biography and capabilities.
///
/// Renders only content stored in `settings/default` and `skills`. When either
/// collection is empty an explicit empty state is shown, so the page can never
/// present invented profile copy or skills.
class _AboutContent extends ConsumerWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(portfolioSettingsProvider);
    final skillsAsync = ref.watch(skillsProvider);

    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          settingsAsync.when(
            data: (settings) => GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solodev Core Philosophy',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Clean Code • High Speed • Futuristic UI',
                              style: TextStyle(
                                  color: AppColors.accentCyan,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    settings.aboutText.isEmpty
                        ? 'Biography has not been added yet.'
                        : settings.aboutText,
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryDark,
                        height: 1.7),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Profile details could not be loaded. $error',
              onRetry: () => ref.invalidate(portfolioSettingsProvider),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'Engineering Capabilities',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 16),
          skillsAsync.when(
            data: (skills) {
              if (skills.isEmpty) {
                return const EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'No capabilities listed yet',
                  message:
                      'Skills will appear here once they are added and published from the admin dashboard.',
                );
              }
              final list = skills.map((s) => s.name).toList();

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: list.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.accentCyan, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Capabilities could not be loaded. $error',
              onRetry: () => ref.invalidate(skillsProvider),
            ),
          ),
          const SizedBox(height: 48),
          const _AboutCta(),
        ],
      ),
    );
  }
}

class _AboutCta extends StatelessWidget {
  const _AboutCta();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      borderColor: AppColors.accentCyan.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Text(
            'Have an ambitious project in mind?',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'From scalable Flutter applications to custom AI design systems, let us engineer a solution tailored to your goals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Start a Project Conversation',
            icon: Icons.send_rounded,
            onPressed: () => context.go('/contact'),
          ),
        ],
      ),
    );
  }
}

