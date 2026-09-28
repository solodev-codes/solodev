import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import 'brand_logo.dart';
import '../../features/search/global_search_dialog.dart';

class PublicNavbar extends StatelessWidget implements PreferredSizeWidget {
  const PublicNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return AppBar(
      title: InkWell(
        // Administrator entry point: deliberately undiscoverable. A long-press
        // on the brand mark opens the login route rather than advertising the
        // admin surface to every visitor.
        onLongPress: () => context.go('/admin/login'),
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 36),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'SOLO'),
                  TextSpan(
                    text: 'DEV',
                    style: TextStyle(color: AppColors.accentCyan),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: isMobile
          ? _mobileActions(context)
          : _desktopActions(context, MediaQuery.sizeOf(context).width),
    );
  }

  /// Mobile keeps a single discoverable entry point to global search; every
  /// other destination lives in [PublicDrawer].
  List<Widget> _mobileActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Search portfolio',
        onPressed: () => GlobalSearchDialog.show(context),
        icon: const Icon(Icons.search_rounded, color: AppColors.accentCyan),
      ),
      const SizedBox(width: 4),
    ];
  }

  /// Adaptive desktop actions: the full link row only renders on wide
  /// viewports, otherwise the overflow collapses into an overflow menu so the
  /// AppBar can never overflow horizontally.
  List<Widget> _desktopActions(BuildContext context, double width) {
    final isWide = width >= AppConstants.wideNavBreakpoint;

    return [
      if (isWide) ...[
        _NavLink(label: 'Home', path: '/'),
        _NavLink(label: 'About', path: '/about'),
        _NavLink(label: 'Services', path: '/services'),
        _NavLink(label: 'Projects', path: '/projects'),
        _NavLink(label: 'Experience', path: '/experience'),
        _NavLink(label: 'Achievements', path: '/achievements'),
        _NavLink(label: 'Certificates', path: '/certificates'),
        _NavLink(label: 'Contact', path: '/contact'),
      ] else ...[
        _NavLink(label: 'Home', path: '/'),
        _NavLink(label: 'Projects', path: '/projects'),
        _NavLink(label: 'Contact', path: '/contact'),
        const _MoreMenu(),
      ],
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Search portfolio',
        onPressed: () => GlobalSearchDialog.show(context),
        icon: const Icon(Icons.search_rounded, color: AppColors.accentCyan),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: ElevatedButton(
          onPressed: () => context.go('/contact'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Text('Hire Me',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 16),
    ];
  }
}

/// Overflow menu holding the destinations that do not fit in the compact bar.
class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    const items = <({String label, String path})>[
      (label: 'About', path: '/about'),
      (label: 'Services', path: '/services'),
      (label: 'Experience', path: '/experience'),
      (label: 'Achievements', path: '/achievements'),
      (label: 'Certificates', path: '/certificates'),
    ];

    return PopupMenuButton<String>(
      tooltip: 'More pages',
      color: AppColors.darkCard,
      onSelected: (path) => context.go(path),
      itemBuilder: (context) => items
          .map((item) => PopupMenuItem<String>(
                value: item.path,
                child: Text(item.label,
                    style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Icon(Icons.expand_more, color: AppColors.textPrimaryDark, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String path;

  const _NavLink({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(path),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

class PublicDrawer extends StatelessWidget {
  const PublicDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        children: [
          Row(
            children: [
              const BrandLogo(size: 40),
              const SizedBox(width: 12),
              const Text(
                'SOLODEV',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: AppColors.darkCardBorder),
          ListTile(
            leading: const Icon(Icons.search_rounded, color: AppColors.accentCyan),
            title: const Text('Search'),
            onTap: () {
              Navigator.pop(context);
              GlobalSearchDialog.show(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: AppColors.accentCyan),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.accentCyan),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              context.go('/about');
            },
          ),
          ListTile(
            leading: const Icon(Icons.design_services_outlined, color: AppColors.accentCyan),
            title: const Text('Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/services');
            },
          ),
          ListTile(
            leading: const Icon(Icons.rocket_launch_outlined, color: AppColors.accentCyan),
            title: const Text('Projects'),
            onTap: () {
              Navigator.pop(context);
              context.go('/projects');
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_history_outlined, color: AppColors.accentCyan),
            title: const Text('Experience'),
            onTap: () {
              Navigator.pop(context);
              context.go('/experience');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined, color: AppColors.accentCyan),
            title: const Text('Achievements'),
            onTap: () {
              Navigator.pop(context);
              context.go('/achievements');
            },
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.accentCyan),
            title: const Text('Certificates'),
            onTap: () {
              Navigator.pop(context);
              context.go('/certificates');
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: AppColors.accentCyan),
            title: const Text('Contact'),
            onTap: () {
              Navigator.pop(context);
              context.go('/contact');
            },
          ),
        ],
      ),
    );
  }
}
