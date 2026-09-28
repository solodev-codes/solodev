/// Non-web fallback for [applyWebMetadata].
///
/// Native platforms expose no DOM, so this build of the seam does nothing.
/// Keeping the signature identical to the web build lets
/// `web_metadata.dart` choose between them with a conditional import.
library;

void applyWebMetadata({
  required String title,
  String? description,
  String? url,
}) {
  // Intentionally empty: there is no document to annotate off the web.
}
