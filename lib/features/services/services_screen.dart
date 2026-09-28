import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../core/widgets/service_icon.dart';
import '../../data/datasources/portfolio_providers.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(publishedServicesProvider);

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: const ResponsiveContainer(
                child: SectionHeader(
                  tag: 'Specialized Expertise',
                  title: 'Production-Grade Engineering',
                  subtitle:
                      'Tailored end-to-end digital solutions spanning cross-platform Flutter development, scalable Firebase architecture, and futuristic AI-driven design systems.',
                ),
              ),
            ),
            ResponsiveContainer(
              child: servicesAsync.when(
                data: (services) {
                  return LayoutBuilder(builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: services.map((s) {
                        return SizedBox(
                          width: isDesktop ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                          child: GlassCard(
                            padding: const EdgeInsets.all(28),
                            onTap: () => context.go('/services/${s.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        serviceIconData(s.iconName),
                                        color: AppColors.accentCyan,
                                        size: 28,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward, color: AppColors.accentCyan),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (s.isFeatured)
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: Color(0xFFFBBF24),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  s.shortDescription,
                                  style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  });
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading services'),
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
