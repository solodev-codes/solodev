import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Privacy-conscious portfolio analytics (spec sections 30 and 45).
///
/// Only page/content identifiers and non-identifying context are logged — never
/// names, emails, message bodies or favourites. Every call is best-effort: an
/// analytics failure must never break navigation or a contact submission.
class AnalyticsService {
  const AnalyticsService._();

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  static Future<void> _log(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics event "$name" failed: $error');
    }
  }

  static Future<void> logProjectView({
    required String projectId,
    String? title,
  }) => _log('portfolio_project_view', {
    'project_id': projectId,
    if (title != null && title.isNotEmpty) 'title': title,
  });

  static Future<void> logServiceView({
    required String serviceId,
    String? title,
  }) => _log('portfolio_service_view', {
    'service_id': serviceId,
    if (title != null && title.isNotEmpty) 'title': title,
  });

  static Future<void> logCertificateView({
    required String certificateId,
    String? title,
  }) => _log('portfolio_certificate_view', {
    'certificate_id': certificateId,
    if (title != null && title.isNotEmpty) 'title': title,
  });

  static Future<void> logContactSubmit() =>
      _log('portfolio_contact_submit', null);

  static Future<void> logProjectShare({required String projectId}) =>
      _log('portfolio_project_share', {'project_id': projectId});
}
