import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records a project view at most once per visitor per throttle window
/// (spec section 27).
///
/// The write only bumps `viewsCount` by exactly one; `firestore.rules` allows
/// anonymous clients to perform that single-field update on published
/// projects and nothing else. All failures are swallowed because the counter
/// is best-effort — an offline device or a stricter ruleset must never break
/// the detail screen.
class ProjectViewsService {
  ProjectViewsService._();

  /// Cross-session throttle: one counted view per project per 30 minutes.
  static const Duration window = Duration(minutes: 30);

  /// In-session guard so a failing write is not retried on every rebuild.
  static final Set<String> _attempted = <String>{};

  static String _prefsKey(String projectId) => 'last_project_view_$projectId';

  static Future<void> recordView(String projectId) async {
    if (projectId.isEmpty || _attempted.contains(projectId)) return;
    _attempted.add(projectId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_prefsKey(projectId));
      final now = DateTime.now().millisecondsSinceEpoch;
      if (last != null && now - last < window.inMilliseconds) return;
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update(<String, dynamic>{
        'viewsCount': FieldValue.increment(1),
      });
      await prefs.setInt(_prefsKey(projectId), now);
    } catch (_) {
      // Undo the session guard so a transient failure can retry next rebuild.
      _attempted.remove(projectId);
    }
  }
}

