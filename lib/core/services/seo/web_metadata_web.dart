/// Web build of the metadata seam (spec section 44).
///
/// Flutter paints into a canvas, so the search-engine and social-preview tags
/// declared in `web/index.html` never change on their own. This module writes
/// the same values the Flutter UI is showing straight into the document, which
/// is what crawlers, link unfurlers and the browser tab actually read.
library;

import 'package:web/web.dart' as web;

/// Applies [title] and, when supplied, the description/URL metadata tags.
///
/// Missing tags are created rather than assumed present, so a trimmed
/// `index.html` cannot silently drop the Open Graph block.
void applyWebMetadata({
  required String title,
  String? description,
  String? url,
}) {
  final head = web.document.head;
  if (head == null) return;

  web.document.title = title;

  _writeMeta(head, 'name', 'description', description);
  _writeMeta(head, 'property', 'og:title', title);
  _writeMeta(head, 'property', 'og:description', description);
  _writeMeta(head, 'property', 'og:url', url ?? web.window.location.href);
  _writeMeta(head, 'name', 'twitter:title', title);
  _writeMeta(head, 'name', 'twitter:description', description);

  _writeCanonical(head, url ?? web.window.location.href);
}

/// Creates or updates a `<meta>` tag, leaving absent values untouched.
void _writeMeta(
  web.HTMLHeadElement head,
  String attribute,
  String key,
  String? content,
) {
  if (content == null || content.isEmpty) return;

  final selector = 'meta[$attribute="$key"]';
  final existing = head.querySelector(selector);
  if (existing != null) {
    existing.setAttribute('content', content);
    return;
  }

  final created = web.document.createElement('meta');
  created.setAttribute(attribute, key);
  created.setAttribute('content', content);
  head.append(created);
}

/// Points the canonical link at [url] so the crawler indexes one address.
void _writeCanonical(web.HTMLHeadElement head, String url) {
  final existing = head.querySelector('link[rel="canonical"]');
  if (existing != null) {
    existing.setAttribute('href', url);
    return;
  }

  final created = web.document.createElement('link');
  created.setAttribute('rel', 'canonical');
  created.setAttribute('href', url);
  head.append(created);
}
