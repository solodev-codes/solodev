import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Reports whether the device currently has a usable network transport, so the
/// UI can degrade instead of failing (spec section 61).
///
/// Connectivity is a hint, not a guarantee: a device can be attached to a
/// network that cannot reach Firebase, and Firestore's own cache keeps serving
/// previously loaded documents either way. Screens therefore still own their
/// error and empty states; this service only decides whether to say
/// "You appear to be offline."
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits the current status immediately, then again on every change.
  ///
  /// A platform that cannot report connectivity (an unsupported target, or a
  /// missing platform implementation) ends the stream quietly rather than
  /// throwing, so an unavailable radio never turns into a visible crash.
  Stream<bool> get onlineChanges async* {
    yield await checkConnected();
    try {
      yield* _connectivity.onConnectivityChanged.map(isOnline).distinct();
    } catch (error) {
      debugPrint('Connectivity monitoring unavailable: $error');
    }
  }

  /// One-shot check, defaulting to `true` when the platform cannot answer.
  ///
  /// Optimistic on failure on purpose: a false "offline" banner on a working
  /// connection is worse than a missing banner on a broken one.
  Future<bool> checkConnected() async {
    try {
      return isOnline(await _connectivity.checkConnectivity());
    } catch (error) {
      debugPrint('Connectivity check unavailable: $error');
      return true;
    }
  }

  /// Folds the platform's transport list into a single connectivity flag.
  ///
  /// `connectivity_plus` reports every active transport, so an empty list and a
  /// single `none` entry both mean offline while `[wifi, vpn]` means online.
  static bool isOnline(List<ConnectivityResult> results) => results
      .any((result) => result != ConnectivityResult.none);
}
