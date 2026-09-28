import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/testimonial_model.dart';

/// The homepage testimonial wall (spec sections 9/23). Renders nothing while
/// no testimonials are published so the section never shows an empty frame.
class TestimonialsSection extends ConsumerWidget {
  const TestimonialsSection({super.key, required this.testimonialsAsync});

  final AsyncValue<List<TestimonialModel>> testimonialsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonials =
        testimonialsAsync.valueOrNull ?? const <TestimonialModel>[];
    if (testimonials.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SectionHeader(
            tag: 'Testimonials',
            title: 'Words from my clients',
            subtitle: 'Real feedback from the people and teams I have '
                'partnered with.',
          ),
          const SizedBox(height: AppConstants.space32),
          Wrap(
            spacing: AppConstants.space24,
            runSpacing: AppConstants.space24,
            alignment: WrapAlignment.center,
            children: [for (final t in testimonials) _card(t)],
          ),
        ],
      ),
    );
  }

  Widget _card(TestimonialModel item) {
    final initials = item.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote_rounded,
                color: AppColors.accentCyan, size: 28),
            const SizedBox(height: AppConstants.space12),
            Text(
              item.content,
              style: const TextStyle(color: Colors.white, height: 1.6),
            ),
            const SizedBox(height: AppConstants.space16),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= item.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: const Color(0xFFFBBF24),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.space16),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppColors.accentCyan.withValues(alpha: 0.15),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.role.isNotEmpty)
                        Text(
                          item.role,
                          style: const TextStyle(
                            color: AppColors.accentCyan,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}