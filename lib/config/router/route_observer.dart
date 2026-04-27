import 'package:flutter/material.dart';

class APPRouterObserver extends RouteObserver<PageRoute<dynamic>> {
  String currentRouteName = '';

  void _updateCurrentRouteName(Route<dynamic>? route) {
    if (route is PageRoute) {
      currentRouteName = route.settings.name ?? '';
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateCurrentRouteName(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateCurrentRouteName(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateCurrentRouteName(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateCurrentRouteName(newRoute);
  }
}
