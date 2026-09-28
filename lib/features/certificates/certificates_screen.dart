import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(publishedCertificatesProvider);

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: const ResponsiveContainer(
                child: SectionHeader(
                  tag: 'Credentials',
                  title: 'Certifications & Accreditations',
                  subtitle: 'Continuous mastery across Flutter, Cloud Architecture, and Modern Engineering.',
                ),
              ),
            ),
            ResponsiveContainer(
              child: certsAsync.when(
                data: (certs) {
                  if (certs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'Verified certificates and accreditations will be showcased here.',
                          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: certs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final cert = certs[index];
                      return GlassCard(
                        onTap: () => context.go('/certificates/${cert.id}'),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cert.imageUrl.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Image.network(
                                      cert.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                        color: AppColors.darkSurface,
                                        child: Icon(
                                          Icons.workspace_premium_outlined,
                                          color: AppColors.textSecondaryDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cert.issuer.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accentCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cert.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cert.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textSecondaryDark),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondaryDark,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading certificates.'),
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
