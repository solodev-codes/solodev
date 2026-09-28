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

  static const List<({String label, String path})> _links = <({
    String label,
    String path,
  })>[
    (label: 'Home', path: '/'),
    (label: 'About', path: '/about'),
    (label: 'Services', path: '/services'),
    (label: 'Projects', path: '/projects'),
    (label: 'Experience', path: '/experience'),
    (label: 'Achievements', path: '/achievements'),
    (label: 'Certificates', path: '/certificates'),
    (label: 'Contact', path: '/contact'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(portfolioSettingsProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppConstants.mobileBreakpoint;
    final isDesktop = width >= AppConstants.tabletBreakpoint;
    final social = _socialButtons(context, settings);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
      ),
      // The footer is the last thing on the page, so it must clear the home
      // indicator on phones and tablets.
      child: SafeArea(
        top: false,
        child: ResponsiveContainer(
          // Horizontal padding comes from ResponsiveContainer; adding it here
          // too would double the gutter on every viewport.
          padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48),
          child: Column(
            children: [
              if (isDesktop)
                // Side by side: the brand block takes the slack, the social row
                // keeps its natural size on the trailing edge.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _brandBlock(CrossAxisAlignment.start)),
                    if (social.isNotEmpty) ...[
                      const SizedBox(width: AppConstants.space24),
                      Flexible(child: _socialRow(social, end: true)),
                    ],
                  ],
                )
              else ...[
                // Stacked and centred, because a row of social buttons beside
                // the brand text overflows a narrow viewport.
                _brandBlock(CrossAxisAlignment.center, centered: true),
                if (social.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.space20),
                  _socialRow(social),
                ],
              ],
              SizedBox(height: isMobile ? 24 : 32),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final link in _links) _FooterLink(link: link),
                ],
              ),
              const SizedBox(height: AppConstants.space24),
              const Divider(color: AppColors.darkCardBorder),
              const SizedBox(height: AppConstants.space16),
              Text(
                '© ${DateTime.now().year} Solodev. All rights reserved. '
                'Built with Flutter & Firebase.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo, wordmark and the one-line positioning statement.
  Widget _brandBlock(CrossAxisAlignment alignment, {bool centered = false}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 32),
            SizedBox(width: 8),
            Text(
              'SOLODEV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.space12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'Futuristic Cross-Platform Developer & AI Designer.\n'
            'Engineering scalable digital products.',
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Only the channels the administrator has actually configured are rendered
  /// (spec section 52). Fixed-size tap targets keep the row predictable at
  /// every width.
  List<Widget> _socialButtons(BuildContext context, settings) {
    if (settings == null) return const <Widget>[];

    return <Widget>[
      if (settings.githubUrl.isNotEmpty)
        _socialButton(
          icon: const FaIcon(FontAwesomeIcons.github, size: 18),
          tooltip: 'GitHub',
          onPressed: () => _launch(settings.githubUrl),
        ),
      if (settings.linkedinUrl.isNotEmpty)
        _socialButton(
          icon: const FaIcon(FontAwesomeIcons.linkedin, size: 18),
          tooltip: 'LinkedIn',
          onPressed: () => _launch(settings.linkedinUrl),
        ),
      if (settings.xUrl.isNotEmpty)
        _socialButton(
          icon: const FaIcon(FontAwesomeIcons.xTwitter, size: 18),
          tooltip: 'X / Twitter',
          onPressed: () => _launch(settings.xUrl),
        ),
      if (settings.whatsappNumber.isNotEmpty)
        _socialButton(
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
          tooltip: 'WhatsApp',
          onPressed: () {
            final digits =
                settings.whatsappNumber.replaceAll(RegExp(r'\D'), '');
            _launch('https://wa.me/$digits');
          },
        ),
      if (settings.contactEmail.isNotEmpty)
        _socialButton(
          icon: const Icon(Icons.mail_outline_rounded, size: 20),
          tooltip: 'Email',
          onPressed: () => _launch('mailto:${settings.contactEmail}'),
        ),
      _socialButton(
        icon: const Icon(Icons.terminal, size: 20),
        tooltip: 'Projects',
        onPressed: () => context.go('/projects'),
      ),
      _socialButton(
        icon: const Icon(Icons.mail, size: 20),
        tooltip: 'Contact',
        onPressed: () => context.go('/contact'),
      ),
    ];
  }

  /// The social buttons wrap onto a second line instead of forcing the
  /// surrounding row wider than the viewport.
  Widget _socialRow(List<Widget> buttons, {bool end = false}) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: end ? WrapAlignment.end : WrapAlignment.center,
      children: buttons,
    );
  }

  Widget _socialButton({
    required Widget icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: icon,
        color: AppColors.accentCyan,
        tooltip: tooltip,
        onPressed: onPressed,
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
  const _FooterLink({required this.link});

  final ({String label, String path}) link;

  @override
  Widget build(BuildContext context) {
    final active = link.path == '/'
        ? GoRouterState.of(context).uri.path == '/'
        : GoRouterState.of(context).uri.path.startsWith(link.path);

    return TextButton(
      onPressed: () => context.go(link.path),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        link.label,
        style: TextStyle(
          color: active ? AppColors.accentCyan : AppColors.textSecondaryDark,
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

