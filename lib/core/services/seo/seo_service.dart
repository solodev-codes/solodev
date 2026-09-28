import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'web_metadata.dart';

/// The title and description a page advertises to search engines and link
/// previews (spec section 44).
@immutable
class PageMetadata {
  const PageMetadata({required this.title, required this.description});

  /// Value for `<title>`, `og:title` and the platform task switcher.
  final String title;

  /// Value for `<meta name="description">` and `og:description`.
  final String description;

  @override
  bool operator ==(Object other) =>
      other is PageMetadata &&
      other.title == title &&
      other.description == description;

  @override
  int get hashCode => Object.hash(title, description);

  @override
  String toString() => 'PageMetadata($title)';
}

/// Keeps page titles and meta descriptions in step with the current route.
///
/// Flutter Web renders to a canvas, so the values baked into `web/index.html`
/// are what a crawler sees unless something writes to the document while the
/// app runs. The router installs a `NavigatorObserver` that calls
/// [applyForLocation] on every navigation, and detail screens override the
/// generic section title once their document has loaded.
///
/// The mapping itself is a pure function, so a location always resolves to the
/// same metadata whatever the platform, router state or network condition.
class SeoService {
  const SeoService._();

  /// Brand appended to page titles, e.g. `Flutter App Development | Solodev`.
  static const String siteName = 'Solodev';

  /// Title used for the landing page and for any unmatched location.
  static const String defaultTitle =
      'Solodev | Flutter Developer & AI Designer';

  /// Description used for the landing page and for any unmatched location.
  static const String defaultDescription =
      'Solodev builds modern mobile, web and AI-powered digital experiences '
      'with cross-platform Flutter excellence. Explore projects, services, '
      'certificates and case studies.';

  static const String _adminDescription =
      'Private administrator area for the Solodev portfolio. Sign-in is '
      'required and access is limited to administrators.';


  /// Resolves the metadata for a route location such as `/services/flutter-app`.
  ///
  /// Matching is by first path segment, so parameterised detail routes inherit
  /// the metadata of the section they belong to; screens then narrow it with
  /// [applyDetailPage] once the document title is known. Query strings,
  /// fragments and fully-qualified URLs are all accepted.
  static PageMetadata metadataForLocation(String location) {
    final segments = _segmentsOf(location);
    if (segments.isEmpty) return _fallback;

    if (segments.first == 'admin') {
      return const PageMetadata(
        title: 'Admin | $siteName',
        description: _adminDescription,
      );
    }

    switch (segments.first) {
      case 'about':
        return const PageMetadata(
          title: 'About | $siteName',
          description:
              'Background, technology stack and working style of Solodev, a '
              'Flutter developer and AI designer.',
        );
      case 'services':
        return const PageMetadata(
          title: 'Flutter App Development | $siteName',
          description:
              'End-to-end Flutter and Firebase services: cross-platform app '
              'builds, AI features, UI/UX design, migration and performance '
              'work.',
        );
      case 'projects':
        return const PageMetadata(
          title: 'Projects & Case Studies | $siteName',
          description:
              'Selected Flutter, Firebase and AI case studies with the brief, '
              'the architecture and the measurable result.',
        );
      case 'experience':
        return const PageMetadata(
          title: 'Experience | $siteName',
          description:
              'Professional history, roles, responsibilities and the platforms '
              'behind the Solodev portfolio.',
        );
      case 'achievements':
        return const PageMetadata(
          title: 'Achievements | $siteName',
          description:
              'Awards, recognition and delivery milestones across mobile, web '
              'and AI projects.',
        );
      case 'certificates':
        return const PageMetadata(
          title: 'Certificates & Credentials | $siteName',
          description:
              'Verified certifications with issuing organisations and '
              'credential links.',
        );
      case 'contact':
        return const PageMetadata(
          title: 'Contact | $siteName',
          description:
              'Start a project with Solodev: send a brief, a timeline and a '
              'budget, and get a considered reply.',
        );
      default:
        return _fallback;
    }
  }

  /// Publishes the metadata for [location].
  static Future<void> applyForLocation(String location) =>
      apply(metadataForLocation(location));

  /// Publishes document-specific metadata, e.g. `Payments App | Solodev`.
  static Future<void> applyDetailPage({
    required String title,
    String? description,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return apply(
      PageMetadata(
        title: '$trimmed | $siteName',
        description: (description == null || description.trim().isEmpty)
            ? defaultDescription
            : description.trim(),
      ),
    );
  }

  /// Writes [metadata] to the browser document and the platform task switcher.
  ///
  /// Platform failures are swallowed: a title is decoration, and an unwritable
  /// channel must never interrupt navigation (spec section 61).
  static Future<void> apply(PageMetadata metadata) async {
    applyWebMetadata(title: metadata.title, description: metadata.description);

    try {
      await SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(label: metadata.title),
      );
    } catch (_) {
      // Some targets expose no task switcher, and a missing platform channel
      // must never interrupt navigation.
    }
  }

  static const PageMetadata _fallback = PageMetadata(
    title: defaultTitle,
    description: defaultDescription,
  );

  /// Splits a location into its meaningful path segments.
  static List<String> _segmentsOf(String location) {
    final uri = Uri.tryParse(location) ?? Uri(path: location);
    return uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  }
}
