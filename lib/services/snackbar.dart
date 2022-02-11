import 'package:flutter/material.dart';

/// Service for showing snackbars.
class CustomSnackBar {
  /// Shows a custom snackbar with message and color.
  static void show(BuildContext context, String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          message,
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
      backgroundColor:
          (color ?? Theme.of(context).colorScheme.secondary).withOpacity(0.5),
    ));
  }
}
