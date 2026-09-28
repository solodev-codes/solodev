import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';

class ServicesSection extends StatelessWidget {
  final AsyncValue servicesAsync;
  const ServicesSection({super.key, required this.servicesAsync});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionHeader(
            tag: 'Capabilities',
            title: 'Engineering & Creative Services',
            subtitle: 'High-performance cross-platform apps backed by robust cloud infrastructure.',
          ),
          const SizedBox(height: 40),
          servicesAsync.when(
            data: (services) {
              return LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: services.map<Widget>((s) {
                    return SizedBox(
                      width: isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                      child: GlassCard(
                        onTap: () => context.go('/services/${s.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.code, color: AppColors.accentCyan, size: 28),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.shortDescription,
                              style: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 14,
                                height: 1.5,
                              ),
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
            error: (_, __) => const Text('Unable to load services at this time.'),
          ),
        ],
      ),
    );
  }
}
