import 'package:flutter/material.dart';

class NavigationHelper {
  static void navigateWithSlideTransition(
    BuildContext context,
    Widget destination,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1, 0); // Start from the right
          const end = Offset.zero; // End at the center
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  static void navigateAndReplaceWithSlideTransition(
    BuildContext context,
    Widget destination,
  ) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1, 0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  static void navigateAndRemoveUntilWithSlideTransition(
    BuildContext context,
    Widget destination,
    String untilRouteName,
  ) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      untilRouteName,
      (route) => false,
      arguments: destination,
    );
  }
}
