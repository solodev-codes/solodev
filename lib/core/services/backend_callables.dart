import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'backend_config.dart';

/// Server-derived portfolio summary written to `analytics/portfolio_stats` by
/// the refresh function. Numbers come from the database itself, so they agree
/// with what the security rules would let an administrator see.
class PortfolioStats {
  const PortfolioStats({
    required this.totalProjects,
    required this.publishedProjects,
    required this.publishedSkills,
    required this.totalMessages,
    required this.newMessages,
    required this.openMessages,
  });

  factory PortfolioStats.fromMap(Map<String, dynamic> map) {
    int asInt(Object? value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    return PortfolioStats(
      totalProjects: asInt(map['totalProjects']),
      publishedProjects: asInt(map['publishedProjects']),
      publishedSkills: asInt(map['publishedSkills']),
      totalMessages: asInt(map['totalMessages']),
      newMessages: asInt(map['newMessages']),
      openMessages: asInt(map['openMessages']),
    );
  }

  factory PortfolioStats.empty() => const PortfolioStats(
        totalProjects: 0,
        publishedProjects: 0,
        publishedSkills: 0,
        totalMessages: 0,
        newMessages: 0,
        openMessages: 0,
      );

  final int totalProjects;
  final int publishedProjects;
  final int publishedSkills;
  final int totalMessages;
  final int newMessages;
  final int openMessages;
}

/// Typed access to the deployed callable functions.
///
/// The region must match the functions codebase or every call fails with
/// `not-found`. Failures surface as [FirebaseFunctionsException], which callers
/// translate into UI-safe copy; this layer never fabricates a response.
class BackendCallables {
  BackendCallables({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: BackendConfig.functionsRegion);

  final FirebaseFunctions _functions;

  /// Registers this device for admin push via the `registerDevice` callable.
  ///
  /// Must only be called while an administrator is signed in; the callable
  /// takes the UID from the auth context, never from the request body.
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    final callable = _functions.httpsCallable('registerDevice');
    await callable.call(<String, dynamic>{
      'token': token,
      'platform': platform,
    });
  }

  /// Recomputes the portfolio summary document and returns the fresh figures.
  ///
  /// Restricted to administrators server-side. Used after a bulk edit so the
  /// dashboard does not wait for the scheduled `dailyStatsRollup`.
  Future<PortfolioStats> refreshPortfolioStats() async {
    final callable = _functions.httpsCallable('refreshPortfolioStats');
    final result = await callable.call(<String, dynamic>{});
    final data = result.data;
    if (data is Map) {
      return PortfolioStats.fromMap(Map<String, dynamic>.from(data));
    }
    debugPrint('refreshPortfolioStats returned an unexpected payload: $data');
    return PortfolioStats.empty();
  }

  /// Broadcasts an administrator-composed notification to the admin inbox.
  ///
  /// `firestore.rules` refuses every client write to `notifications`, so the
  /// document and the push payload are both produced by the `sendNotification`
  /// callable. Returns the ID of the notification that was created.
  Future<String> sendAdminNotification({
    required String title,
    required String body,
    String? link,
    String? recipientId,
  }) async {
    final callable = _functions.httpsCallable('sendNotification');
    final result = await callable.call(<String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      if (link != null && link.trim().isNotEmpty) 'link': link.trim(),
      if (recipientId != null && recipientId.isNotEmpty)
        'recipientId': recipientId,
    });

    final data = result.data;
    if (data is Map && data['notificationId'] is String) {
      return data['notificationId'] as String;
    }
    debugPrint('sendNotification returned an unexpected payload: $data');
    return '';
  }

  /// Grants or revokes administrator privileges for an account.
  ///
  /// The caller must already be an administrator. Pass either the account's
  /// [uid] or [email]. Self-revocation is refused server-side.
  Future<void> setAdminClaim({
    String? uid,
    String? email,
    required bool grant,
  }) async {
    assert(
      (uid != null && uid.isNotEmpty) || (email != null && email.isNotEmpty),
      'setAdminClaim needs either a uid or an email',
    );
    final callable = _functions.httpsCallable('setAdminClaim');
    await callable.call(<String, dynamic>{
      if (uid != null && uid.isNotEmpty) 'uid': uid,
      if (email != null && email.isNotEmpty) 'email': email.trim(),
      'grant': grant,
    });
  }

  /// Sends an e-mail to a client through the `sendClientEmail` callable
  /// (spec section 59).
  ///
  /// * [type] `'ack'` — acknowledgement for enquiry [messageId];
  /// * [type] `'reply'` — administrator reply, requires [subject] and [body];
  /// * [type] `'test'` — self-test, requires [to].
  ///
  /// The recipient for `ack`/`reply` is always derived server-side from the
  /// message document, so the browser can never redirect client mail.
  /// Returns the `email_logs` document id of the delivery.
  Future<String> sendClientEmail({
    required String type,
    String? messageId,
    String? to,
    String? subject,
    String? body,
  }) async {
    final callable = _functions.httpsCallable('sendClientEmail');
    final result = await callable.call(<String, dynamic>{
      'type': type,
      if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
      if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
    });
    final data = result.data;
    if (data is Map && data['emailId'] is String) {
      return data['emailId'] as String;
    }
    debugPrint('sendClientEmail returned an unexpected payload: $data');
    return '';
  }
}