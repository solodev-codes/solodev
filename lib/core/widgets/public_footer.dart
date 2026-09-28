import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import 'brand_logo.dart';
import '../../data/datasources/portfolio_providers.dart';

class PublicFooter extends ConsumerWidget {
  const PublicFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(portfolioSettingsProvider).valueOrNull;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: ResponsiveContainer(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandLogo(size: 32),
                          const SizedBox(width: 8),
                          const Text(
                            'SOLODEV',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Futuristic Cross-Platform Developer & AI Designer.\nEngineering scalable digital products.',
                        style: TextStyle(
                            color: AppColors.textSecondaryDark, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (settings != null && settings.githubUrl.isNotEmpty)
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.github, size: 18),
                        color: AppColors.accentCyan,
                        tooltip: 'GitHub',
                        onPressed: () => _launch(settings.githubUrl),
                      ),
                    if (settings != null && settings.linkedinUrl.isNotEmpty)
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.linkedin, size: 18),
                        color: AppColors.accentCyan,
                        tooltip: 'LinkedIn',
                        onPressed: () => _launch(settings.linkedinUrl),
                      ),
                    if (settings != null && settings.xUrl.isNotEmpty)
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.xTwitter, size: 18),
                        color: AppColors.accentCyan,
                        tooltip: 'X / Twitter',
                        onPressed: () => _launch(settings.xUrl),
                      ),
                    if (settings != null && settings.whatsappNumber.isNotEmpty)
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                        color: AppColors.accentCyan,
                        tooltip: 'WhatsApp',
                        onPressed: () {
                          final digits = settings.whatsappNumber.replaceAll(RegExp(r'\D'), '');
                          _launch('https://wa.me/$digits');
                        },
                      ),
                    if (settings != null && settings.contactEmail.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.mail_outline_rounded, size: 20),
                        color: AppColors.accentCyan,
                        tooltip: 'Email',
                        onPressed: () => _launch('mailto:${settings.contactEmail}'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.terminal, color: AppColors.accentCyan),
                      tooltip: 'Projects',
                      onPressed: () => context.go('/projects'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mail, color: AppColors.accentCyan),
                      tooltip: 'Contact',
                      onPressed: () => context.go('/contact'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: const [
                _FooterLink(label: 'Home', path: '/'),
                _FooterLink(label: 'About', path: '/about'),
                _FooterLink(label: 'Services', path: '/services'),
                _FooterLink(label: 'Projects', path: '/projects'),
                _FooterLink(label: 'Experience', path: '/experience'),
                _FooterLink(label: 'Achievements', path: '/achievements'),
                _FooterLink(label: 'Certificates', path: '/certificates'),
                _FooterLink(label: 'Contact', path: '/contact'),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.darkCardBorder),
            const SizedBox(height: 16),
            const Text(
              '© 2026 Solodev. All rights reserved. Built with Flutter & Firebase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static void _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Text-style navigation link used in the public footer.
class _FooterLink extends StatelessWidget {
  final String label;
  final String path;

  const _FooterLink({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

