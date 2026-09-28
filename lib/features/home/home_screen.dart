import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';
import '../../data/models/project_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/testimonial_model.dart';
import 'hero_section.dart';
import 'home_extra_sections.dart';
import 'services_section.dart';
import 'projects_cta_sections.dart';
import 'testimonials_section.dart';

/// The homepage renders hero + an admin-controlled sequence of sections
/// (spec sections 23/51). The hero and footer are structural: only the
/// sections in `PortfolioSettingsModel.homeSections` are reorderable.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(publishedServicesProvider);
    final projectsAsync = ref.watch(publishedProjectsProvider);
    final testimonialsAsync = ref.watch(publishedTestimonialsProvider);
    // Until settings load (or if the read fails) the default order is shown so
    // the homepage is never blank.
    final order = ref.watch(portfolioSettingsProvider).valueOrNull?.homeSections ??
        kDefaultHomeSections;
    // Section rhythm tightens on phones so the first two sections still sit
    // above the fold.
    final gap = MediaQuery.sizeOf(context).width < AppConstants.mobileBreakpoint
        ? AppConstants.space32
        : AppConstants.space48;

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HeroSection(),
            for (final id in order) ...[
              SizedBox(height: gap),
              _sectionFor(
                id,
                servicesAsync: servicesAsync,
                projectsAsync: projectsAsync,
                testimonialsAsync: testimonialsAsync,
              ),
            ],
            const SizedBox(height: AppConstants.space48),
            const PublicFooter(),
          ],
        ),
      ),
    );
  }

  Widget _sectionFor(
    String id, {
    required AsyncValue<List<ServiceModel>> servicesAsync,
    required AsyncValue<List<ProjectModel>> projectsAsync,
    required AsyncValue<List<TestimonialModel>> testimonialsAsync,
  }) {
    switch (id) {
      case 'services':
        return ServicesSection(servicesAsync: servicesAsync);
      case 'projects':
        return ProjectsSection(projectsAsync: projectsAsync);
      case 'certificates':
        return const CertificatesSection();
      case 'achievements':
        return const AchievementsSection();
      case 'testimonials':
        return TestimonialsSection(testimonialsAsync: testimonialsAsync);
      case 'cta':
        return const CallToActionSection();
      default:
        // Unknown ids are filtered in the model; ignore anything unexpected.
        return const SizedBox.shrink();
    }
  }
}

