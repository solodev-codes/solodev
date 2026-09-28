/// Build-time settings that tie the client to the deployed backend.
///
/// Nothing secret lives here (spec section 42). Values that identify a specific
/// deployment arrive through `--dart-define`, so no key is committed and a
/// staging build can point at a different project without editing source.
class BackendConfig {
  const BackendConfig._();

  /// Region the Cloud Functions codebase is deployed to. Must match `REGION`
  /// in `functions/src/config/constants.ts`, or every callable fails with
  /// `functions/not-found` rather than a permission error.
  static const String functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  /// reCAPTCHA Enterprise site key used for App Check on the web build.
  /// Supplied with `--dart-define=RECAPTCHA_SITE_KEY=...`.
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
  );

  /// Web Push certificate key pair, required to mint an FCM token in the
  /// browser. Supplied with `--dart-define=WEB_PUSH_VAPID_KEY=...`.
  static const String webPushVapidKey = String.fromEnvironment(
    'WEB_PUSH_VAPID_KEY',
  );

  static bool get hasRecaptchaSiteKey => recaptchaSiteKey.isNotEmpty;

  static bool get hasWebPushVapidKey => webPushVapidKey.isNotEmpty;
}