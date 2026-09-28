import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/brand_logo.dart';
import '../../data/datasources/portfolio_providers.dart';

class HeroSection extends ConsumerWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final settingsAsync = ref.watch(portfolioSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    final title = (settings != null && settings.heroTitle.trim().isNotEmpty)
        ? settings.heroTitle.trim()
        : 'Flutter Developer\n& AI Designer';

    final subtitle = (settings != null && settings.heroSubtitle.trim().isNotEmpty)
        ? settings.heroSubtitle.trim()
        : AppConstants.appSubheading;

    final availableForHire = settings?.availableForHire ?? true;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.darkHeroGradient),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 80,
        horizontal: 24,
      ),
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The brand leads the hero: the mark, then the availability
            // signal, then the headline.
            Animate(
              key: const Key('hero_brand'),
              child: BrandHeroMark(size: isMobile ? 104 : 148),
            ).scale(
              begin: const Offset(0.82, 0.82),
              curve: Curves.easeOutBack,
              alignment: Alignment.center,
              duration: 700.ms,
            ).fadeIn(
              duration: 600.ms,
            ),
            const SizedBox(height: 28),
            if (availableForHire) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: AppColors.accentCyan, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'AVAILABLE FOR CONTRACTS & ARCHITECTURE',
                      style: TextStyle(
                        color: AppColors.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 36 : 64,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1.1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondaryDark,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                AppButton(
                  label: 'Explore Projects',
                  icon: Icons.rocket_launch,
                  onPressed: () => context.go('/projects'),
                ),
                AppButton(
                  label: 'Get In Touch',
                  icon: Icons.send,
                  isSecondary: true,
                  onPressed: () => context.go('/contact'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

