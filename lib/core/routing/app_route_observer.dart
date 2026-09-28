import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/seo/seo_service.dart';

/// Publishes page metadata (spec section 44) whenever the top route changes.
///
/// `go_router` reports the matched route *pattern* through
/// `RouteSettings.name` (e.g. `/projects/:id`), which is neither the address a
/// visitor sees nor enough to describe a specific document. The observer
/// therefore reads the live location from [locationResolver] and only falls
/// back to the route name when no resolver has been installed.
///
/// The update is deferred by one microtask because a pop notifies the observer
/// before `go_router` has committed the new match list; reading the location
/// synchronously inside `didPop` would re-publish the page being left.
class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver({this.locationResolver});

  /// Supplies the current location, typically the router delegate's URI.
  final String? Function()? locationResolver;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _publish(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _publish(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _publish(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _publish(previousRoute);
  }

  void _publish(Route<dynamic>? fallbackRoute) {
    final fallback = fallbackRoute?.settings.name;
    scheduleMicrotask(() {
      String? location;
      try {
        location = locationResolver?.call();
      } catch (_) {
        // A navigator that outlives its router must not break navigation.
      }
      final resolved = (location == null || location.isEmpty)
          ? fallback
          : location;
      if (resolved == null || resolved.isEmpty) return;
      // Fire-and-forget: metadata must never block a route transition.
      unawaited(SeoService.applyForLocation(resolved));
    });
  }
}
