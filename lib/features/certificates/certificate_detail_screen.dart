import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/seo/seo_service.dart';
import '../../core/widgets/fullscreen_image_viewer.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';

/// Public detail page for a single certificate: image, issuer, credential
/// details and a verification link (spec section 15).
///
/// Route: `/certificates/:id`.
class CertificateDetailScreen extends ConsumerWidget {
  const CertificateDetailScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(publishedCertificatesProvider);

    // Publishes document-specific metadata once the certificate is loaded
    // (spec section 44); applied for the current value and again from the
    // listener because Riverpod 2's `Ref.listen` has no `fireImmediately`.
    _publishCertificateMetadata(certsAsync, certificateId);
    ref.listen<AsyncValue<List<CertificateModel>>>(
      publishedCertificatesProvider,
      (_, next) => _publishCertificateMetadata(next, certificateId),
    );

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: certsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _CertificateNotFound(),
        data: (certs) {
          final index = certs.indexWhere((c) => c.id == certificateId);
          if (index == -1) return const _CertificateNotFound();
          final cert = certs[index];
          AnalyticsService.logCertificateView(
            certificateId: cert.id,
            title: cert.title,
          );

          final hasImage = cert.imageUrl.trim().isNotEmpty;
          final credentialUrl = (cert.credentialUrl ?? '').trim();
          final issued = DateFormat.yMMMM().format(cert.issueDate);

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.darkSurface,
                  padding: const EdgeInsets.symmetric(
                      vertical: 40, horizontal: 24),
                  child: ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/certificates'),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back to Certificates'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cert.issuer.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cert.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: AppConstants.space16,
                          runSpacing: AppConstants.space8,
                          children: [
                            _metaChip(
                              icon: Icons.calendar_month_outlined,
                              label: 'Issued $issued',
                            ),
                            if (cert.isFeatured)
                              _metaChip(
                                icon: Icons.star_rounded,
                                label: 'Featured',
                                highlighted: true,
                              ),
                            if (cert.credentialId?.trim().isNotEmpty == true)
                              _metaChip(
                                icon: Icons.tag_rounded,
                                label: cert.credentialId!.trim(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasImage)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.space24),
                          child: GestureDetector(
                            onTap: () => FullscreenImageViewer.show(
                              context,
                              images: [cert.imageUrl],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSmall),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  cert.imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null
                                          ? child
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.darkSurface,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textSecondaryDark,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (cert.description.trim().isNotEmpty) ...[
                        Text(
                          cert.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: AppConstants.space24),
                      ],
                      if (cert.skills.isNotEmpty) ...[
                        const Text(
                          'Skills validated',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppConstants.space12),
                        Wrap(
                          spacing: AppConstants.space8,
                          runSpacing: AppConstants.space8,
                          children: [
                            for (final skill in cert.skills)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusFull),
                                  border: Border.all(
                                    color: AppColors.accentCyan
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    color: AppColors.accentCyan,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.space24),
                      ],
                      if (credentialUrl.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () => _openCredential(credentialUrl),
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: const Text('Verify credential'),
                        ),
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

  Widget _metaChip({
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    final color = highlighted ? const Color(0xFFFBBF24) : AppColors.textSecondaryDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Opens the credential URL in the external browser; only `http(s)` links
  /// are ever launched.
  Future<void> _openCredential(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        !uri.hasAuthority) {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A blocked or malformed link must never crash the detail page.
    }
  }
}

class _CertificateNotFound extends StatelessWidget {
  const _CertificateNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 56, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          const Text(
            'This certificate could not be found.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/certificates'),
            child: const Text('Back to Certificates'),
          ),
        ],
      ),
    );
  }
}

/// Puts the loaded certificate into the page metadata (spec section 44).
void _publishCertificateMetadata(
  AsyncValue<List<CertificateModel>> value,
  String certificateId,
) {
  for (final cert in value.valueOrNull ?? const <CertificateModel>[]) {
    if (cert.id != certificateId) continue;
    SeoService.applyDetailPage(
      title: cert.title,
      description: cert.description.trim().isEmpty
          ? '${cert.issuer} certification verified by ${SeoService.siteName}.'
          : cert.description,
    );
    return;
  }
}