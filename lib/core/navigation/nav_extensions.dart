import 'package:flutter/material.dart';

extension AppNavigation on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) {
    return Navigator.of(
      this,
    ).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  Future<T?> replaceWith<T>(Widget screen) {
    return Navigator.of(
      this,
    ).pushReplacement<T, void>(MaterialPageRoute(builder: (_) => screen));
  }
}
