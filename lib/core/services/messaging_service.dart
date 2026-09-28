import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'backend_callables.dart';
import 'backend_config.dart';

/// Admin push registration and foreground display (spec section 26).
///
/// Registration goes through the `registerDevice` callable because clients are
/// refused direct writes to `devices` by `firestore.rules`. Registration only
/// happens for an authenticated administrator; visitors never register. The
/// service never shows a dialog on its own — screens call [ensureRegistered]
/// after login, and [showForegroundMessages] once from the admin shell.
class MessagingService {
  const MessagingService._();

  /// True after constructor validation passed and [ensureRegistered] has run
  /// at least once this session; prevents duplicate callable calls.
  static bool _registeredThisSession = false;

  /// Permission status or callable outcome for the admin profile menu.
  static String? lastStatus;

  /// Requests notification permission, resolves the FCM token (including the
  /// mandatory VAPID key on web), and registers it with the backend.
  ///
  /// Returns `true` when the token was accepted server-side. Any failure is
  /// captured in [lastStatus] and reported as `false` rather than thrown, so
  /// login cannot fail because push registration did.
  static Future<bool> ensureRegistered({
    BackendCallables? callables,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  }) async {
    final currentUser =
        (auth ?? FirebaseAuth.instance).currentUser;
    if (currentUser == null) {
      lastStatus = 'Sign in as an administrator to enable notifications.';
      debugPrint('Messaging registration skipped: no signed-in user.');
      return false;
    }

    if (_registeredThisSession) return true;

    final messenger = messaging ?? FirebaseMessaging.instance;
    try {
      final settings = await messenger.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        lastStatus = 'Notifications are blocked for this device.';
        debugPrint('Messaging registration skipped: permission denied.');
        return false;
      }

      final token = await messenger.getToken(
        vapidKey: BackendConfig.hasWebPushVapidKey
            ? BackendConfig.webPushVapidKey
            : null,
      );
      if (token == null || token.isEmpty) {
        lastStatus = 'Could not obtain a device token on this browser.';
        debugPrint('Messaging registration skipped: empty FCM token.');
        return false;
      }

      await (callables ?? BackendCallables()).registerDevice(
        token: token,
        platform: _platformLabel(),
      );
      _registeredThisSession = true;
      lastStatus = 'Push notifications enabled for this device.';
      return true;
    } catch (error) {
      lastStatus = 'Could not enable notifications: $error';
      debugPrint('Messaging registration failed: $error');
      return false;
    }
  }

  /// Shows incoming messages as snack bars while the admin area is open.
  ///
  /// Idempotent: safe to call from every admin shell build. Background and
  /// terminated-state taps are out of scope for this release; the dashboard
  /// inbox remains the source of truth for missed pushes.
  static bool _foregroundListenerAttached = false;

  static void showForegroundMessages(BuildContext context) {
    if (_foregroundListenerAttached) return;
    _foregroundListenerAttached = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final title = notification?.title ?? 'New notification';
      final body = notification?.body ?? '';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
        );
    });
  }

  /// Listens for refreshed tokens and re-registers them while signed in.
  ///
  /// Attach once per app lifetime (alongside [showForegroundMessages]) so a
  /// rotated token cannot silently stop delivery.
  static void watchTokenRefresh({
    BackendCallables? callables,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  }) {
    (messaging ?? FirebaseMessaging.instance).onTokenRefresh.listen((
      String token,
    ) async {
      _registeredThisSession = false;
      await ensureRegistered(
        callables: callables,
        messaging: messaging,
        auth: auth,
      );
    });
  }

  /// Servers record one platform label per token so dead-token pruning in the
  /// backend can distinguish browsers from devices.
  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Streams the signed-in administrator's stored notifications for the
  /// notification centre (spec section 8). Broadcasts (`recipientId == null`)
  /// are included; other administrators' direct messages are excluded by the
  /// query itself rather than filtered client-side.
  ///
  /// Firestore `whereIn` rejects `null`, so broadcasts and direct messages
  /// are queried separately and merged locally. The merge is still
  /// server-filtered — no administrator ever receives another account's
  /// direct notifications.
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  notificationHistory(String uid) {
    final collection = FirebaseFirestore.instance.collection('notifications');
    final broadcasts = collection
        .where('recipientId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots();
    final direct = collection
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots();

    return _combineLatest2(
      broadcasts,
      direct,
      (
        QuerySnapshot<Map<String, dynamic>> a,
        QuerySnapshot<Map<String, dynamic>> b,
      ) {
        final merged =
            <QueryDocumentSnapshot<Map<String, dynamic>>>[...a.docs, ...b.docs];
        merged.sort((x, y) {
          final xAt = (x.data()['createdAt'] as Timestamp?);
          final yAt = (y.data()['createdAt'] as Timestamp?);
          final xMs = xAt?.millisecondsSinceEpoch ?? 0;
          final yMs = yAt?.millisecondsSinceEpoch ?? 0;
          return yMs.compareTo(xMs);
        });
        return merged.take(50).toList();
      },
    );
  }

  /// Minimal two-stream combiner without adding an rx dependency.
  static Stream<R> _combineLatest2<A, B, R>(
    Stream<A> first,
    Stream<B> second,
    R Function(A a, B b) combine,
  ) {
    late A latestA;
    late B latestB;
    var hasA = false;
    var hasB = false;
    late StreamController<R> controller;
    StreamSubscription<A>? subA;
    StreamSubscription<B>? subB;

    void emitIfReady() {
      if (hasA && hasB) {
        try {
          controller.add(combine(latestA, latestB));
        } catch (error, stack) {
          controller.addError(error, stack);
        }
      }
    }

    controller = StreamController<R>.broadcast(
      onListen: () {
        subA = first.listen(
          (value) {
            latestA = value;
            hasA = true;
            emitIfReady();
          },
          onError: controller.addError,
        );
        subB = second.listen(
          (value) {
            latestB = value;
            hasB = true;
            emitIfReady();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }
}
