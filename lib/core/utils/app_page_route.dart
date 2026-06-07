import 'package:flutter/material.dart';

/// Transitions de page personnalisées pour une expérience premium.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteTransition transition;

  AppPageRoute({
    required this.page,
    this.transition = RouteTransition.slideUp,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(transition, animation, secondaryAnimation, child);
          },
        );

  static Widget _buildTransition(
    RouteTransition type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case RouteTransition.slideUp:
        return _slideUpTransition(animation, secondaryAnimation, child);
      case RouteTransition.fade:
        return FadeTransition(opacity: animation, child: child);
      case RouteTransition.scale:
        return _scaleTransition(animation, child);
    }
  }

  static Widget _slideUpTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.06);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: Curves.easeOutCubic),
    );
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: Curves.easeOut),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }

  static Widget _scaleTransition(
    Animation<double> animation,
    Widget child,
  ) {
    final tween = Tween<double>(begin: 0.92, end: 1.0).chain(
      CurveTween(curve: Curves.easeOutCubic),
    );
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: Curves.easeOut),
    );

    return ScaleTransition(
      scale: animation.drive(tween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}

enum RouteTransition { slideUp, fade, scale }

/// Helper pour naviguer vers une propriété avec la bonne transition Hero + slide
Route<T> buildPropertyDetailRoute<T>(Widget page) {
  return AppPageRoute<T>(
    page: page,
    transition: RouteTransition.slideUp,
  );
}
