import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the visitor's favourite project ids locally on the device/browser.
/// Uses [SharedPreferences] so no authentication is required.
class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  static const String storageKey = 'solodev_favorite_projects';

  @override
  Future<Set<String>> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(storageKey) ?? const <String>[];
      return stored.toSet();
    } catch (_) {
      // Storage unavailable (private mode, blocked cookies) — degrade gracefully.
      return <String>{};
    }
  }

  Set<String> get _current => state.valueOrNull ?? <String>{};

  bool isFavorite(String projectId) => _current.contains(projectId);

  /// Adds or removes [projectId] and persists the new collection.
  Future<bool> toggle(String projectId) async {
    final updated = Set<String>.from(_current);
    final nowFavorite = !updated.remove(projectId);
    if (nowFavorite) {
      updated.add(projectId);
    }
    state = AsyncData(updated);
    await _persist(updated);
    return nowFavorite;
  }

  /// Removes a project from favourites.
  Future<void> remove(String projectId) async {
    final updated = Set<String>.from(_current)..remove(projectId);
    state = AsyncData(updated);
    await _persist(updated);
  }

  /// Clears every stored favourite.
  Future<void> clear() async {
    state = const AsyncData(<String>{});
    await _persist(<String>{});
  }

  Future<void> _persist(Set<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(storageKey, values.toList());
    } catch (_) {
      // Ignore persistence failures; in-memory state stays consistent.
    }
  }
}

/// Exposes the visitor's favourite project ids.
final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

/// Convenience derived provider: the favourited count for badge widgets.
final favoritesCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider).valueOrNull?.length ?? 0;
});
