import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;
import 'package:spartial/services/foreground_task.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/wrappers/navigation_wrapper.dart';

/// Page that shows how the Spartial foreground notification can be hidden.
class MinimizeNotificationPage extends StatefulWidget {
  /// The page to navigate to when pressing the back button.
  final Widget? backPage;
  const MinimizeNotificationPage({Key? key, this.backPage}) : super(key: key);

  @override
  _MinimizeNotificationPageState createState() =>
      _MinimizeNotificationPageState();
}

class _MinimizeNotificationPageState extends State<MinimizeNotificationPage> {
  /// The time of the last foreground task restart.
  DateTime lastRestartTime = DateTime.fromMicrosecondsSinceEpoch(0);

  /// Minimum amount of seconds between every foreground task restart.
  int minSecsBetweenRestarts = 10;

  @override
  Widget build(BuildContext context) {
    // Navigate to widget.backPage when pressing the back button.
    return WillPopScope(
      onWillPop: () async {
        if (widget.backPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => widget.backPage!),
          );
          return false;
        }
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Hide Notification",
              style: Theme.of(context).textTheme.headline2,
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 90.sp),
                child: Center(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: Platform.isAndroid
                      // Android instructions
                      ? [
                          Text(
                            "How to hide Spartial notification",
                            style: Theme.of(context).textTheme.headline2,
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          Text(
                            "The steps to hide the Spartial notification might be a little different for every Android version but they should look somewhat like this.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 4,
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          // 1.
                          Text(
                            "1. Swipe the notification to the right, and click on the settings cog.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications/1.jpg',
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications/2.jpg',
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          // 2.
                          Text(
                            "2. Click on 'settings'.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications/3.jpg',
                          ),
                          // 3.
                          SizedBox(
                            height: 30.h,
                          ),
                          Text(
                            "3. Click on 'Foreground Notification'.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications/4.jpg',
                          ),
                          // 4.
                          SizedBox(
                            height: 30.h,
                          ),
                          Text(
                            "4. Switch 'Minimize notifications' to ON",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          Text(
                            "5. Switch 'App icon badges' to OFF",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications/6.jpg',
                          ),
                          // 6.
                          SizedBox(
                            height: 30.h,
                          ),
                          Text(
                            "6. Restart the foreground task:",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          // Restart button.
                          Center(
                            child: SolidRoundedButton(
                              text: "Restart",
                              onPressed: () async {
                                // Only allow restarting every 'minSecsBetweenRestarts' seconds.
                                if (DateTime.now()
                                        .difference(lastRestartTime)
                                        .inSeconds >
                                    minSecsBetweenRestarts) {
                                  lastRestartTime = DateTime.now();
                                  if (await ForegroundTask.isRunningService()) {
                                    ForegroundTask.restart();
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            const NavigationWrapper(),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          Text(
                              "Voilà, now the Spartial notification is minimized!",
                              style: Theme.of(context).textTheme.subtitle1,
                              maxLines: 2,
                              textAlign: TextAlign.center),
                          SizedBox(
                            height: 30.h,
                          ),
                        ]
                      // IOS instructions.
                      : Platform.isIOS ? [
                        Text(
                            "How to hide Spartial notification",
                            style: Theme.of(context).textTheme.headline2,
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          Text(
                            "The steps to hide the Spartial notification might be a little different for every iOS version but they should look somewhat like this.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 4,
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          // 1.
                          Text(
                            "1. Go to settings and click on Spartial.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications_ios/1.jpg',
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          // 2.
                          Text(
                            "2. Go to 'Notifications'.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications_ios/2.jpg',
                          ),
                          // 3.
                          SizedBox(
                            height: 30.h,
                          ),
                          Text(
                            "3. Disable 'Lock Screen', 'Banners', 'Sounds', and 'Badges'.",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications_ios/3.jpg',
                          ),
                          // 4.
                          SizedBox(
                            height: 30.h,
                          ),
                          Image.asset(
                            'assets/hide_notifications_ios/4.jpg',
                          ),
                          // 5.
                          SizedBox(
                            height: 30.h,
                          ),
                          Text(
                            "5. Restart the foreground task:",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          // Restart button.
                          Center(
                            child: SolidRoundedButton(
                              text: "Restart",
                              onPressed: () async {
                                // Only allow restarting every 'minSecsBetweenRestarts' seconds.
                                if (DateTime.now()
                                        .difference(lastRestartTime)
                                        .inSeconds >
                                    minSecsBetweenRestarts) {
                                  lastRestartTime = DateTime.now();
                                  if (await ForegroundTask.isRunningService()) {
                                    ForegroundTask.restart();
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            const NavigationWrapper(),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          Text(
                              "Voilà, now the Spartial notification is minimized!",
                              style: Theme.of(context).textTheme.subtitle1,
                              maxLines: 2,
                              textAlign: TextAlign.center),
                          SizedBox(
                            height: 30.h,
                          ),
                      ] : [],
                ))),
          ),
        ),
      ),
    );
  }
}
