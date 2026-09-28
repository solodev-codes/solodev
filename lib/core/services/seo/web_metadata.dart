/// Selects the real DOM implementation on the web and the no-op elsewhere.
///
/// Conditional imports let the SEO layer live in the shared codebase without
/// dragging `package:web` onto Android, iOS or the Dart VM, and without any
/// `kIsWeb` branch that the tree shaker would keep alive on native builds.
library;

export 'web_metadata_stub.dart'
    if (dart.library.js_interop) 'web_metadata_web.dart'
    show applyWebMetadata;
