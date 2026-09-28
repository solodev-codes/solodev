import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'backend_config.dart';

/// Activates App Check with a provider appropriate to the platform (spec
/// section 41).
///
/// Activation is best-effort on purpose. App Check is defence in depth: an
/// unavailable provider must degrade to "unattested requests", never to an app
/// that will not start. Development builds therefore use the debug providers,
/// and the web build only activates once a site key has been supplied, which
/// keeps `flutter run` working before the reCAPTCHA resource exists.
class AppCheckService {
  const AppCheckService._();

  /// Activates App Check. Returns a human-readable note when activation was
  /// skipped or failed, and `null` when it succeeded.
  static Future<String?> initialise() async {
    try {
      if (kIsWeb) {
        if (!BackendConfig.hasRecaptchaSiteKey) {
          return 'App Check is inactive: build with '
              '--dart-define=RECAPTCHA_SITE_KEY=... to enable it.';
        }
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaEnterpriseProvider(
            BackendConfig.recaptchaSiteKey,
          ),
        );
        return null;
      }

      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
      );
      return null;
    } catch (error) {
      debugPrint('App Check activation failed: $error');
      return 'App Check could not be activated: $error';
    }
  }
}