import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Loading animation using flutter_spinkit.
class CustomLoadingIndicator extends StatelessWidget {
  final double size;
  const CustomLoadingIndicator({Key? key, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(
      color: Theme.of(context).highlightColor,
      size: size,
    );
  }
}
