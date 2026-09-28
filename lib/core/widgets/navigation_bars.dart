import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import 'brand_logo.dart';
import '../../features/search/global_search_dialog.dart';

class PublicNavbar extends StatelessWidget implements PreferredSizeWidget {
  const PublicNavbar({super.key});

  /// The bar height scales with the viewport, so the header never feels cramped
  /// on a phone nor oversized on a desktop.
  static double _barHeight(double width) {
    if (width >= AppConstants.tabletBreakpoint) return 72;
    if (width >= AppConstants.mobileBreakpoint) return 64;
    return 60;
  }

  @override
  Size get preferredSize => Size.fromHeight(_barHeight(_viewportWidth()));

  /// Viewport width without needing a [BuildContext], which the AppBar reads
  /// this value through before the widget is built.
  static double _viewportWidth() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize.width / view.devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Below 360 logical pixels even the wordmark no longer fits beside the
    // drawer button and the search action, so the mark stands on its own.
    final showWordmark = width >= 360;

    return AppBar(
      toolbarHeight: _barHeight(width),
      titleSpacing: width < AppConstants.mobileBreakpoint ? 12 : 20,
      // The title must NOT be wrapped in Flexible: AppBar lays its title out in
      // a box-based slot, so a FlexParentData throws "Incorrect use of
      // ParentDataWidget" and release builds replace the whole title with a grey
      // error box. Truncation is handled inside _Brand instead, where the Row is
      // a real Flex parent.
      title: _Brand(
        showWordmark: showWordmark,
        onTap: () => context.go('/'),
      ),
      actions: _actionsFor(context, width),
    );
  }

  /// Picks a link set that is guaranteed to fit.
  ///
  /// The eight-destination bar needs roughly 1,100 px once the brand, drawer
  /// button, search and call-to-action are accounted for, so the destinations
  /// are revealed progressively and the rest live behind the overflow menu.
  List<Widget> _actionsFor(BuildContext context, double width) {
    final isMobile = width < AppConstants.mobileBreakpoint;
    final dense = width < 820;
    final showAllLinks = width >= AppConstants.wideNavBreakpoint;
    final showPrimaryLinks = width >= 900;

    return [
      if (showAllLinks) ...const <Widget>[
          _NavLink(label: 'Home', path: '/'),
          _NavLink(label: 'About', path: '/about'),
          _NavLink(label: 'Services', path: '/services'),
          _NavLink(label: 'Projects', path: '/projects'),
          _NavLink(label: 'Experience', path: '/experience'),
          _NavLink(label: 'Achievements', path: '/achievements'),
          _NavLink(label: 'Certificates', path: '/certificates'),
          _NavLink(label: 'Contact', path: '/contact'),
        ] else if (showPrimaryLinks) ...const <Widget>[
          _NavLink(label: 'Home', path: '/'),
          _NavLink(label: 'Projects', path: '/projects'),
          _MoreMenu(),
        ] else if (!isMobile) ...const <Widget>[
          _NavLink(label: 'Projects', path: '/projects'),
          _MoreMenu(),
        ],
      if (!isMobile) ...[
        const SizedBox(width: 4),
        _HireButton(compact: dense),
      ],
      IconButton(
        tooltip: 'Search portfolio',
        onPressed: () => GlobalSearchDialog.show(context),
        icon: const Icon(Icons.search_rounded, color: AppColors.accentCyan),
      ),
      SizedBox(width: isMobile ? 4 : 12),
    ];
  }
}

/// The wordmark is split in two spans so the "DEV" half carries the accent.
class _Brand extends StatelessWidget {
  const _Brand({required this.onTap, required this.showWordmark});

  final VoidCallback onTap;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return InkWell(
      // Administrator entry point: deliberately undiscoverable. A long-press
      // on the brand mark opens the login route rather than advertising the
      // admin surface to every visitor.
      onLongPress: () => context.go('/admin/login'),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(size: isMobile ? 32 : 38),
          if (showWordmark) ...[
            SizedBox(width: isMobile ? 8 : 10),
            Flexible(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: isMobile ? 0.3 : 0.5,
                    color: Colors.white,
                  ),
                  children: const [
                    TextSpan(text: 'SOLO'),
                    TextSpan(
                      text: 'DEV',
                      style: TextStyle(color: AppColors.accentCyan),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Primary call to action; tightens its own padding on narrow viewports.
class _HireButton extends StatelessWidget {
  const _HireButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveLayout.isMobile(context) ? 10 : 14),
      child: ElevatedButton(
        onPressed: () => context.go('/contact'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Hire Me',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: compact ? 13 : 14,
          ),
        ),
      ),
    );
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

  /// Whether [path] is the section currently on screen. `/` only matches
  /// exactly, so it does not stay lit while browsing nested routes.
  bool _isActive(String location) =>
      path == '/' ? location == '/' : location.startsWith(path);

  @override
  Widget build(BuildContext context) {
    final active = _isActive(GoRouterState.of(context).uri.path);
    final dense = MediaQuery.sizeOf(context).width < 820;

    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.accentCyan : AppColors.textPrimaryDark,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: dense ? 14 : 15,
            ),
          ),
          // A short rule under the active destination, rather than shifting the
          // bar when it appears.
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: active ? 18 : 0,
            decoration: BoxDecoration(
              color: AppColors.accentCyan,
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
          ),
        ],
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
