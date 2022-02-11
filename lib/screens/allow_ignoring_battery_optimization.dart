import 'package:flutter/material.dart';
import 'package:spartial/services/foreground_task.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen that shows then the user has not disabled battery optimization for Spartial.
/// Informs the user that the cannot continue without disableing batter optimization
/// because Spartial basically cannot run properly without it.
class AllowIgnoringBatteryOptimizationPage extends StatefulWidget {
  const AllowIgnoringBatteryOptimizationPage({Key? key}) : super(key: key);

  @override
  _AllowIgnoringBatteryOptimizationPageState createState() =>
      _AllowIgnoringBatteryOptimizationPageState();
}

class _AllowIgnoringBatteryOptimizationPageState
    extends State<AllowIgnoringBatteryOptimizationPage> {
  /// Whether battery optimization is disabled for Spartial.
  bool isIgnoring = false;

  /// Shows a popup that asks the user to disable battery optimization.
  /// Navigator.pop if they accept.
  Future<void> requestIgnoreBatteryOptimization() async {
    isIgnoring = await ForegroundTask.isIgnoringBatteryOptimizations();
    if (!isIgnoring) {
      isIgnoring = await ForegroundTask.requestIgnoreBatteryOptimization();
    }
    if (isIgnoring) {
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();
    // Immediately ask the user to ignore battery optimization.
    requestIgnoreBatteryOptimization();
  }

  @override
  Widget build(BuildContext context) {
    // Only allow to press the back button when battery optimization is ignored.
    return WillPopScope(
      onWillPop: () async {
        if (isIgnoring) {
          return true;
        } else {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          return false;
        }
      },
      child: SafeArea(
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(60.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Permission required",
                    style: Theme.of(context).textTheme.headline2,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 60.h,
                  ),
                  Text(
                    "Unfortunately Spartial cannot run when battery optimization for Spartial is enabled. Please dissable battery optimization for Spartial",
                    style: Theme.of(context).textTheme.subtitle1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 60.h,
                  ),
                  // Button to show the disable request popup again.
                  SolidRoundedButton(
                      onPressed: () {
                        requestIgnoreBatteryOptimization();
                      },
                      text: "Disable"),
                  SizedBox(
                    height: 30.h,
                  ),
                  Text(
                    "Or",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  // Button to open the phone settings an navigate to the battery optimization settings.
                  TextButton(
                      onPressed: () async {
                        isIgnoring = await ForegroundTask
                            .openIgnoreBatteryOptimizationSettings();
                        if (isIgnoring) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: Text(
                        "Open settings to manually disable battery optimization for Spartial",
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.center,
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
