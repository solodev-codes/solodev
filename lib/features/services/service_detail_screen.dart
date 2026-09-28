import '../../core/services/analytics_service.dart';
import '../../core/services/seo/seo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../core/widgets/service_icon.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/service_model.dart';

/// Public detail page for a single service.
///
/// Every field of [ServiceModel] is surfaced. Each block carries its own data
/// check, so a service that has not been filled in completely never renders an
/// empty heading, blank image or stray divider.
class ServiceDetailScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(publishedServicesProvider);

    // Names the service in the page title once it loads, e.g.
    // "Flutter App Development | Solodev" (spec section 44).
    _publishServiceMetadata(servicesAsync, serviceId);
    ref.listen<AsyncValue<List<ServiceModel>>>(
      publishedServicesProvider,
      (_, next) => _publishServiceMetadata(next, serviceId),
    );

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ServiceNotFound(),
        data: (services) {
          // Match strictly: rendering a different service under this URL would
          // be worse than an honest not-found state.
          final index = services.indexWhere((s) => s.id == serviceId);
          if (index == -1) return const _ServiceNotFound();
          final service = services[index];
          AnalyticsService.logServiceView(
            serviceId: service.id,
            title: service.title,
          );

          // Trimmed and blank-filtered, so a stray empty line in the editor
          // can never render an empty bullet or chip.
          final technologies = _clean(service.technologies);
          final features = _clean(service.features);
          final process = _clean(service.process);
          final benefits = _clean(service.benefits);
          final description = service.fullDescription.trim();
          final coverImage = service.coverImage.trim();
          final shortDescription = service.shortDescription.trim();

          return SingleChildScrollView(
            child: Column(
              children: [
                _ServiceHero(
                  service: service,
                  shortDescription: shortDescription,
                ),
                const SizedBox(height: 40),
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coverImage.isNotEmpty) ...[
                        _ServiceCover(imageUrl: coverImage),
                        const SizedBox(height: AppConstants.space32),
                      ],
                      if (description.isNotEmpty) ...[
                        const _ServiceSectionTitle('Overview'),
                        const SizedBox(height: AppConstants.space12),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondaryDark,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppConstants.space32),
                      ],
                      if (technologies.isNotEmpty) ...[
                        const _ServiceSectionTitle('Built with'),
                        const SizedBox(height: AppConstants.space12),
                        Wrap(
                          spacing: AppConstants.space8,
                          runSpacing: AppConstants.space8,
                          children: [
                            for (final tech in technologies)
                              _ServiceChip(label: tech),
                          ],
                        ),
                        const SizedBox(height: AppConstants.space32),
                      ],
                      if (features.isNotEmpty) ...[
                        const _ServiceSectionTitle('What is included'),
                        const SizedBox(height: AppConstants.space12),
                        for (final feature in features)
                          _ServiceBullet(
                            icon: Icons.check_circle_outline_rounded,
                            text: feature,
                          ),
                        const SizedBox(height: AppConstants.space32),
                      ],
                      if (process.isNotEmpty) ...[
                        const _ServiceSectionTitle('How I work'),
                        const SizedBox(height: AppConstants.space12),
                        for (var i = 0; i < process.length; i++)
                          _ServiceStep(index: i + 1, text: process[i]),
                        const SizedBox(height: AppConstants.space32),
                      ],
                      if (benefits.isNotEmpty) ...[
                        const _ServiceSectionTitle('Benefits'),
                        const SizedBox(height: AppConstants.space12),
                        Wrap(
                          spacing: AppConstants.space16,
                          runSpacing: AppConstants.space16,
                          children: [
                            for (final benefit in benefits)
                              _ServiceBenefit(text: benefit),
                          ],
                        ),
                        const SizedBox(height: AppConstants.space32),
                      ],
                      const _ServiceCallToAction(),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                const PublicFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Trims each entry and drops the blank ones.
  static List<String> _clean(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
}


/// Hero header: icon, title, featured flag, summary and the last update date.
class _ServiceHero extends StatelessWidget {
  const _ServiceHero({required this.service, required this.shortDescription});

  final ServiceModel service;
  final String shortDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/services'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Services'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Icon(
                    serviceIconData(service.iconName),
                    color: AppColors.accentCyan,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppConstants.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service.isFeatured) ...[
                        const _ServiceChip(label: 'Featured', filled: true),
                        const SizedBox(height: AppConstants.space8),
                      ],
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (shortDescription.isNotEmpty) ...[
              const SizedBox(height: AppConstants.space12),
              Text(
                shortDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.space12),
            Wrap(
              spacing: AppConstants.space16,
              runSpacing: AppConstants.space8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        size: 14, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'Added ${DateFormat.yMMMd().format(service.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.update_rounded,
                        size: 14, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'Updated ${DateFormat.yMMMd().format(service.updatedAt)}',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cover image, only built when the service actually has one.
class _ServiceCover extends StatelessWidget {
  const _ServiceCover({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() {
      return Container(
        color: AppColors.accentCyan.withValues(alpha: 0.06),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondaryDark,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      ),
    );
  }
}

class _ServiceSectionTitle extends StatelessWidget {
  const _ServiceSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.accentCyan.withValues(alpha: 0.16)
            : Colors.transparent,
        border: Border.all(
          color: filled
              ? AppColors.accentCyan
              : AppColors.textSecondaryDark.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? AppColors.accentCyan : AppColors.textSecondaryDark,
          fontSize: 12,
          fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// One tick-marked line, used for the feature list.
class _ServiceBullet extends StatelessWidget {
  const _ServiceBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentCyan),
          const SizedBox(width: AppConstants.space12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A numbered step of the delivery process.
class _ServiceStep extends StatelessWidget {
  const _ServiceStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.accentCyan.withValues(alpha: 0.15),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.space12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single benefit card.
class _ServiceBenefit extends StatelessWidget {
  const _ServiceBenefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppColors.accentCyan),
            const SizedBox(width: AppConstants.space12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Closing call to action shown after the content blocks.
class _ServiceCallToAction extends StatelessWidget {
  const _ServiceCallToAction();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Need this solution for your product?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          AppButton(
            label: 'Hire Solodev',
            onPressed: () => context.go('/contact'),
          ),
        ],
      ),
    );
  }
}

/// Shown for an unknown, unpublished or unreachable service id.
class _ServiceNotFound extends StatelessWidget {
  const _ServiceNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Service not found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This service may have been unpublished or removed.',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Back to Services',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.go('/services'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puts the loaded service into the page metadata (spec section 44).
///
/// Applied explicitly for the current value and again from the listener, because
/// Riverpod 2's `Ref.listen` does not support `fireImmediately`.
void _publishServiceMetadata(
  AsyncValue<List<ServiceModel>> value,
  String serviceId,
) {
  for (final service in value.valueOrNull ?? const <ServiceModel>[]) {
    if (service.id != serviceId) continue;
    SeoService.applyDetailPage(
      title: service.title,
      description: service.shortDescription,
    );
    return;
  }
}
