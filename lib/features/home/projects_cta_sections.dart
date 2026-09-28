import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';

class ProjectsSection extends StatelessWidget {
  final AsyncValue projectsAsync;
  const ProjectsSection({super.key, required this.projectsAsync});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionHeader(
            tag: 'Featured Work',
            title: 'Selected Production Systems',
            subtitle: 'Engineered for scalability, seamless ergonomics, and real-world impact.',
          ),
          const SizedBox(height: 40),
          projectsAsync.when(
            data: (projects) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return GlassCard(
                    onTap: () => context.go('/projects/${p.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.shortDescription,
                          style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Unable to load projects at this time.'),
          ),
        ],
      ),
    );
  }
}

class CallToActionSection extends StatelessWidget {
  const CallToActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: GlassCard(
        borderColor: AppColors.accentCyan.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            const Text(
              'Have a project in mind?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Let’s build something extraordinary together. Available for full-cycle apps, UI/UX architecture, and consults.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Initiate Contact',
              icon: Icons.chat_bubble_outline,
              onPressed: () => context.go('/contact'),
            ),
          ],
        ),
      ),
    );
  }
}
