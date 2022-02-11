import 'package:flutter/material.dart';
import 'package:spartial/widgets/loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen that shows a loading animation.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Center(
        child: CustomLoadingIndicator(
          size: 90.sp,
        ),
      )),
    );
  }
}
