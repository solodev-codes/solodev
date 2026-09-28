import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';

/// Compact certificates strip for the homepage (spec section 23, item 8).
class CertificatesSection extends ConsumerWidget {
  const CertificatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificates = ref.watch(publishedCertificatesProvider).valueOrNull ??
        const <CertificateModel>[];
    if (certificates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SectionHeader(
            tag: 'Certificates',
            title: 'Certified skills',
            subtitle: 'Credentials earned through structured, verified study.',
          ),
          const SizedBox(height: AppConstants.space32),
          Wrap(
            spacing: AppConstants.space24,
            runSpacing: AppConstants.space24,
            alignment: WrapAlignment.center,
            children: [
              for (final c in certificates.take(6)) _card(context, c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, CertificateModel item) {
    const fallback = Icon(
      Icons.workspace_premium_outlined,
      size: 42,
      color: AppColors.accentCyan,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        onTap: () => context.go('/certificates/${item.id}'),
        child: GlassCard(
          padding: const EdgeInsets.all(AppConstants.space16),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  child: item.imageUrl.isEmpty
                      ? Container(
                          color: AppColors.accentCyan.withValues(alpha: 0.08),
                          child: fallback,
                        )
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color:
                                AppColors.accentCyan.withValues(alpha: 0.08),
                            child: fallback,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppConstants.space12),
              Text(
                item.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.issuer.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.issuer,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact achievements strip for the homepage (spec section 23, item 9).
class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements =
        ref.watch(publishedAchievementsProvider).valueOrNull ??
            const <AchievementModel>[];
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SectionHeader(
            tag: 'Achievements',
            title: 'Milestones and awards',
            subtitle: 'Moments worth remembering along the way.',
          ),
          const SizedBox(height: AppConstants.space32),
          Wrap(
            spacing: AppConstants.space24,
            runSpacing: AppConstants.space24,
            alignment: WrapAlignment.center,
            children: [
              for (final a in achievements.take(6)) _card(context, a),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, AchievementModel item) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.info.withValues(alpha: 0.15),
                  child: const Icon(Icons.emoji_events_outlined,
                      size: 20, color: AppColors.info),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(item.date),
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space12),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondaryDark, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}