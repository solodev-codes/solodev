import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';
import 'admin_widgets.dart';

/// Every enquiry lifecycle state, mirroring `MESSAGE_STATUSES` in
/// `functions/src/config/constants.ts`.
const List<String> kMessageStatuses = <String>[
  'new',
  'read',
  'in_progress',
  'replied',
  'closed',
];

const Map<String, String> _statusLabels = <String, String>{
  'new': 'New',
  'read': 'Read',
  'in_progress': 'In Progress',
  'replied': 'Replied',
  'closed': 'Closed',
};

const Map<String, Color> _statusColors = <String, Color>{
  'new': AppColors.accentCyan,
  'read': Color(0xFF3B82F6),
  'in_progress': Color(0xFFF59E0B),
  'replied': Color(0xFF22C55E),
  'closed': AppColors.textSecondaryDark,
};

/// Lightweight CRM inbox for contact enquiries (spec section 59).
///
/// Search and filtering run client-side over the already-subscribed snapshot
/// rather than issuing a query per keystroke, which keeps Firestore read costs
/// flat regardless of how the administrator filters.
class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() =>
      _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  final _search = TextEditingController();

  String _query = '';
  String? _statusFilter;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              isError ? AppColors.error : AppColors.darkCardBorder,
        ),
      );
  }

  Future<void> _setStatus(ContactMessageModel message, String status) async {
    if (status == message.status) return;
    setState(() => _busy = true);
    try {
      await ref.read(portfolioRepositoryProvider).updateMessageStatus(
            message.id,
            status,
            updatedBy: FirebaseAuth.instance.currentUser?.uid,
          );
      _snack('Marked as ${_statusLabels[status]}');
    } catch (e) {
      _snack('Could not update the status: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ContactMessageModel message) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete this enquiry?',
      message:
          'The message from ${message.name} will be permanently removed from '
          'the inbox. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(portfolioRepositoryProvider).deleteMessage(message.id);
      _snack('Enquiry deleted');
    } catch (e) {
      _snack('Could not delete: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Translates callable failures into copy the administrator can act on
  /// (spec section 59).
  String _emailErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        return 'Daily e-mail limit reached — try again after midnight UTC.';
      case 'failed-precondition':
        return 'E-mail is not configured yet — set the Gmail secrets and '
            'redeploy the functions.';
      case 'not-found':
        return 'That enquiry no longer exists.';
      case 'unauthenticated':
      case 'permission-denied':
        return 'You are not authorised to send client e-mail.';
      default:
        return 'Could not send the e-mail: ${e.message ?? e.code}';
    }
  }

  /// Sends the automatic acknowledgement for [message] (spec section 59).
  Future<void> _sendAcknowledgement(ContactMessageModel message) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(backendCallablesProvider)
          .sendClientEmail(type: 'ack', messageId: message.id);
      _snack('Acknowledgement sent to ${message.email}');
    } on FirebaseFunctionsException catch (e) {
      _snack(_emailErrorMessage(e), isError: true);
    } catch (e) {
      _snack('Could not send the e-mail: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Compose-and-send dialog for an administrator reply.
  ///
  /// The recipient is always the stored enquiry address — the dialog only
  /// collects subject and body, so the browser cannot redirect client mail.
  Future<void> _openReplyDialog(ContactMessageModel message) async {
    final subjectController = TextEditingController(
      text: message.subject.trim().isEmpty
          ? 'Re: your enquiry'
          : 'Re: ${message.subject.trim()}',
    );
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool? sent;
    String subject = '';
    String body = '';
    try {
      sent = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Reply to ${message.name}'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To: ${message.email}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppConstants.space16),
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Subject is required (3+ characters)'
                        : null,
                  ),
                  const SizedBox(height: AppConstants.space16),
                  TextFormField(
                    controller: bodyController,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'Message'),
                    validator: (v) => (v == null || v.trim().length < 5)
                        ? 'Message is required (5+ characters)'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send'),
            ),
          ],
        ),
      );
      // Capture the text before the controllers are disposed below.
      subject = subjectController.text;
      body = bodyController.text;
    } finally {
      subjectController.dispose();
      bodyController.dispose();
    }

    if (sent != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(backendCallablesProvider).sendClientEmail(
            type: 'reply',
            messageId: message.id,
            subject: subject,
            body: body,
          );
      _snack('Reply sent to ${message.email}');
      await _setStatus(message, 'replied');
    } on FirebaseFunctionsException catch (e) {
      _snack(_emailErrorMessage(e), isError: true);
    } catch (e) {
      _snack('Could not send the e-mail: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _matches(ContactMessageModel m) {
    if (_statusFilter != null && m.status != _statusFilter) return false;
    if (_query.isEmpty) return true;
    final haystack =
        '${m.name} ${m.email} ${m.subject} ${m.message}'.toLowerCase();
    return haystack.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(contactMessagesProvider);

    return AdminShell(
      title: 'Messages',
      child: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(contactMessagesProvider),
        ),
        data: (all) {
          final visible = all.where(_matches).toList();

          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.space32),
                child: EmptyState(
                  icon: Icons.mail_outline_rounded,
                  title: 'No messages yet',
                  message: 'Enquiries sent from the contact form will appear '
                      'here as soon as a visitor submits one.',
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(all),
                const SizedBox(height: AppConstants.space16),
                _filters(all),
                const SizedBox(height: AppConstants.space16),
                if (visible.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching messages',
                    message: 'Try a different search term or clear the filter.',
                  )
                else
                  ...visible.map(_tile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(List<ContactMessageModel> all) {
    final unread = all.where((m) => m.status == 'new').length;
    return Row(
      children: [
        Expanded(
          child: Text(
            unread > 0
                ? '$unread unread of ${all.length}'
                : '${all.length} enquiries',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search name, email, subject...',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filters(List<ContactMessageModel> all) {
    int countFor(String? status) =>
        status == null
            ? all.length
            : all.where((m) => m.status == status).length;

    Widget chip(String? status, String label) {
      final selected = _statusFilter == status;
      return FilterChip(
        label: Text('$label (${countFor(status)})'),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = status),
        selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
      );
    }

    return Wrap(
      spacing: AppConstants.space8,
      runSpacing: AppConstants.space8,
      children: [
        chip(null, 'All'),
        for (final status in kMessageStatuses)
          chip(status, _statusLabels[status] ?? status),
      ],
    );
  }

  Widget _tile(ContactMessageModel message) {
    final timestamp = DateFormat.yMMMd().add_jm().format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space12),
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(status: message.status),
              const SizedBox(width: AppConstants.space8),
              PopupMenuButton<String>(
                tooltip: 'Change status or delete',
                enabled: !_busy,
                onSelected: (value) {
                  if (value == 'delete') {
                    _delete(message);
                  } else if (value == 'ack') {
                    _sendAcknowledgement(message);
                  } else if (value == 'email') {
                    _openReplyDialog(message);
                  } else {
                    _setStatus(message, value);
                  }
                },
                itemBuilder: (_) => [
                  for (final status in kMessageStatuses)
                    CheckedPopupMenuItem(
                      value: status,
                      checked: message.status == status,
                      child: Text(_statusLabels[status] ?? status),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'email',
                    child: Text('Email client…'),
                  ),
                  const PopupMenuItem(
                    value: 'ack',
                    child: Text('Send acknowledgement'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space4),
          Text(
            '${message.email}  ·  $timestamp',
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          if (message.subject.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            Text(
              message.subject,
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.space8),
          Text(
              message.message,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text plus colour, so status is never communicated by colour alone
/// (spec section 45).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabels[status] ?? status;
    final color = _statusColors[status] ?? AppColors.textSecondaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}