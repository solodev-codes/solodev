import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../core/services/messaging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/responsive/responsive_text.dart';
import '../../core/widgets/app_widgets.dart';

/// Width of the persistent desktop sidebar.
const double _kSidebarWidth = 250;

/// A single admin navigation destination.
class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;

  /// Destinations available in this build.
  ///
  /// Kept as a single source of truth so the sidebar, the drawer and any
  /// future quick-action menu cannot drift apart. Phase C extends this list
  /// as further admin routes are added.
  static const List<AdminNavItem> items = <AdminNavItem>[
    AdminNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      path: '/admin/dashboard',
    ),
    AdminNavItem(
      label: 'Messages',
      icon: Icons.mail_outline,
      path: '/admin/messages',
    ),
    AdminNavItem(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      path: '/admin/notifications',
    ),
    AdminNavItem(
      label: 'Projects',
      icon: Icons.folder_outlined,
      path: '/admin/projects',
    ),
    AdminNavItem(
      label: 'Site settings',
      icon: Icons.tune_rounded,
      path: '/admin/settings',
    ),
    AdminNavItem(
      label: 'Skills',
      icon: Icons.bolt_outlined,
      path: '/admin/skills',
    ),
    AdminNavItem(
      label: 'Achievements',
      icon: Icons.emoji_events_outlined,
      path: '/admin/achievements',
    ),
    AdminNavItem(
      label: 'Certificates',
      icon: Icons.workspace_premium_outlined,
      path: '/admin/certificates',
    ),
    AdminNavItem(
      label: 'Testimonials',
      icon: Icons.format_quote_rounded,
      path: '/admin/testimonials',
    ),
    AdminNavItem(
      label: 'Experience',
      icon: Icons.work_outline_rounded,
      path: '/admin/experience',
    ),
    AdminNavItem(
      label: 'Services',
      icon: Icons.design_services_outlined,
      path: '/admin/services',
    ),
  ];
}

/// A headline metric tile for the dashboard (spec section 8).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.accentCyan,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppConstants.space16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.space8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppConstants.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared chrome for every admin screen: sidebar on desktop, drawer below it.
///
/// Putting navigation here rather than in each screen means a new admin page
/// is one `body:` away and can never ship without consistent navigation,
/// sign-out or a route back to the live site.
/// Section heading with an optional trailing action, shared by every admin
/// list screen.
///
/// The title is [Expanded] with an ellipsis, so a long collection name can
/// never push the action off a narrow screen — the previous inline `Row` plus
/// `Spacer` could.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.fontSize = 20,
  });

  final String title;
  final Widget? trailing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveText.sizeOf(context, fontSize),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppConstants.space8),
          trailing!,
        ],
      ],
    );
  }
}

/// Cancel/save row for the editor sheets.
///
/// The save button is [Flexible] and the cancel label is [Expanded], so on a
/// narrow phone the row shrinks inside its bounds instead of overflowing once
/// the device type scale is applied.
class AdminEditorActions extends StatelessWidget {
  const AdminEditorActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
    this.isSaving = false,
    this.cancelLabel = 'Cancel',
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool isSaving;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: isSaving ? null : onCancel,
              child: Text(cancelLabel, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.space8),
        Flexible(
          child: AppButton(
            label: saveLabel,
            icon: Icons.check_rounded,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
        ),
      ],
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  static Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    MessagingService.showForegroundMessages(context);
    final useSidebar = ResponsiveLayout.isDesktop(context);
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          ...actions,
          const _AdminNotificationBell(),
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'View live portfolio',
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
          ),
          const SizedBox(width: AppConstants.space4),
        ],
      ),
      drawer: useSidebar
          ? null
          : Drawer(
              backgroundColor: AppColors.darkCard,
              child: _AdminNav(currentPath: location),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (useSidebar)
            Container(
              width: _kSidebarWidth,
              decoration: const BoxDecoration(
                color: AppColors.darkCard,
                border: Border(
                  right: BorderSide(color: AppColors.darkCardBorder),
                ),
              ),
              child: const _AdminNav(),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminNav extends StatelessWidget {
  const _AdminNav({this.currentPath});

  final String? currentPath;

  @override
  Widget build(BuildContext context) {
    // In a drawer the location may not be available from context, so fall back
    // to the router instance.
    final path =
        currentPath ?? GoRouter.of(context).state.uri.path;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppConstants.space20),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.accentCyan),
                SizedBox(width: AppConstants.space8),
                Text(
                  'Solodev Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.darkCardBorder, height: 1),
          const SizedBox(height: AppConstants.space8),
          for (final item in AdminNavItem.items)
            _AdminNavTile(item: item, selected: path == item.path),
          const Spacer(),
          const Divider(color: AppColors.darkCardBorder, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.textSecondaryDark),
            title: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({required this.item, required this.selected});

  final AdminNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected ? AppColors.accentCyan : AppColors.textSecondaryDark,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondaryDark,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.accentCyan.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      onTap: () {
        // Close the drawer before navigating, otherwise the route change is
        // hidden behind it.
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        context.go(item.path);
      },
    );
  }
}

/// Asks the administrator to confirm a destructive action (spec section 9).
///
/// Returns `true` only when the confirm button was pressed. Cancel and
/// dismissing the dialog both count as a refusal.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.darkCard,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondaryDark),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
/// Runs a repository mutation, turning any failure into a visible snack bar.
///
/// Admin screens must never swallow a write failure, and the messenger is
/// captured before the await so the call does not use a stale context.
Future<void> runGuarded(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
  String failurePrefix = 'The action failed',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (successMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.darkCardBorder,
        ),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('$failurePrefix: $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
/// Notification bell with badge showing unread notification count.
class _AdminNotificationBell extends ConsumerWidget {
  const _AdminNotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(adminNotificationsStreamProvider);

    return notificationsAsync.maybeWhen(
      data: (docs) {
        final unreadCount = docs.where((d) => d.data()['read'] != true).length;
        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            backgroundColor: AppColors.accentCyan,
            textColor: Colors.black,
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: unreadCount > 0
              ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
              : 'Notifications',
          onPressed: () => _showNotificationSheet(context, docs),
        );
      },
      orElse: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        onPressed: () => _showNotificationSheet(context, const []),
      ),
    );
  }

  void _showNotificationSheet(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppConstants.space32),
            child: EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message: 'System alerts and incoming contact enquiries will appear here.',
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        context.go('/admin/notifications');
                      },
                      child: const Text('View all'),
                    ),
                    Text(
                      '${docs.length} total',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.darkCardBorder),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.darkCardBorder, height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = data['title'] as String? ?? 'Notification';
                    final body = data['body'] as String? ?? '';
                    final isRead = data['read'] == true;
                    final link = data['link'] as String?;

                    return ListTile(
                      leading: Icon(
                        isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                        color: isRead ? AppColors.textSecondaryDark : AppColors.accentCyan,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        body,
                        style: const TextStyle(color: AppColors.textSecondaryDark),
                      ),
                      trailing: !isRead
                          ? IconButton(
                              icon: const Icon(Icons.done, size: 18, color: AppColors.accentCyan),
                              tooltip: 'Mark as read',
                              onPressed: () async {
                                await doc.reference.update({'read': true});
                              },
                            )
                          : null,
                      onTap: () async {
                        if (!isRead) {
                          await doc.reference.update({'read': true});
                        }
                        if (context.mounted && link != null && link.isNotEmpty) {
                          Navigator.of(bottomSheetContext).pop();
                          context.go(link);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}