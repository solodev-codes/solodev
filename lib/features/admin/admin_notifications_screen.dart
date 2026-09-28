import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import 'admin_widgets.dart';

/// Admin notification center (§60) displaying system alerts, incoming enquiries,
/// upload events, and direct notifications with read/unread statuses.
class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(adminNotificationsStreamProvider);

    return AdminShell(
      title: 'Notifications',
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text('Compose'),
          onPressed: () => showComposeNotificationDialog(context),
        ),
        notificationsAsync.maybeWhen(
          data: (docs) {
            final unreadDocs =
                docs.where((d) => d.data()['read'] != true).toList();
            if (unreadDocs.isEmpty) return const SizedBox.shrink();
            return TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
              onPressed: () async {
                for (final doc in unreadDocs) {
                  await doc.reference.update({'read': true});
                }
              },
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      child: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(adminNotificationsStreamProvider),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.space32),
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications',
                  message:
                      'System alerts, interaction events, and incoming enquiries will appear here.',
                ),
              ),
            );
          }

          final unreadCount =
              docs.where((d) => d.data()['read'] != true).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications (${docs.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.accentCyan.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '$unreadCount unread',
                          style: const TextStyle(
                            color: AppColors.accentCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.space16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppConstants.space12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = data['title'] as String? ?? 'Notification';
                    final body = data['body'] as String? ?? '';
                    final isRead = data['read'] == true;
                    final type = data['type'] as String? ?? 'general';
                    final link = data['link'] as String?;
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();

                    return GlassCard(
                      padding: const EdgeInsets.all(AppConstants.space16),
                      onTap: () async {
                        if (!isRead) {
                          await doc.reference.update({'read': true});
                        }
                        if (context.mounted &&
                            link != null &&
                            link.isNotEmpty) {
                          context.go(link);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _iconForType(type, isRead),
                            color: isRead
                                ? AppColors.textSecondaryDark
                                : AppColors.accentCyan,
                            size: 24,
                          ),
                          const SizedBox(width: AppConstants.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (createdAt != null)
                                      Text(
                                        DateFormat('MMM d, h:mm a')
                                            .format(createdAt),
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if (type.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryDark,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: AppConstants.space12),
                            IconButton(
                              icon: const Icon(Icons.done_rounded,
                                  size: 20, color: AppColors.accentCyan),
                              tooltip: 'Mark as read',
                              onPressed: () async {
                                await doc.reference.update({'read': true});
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(String type, bool isRead) {
    switch (type) {
      case 'new_message':
      case 'message':
        return isRead ? Icons.mail_outline : Icons.mark_email_unread_outlined;
      case 'media_uploaded':
        return Icons.cloud_done_outlined;
      case 'project_published':
        return Icons.rocket_launch_outlined;
      default:
        return isRead
            ? Icons.notifications_none_rounded
            : Icons.notifications_active_outlined;
    }
  }
}


/// Opens the notification compose form.
///
/// Shared by the notification centre's app bar and the dashboard quick action,
/// so both entry points offer the same validated form (spec sections 8 and 60).
Future<void> showComposeNotificationDialog(BuildContext context) =>
    _ComposeNotificationDialog.show(context);


/// Composes and sends an announcement to the administrator inbox (spec section
/// 8 and section 60).
///
/// The write goes through the `sendNotification` callable rather than Firestore,
/// because `firestore.rules` refuses every client write to `notifications`: the
/// inbox is a record of what the system announced, so it must not be forgeable
/// from a client, not even by a signed-in administrator.
class _ComposeNotificationDialog extends ConsumerStatefulWidget {
  const _ComposeNotificationDialog();

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const _ComposeNotificationDialog(),
      );

  @override
  ConsumerState<_ComposeNotificationDialog> createState() =>
      _ComposeNotificationDialogState();
}

class _ComposeNotificationDialogState
    extends ConsumerState<_ComposeNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _linkController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Captured before the await: the dialog is popped on success, so the
    // element's context must not be used afterwards.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);

    try {
      await ref.read(backendCallablesProvider).sendAdminNotification(
            title: _titleController.text,
            body: _bodyController.text,
            link: _linkController.text,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Notification sent to administrators.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not send notification: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _required(String? value, int min, String label) {
    final text = value?.trim() ?? '';
    if (text.length < min) return 'Enter at least $min characters for $label.';
    return null;
  }

  String? _validateLink(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!text.startsWith('/')) return 'Use an in-app path, e.g. /projects.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkCard,
      title: const Text(
        'Send notification',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => _required(value, 3, 'the title'),
              ),
              TextFormField(
                controller: _bodyController,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (value) => _required(value, 3, 'the message'),
              ),
              TextFormField(
                controller: _linkController,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Open in-app path (optional)',
                  hintText: '/admin/messages',
                ),
                validator: _validateLink,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}

