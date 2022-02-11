import 'package:flutter/material.dart';
import 'package:spartial/screens/introduction.dart';
import 'package:spartial/screens/minimize_notification.dart';
import 'package:spartial/services/foreground_task.dart';
import 'package:spartial/services/logger.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/wrappers/navigation_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen on which settings can be configured.
class SettinsPage extends StatefulWidget {
  /// Whether the storage options part of the settings should be highlighted.
  final bool highlightStorage;
  const SettinsPage({Key? key, this.highlightStorage = false})
      : super(key: key);

  @override
  _SettinsPageState createState() => _SettinsPageState();
}

class _SettinsPageState extends State<SettinsPage> {
  /// Lists of logs
  List<String> errorLogs = [];
  List<String> infoLogs = [];

  /// Number of times the 'settings' text has to be tapped to unlock the dev options.
  int numberOfTapsToUnlockDevOptions = 5;

  /// Initial number of seconds between idle api calls.
  int initialSecondsBetweenIdleApiCalls = Settings.secondsBetweenApiCalls();

  /// Get the logs
  void getLogs() async {
    if (Settings.showDevOptions()) {
      List<String> _errorLogs = await Logger.getErrorLogs();
      List<String> _infoLogs = await Logger.getInfoLogs();
      setState(() {
        errorLogs = _errorLogs;
        infoLogs = _infoLogs;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getLogs();
  }

  @override
  void dispose() {
    // Restart the foreground task if we've changed the number of seconds between idle api calls.
    try {
      if (initialSecondsBetweenIdleApiCalls !=
          Settings.secondsBetweenApiCalls()) {
        ForegroundTask.restart();
      }
    } on Exception catch (e) {
      Logger.error(e);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Slider for selecting the number of seconds between api calls when Spartial is idle.
    Slider idleApiCallPerSecondSlider = Slider(
      activeColor: Theme.of(context).colorScheme.secondary,
      value: Settings.secondsBetweenApiCalls().toDouble(),
      onChanged: (value) {
        setState(() {
          Settings.setSecondsBetweenIdleApiCalls(value.floor());
        });
      },
      min: 1.0,
      divisions: 29,
      max: 30.0,
      label: Settings.secondsBetweenApiCalls().toString(),
    );

    /// Number of times the 'Settings' text has been tapped.
    /// (to unlock the dev settings.)
    int settingsTaps = 0;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: GestureDetector(
            child:
                Text("Settings", style: Theme.of(context).textTheme.headline2),
            // 'Settings' Can be tapped to unlock the dev options.
            onTap: () {
              settingsTaps += 1;
              if (settingsTaps >= numberOfTapsToUnlockDevOptions &&
                  !Settings.showDevOptions()) {
                Settings.setShowDevOptions(true);
                getLogs();
                // Setstate is already called in getLogs
                // so no need to call it here again.
                CustomSnackBar.show(context, "Dev options unlocked ↓");
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(90.w, 30.h, 90.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Performance",
                  style: Theme.of(context).textTheme.headline2,
                ),
                SizedBox(
                  height: 60.h,
                ),
                Text(
                  "Seconds between idle API calls",
                  style: Theme.of(context).textTheme.subtitle1,
                  maxLines: 1,
                ),
                SizedBox(
                  height: 15.h,
                ),
                Text(
                  "When idle, Spartial checks if Spotify is playing once every few seconds. This slider changes that time. Higher results in better battery life. Lower causes Spartial to activate more quickly after being idle for a while.",
                  style: Theme.of(context).textTheme.subtitle2,
                  maxLines: 5,
                ),
                SizedBox(
                  height: 45.h,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      idleApiCallPerSecondSlider.min.floor().toString(),
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                    Expanded(child: idleApiCallPerSecondSlider),
                    Text(
                      idleApiCallPerSecondSlider.max.floor().toString(),
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                  ],
                ),

                SizedBox(
                  height: 30.h,
                ),
                // Only on this device
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Only on this device",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 1,
                          ),
                          Text(
                            "When active, Spartial will only do it's job when listening to music on this device. The listening experience on other devices will be unaffected.",
                            style: Theme.of(context).textTheme.subtitle2,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      activeColor: Theme.of(context).colorScheme.secondary,
                      inactiveTrackColor:
                          Theme.of(context).highlightColor.withOpacity(0.5),
                      value: Settings.onlyOnThisDevice(),
                      onChanged: (value) async {
                        setState(() {
                          Settings.setOnlyOnThisDevice(value);
                        });
                        // We must restart the foreground service.
                        if (await ForegroundTask.isRunningService()) {
                          ForegroundTask.restart();
                        }
                        CustomSnackBar.show(context, "Saved!");
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 30.h,
                ),
                // Check for updates
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Check for updates",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 1,
                          ),
                          Text(
                            "When active, Spartial will check for updates everytime it is opened.",
                            style: Theme.of(context).textTheme.subtitle2,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      activeColor: Theme.of(context).colorScheme.secondary,
                      inactiveTrackColor:
                          Theme.of(context).highlightColor.withOpacity(0.5),
                      value: Settings.checkForUpdates(),
                      onChanged: (value) async {
                        setState(() {
                          Settings.setCheckForUpdates(value);
                        });
                        CustomSnackBar.show(context, "Saved!");
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 30.h,
                ),
                // hide Spartial notification
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hide Spartial notification",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 1,
                          ),
                          Text(
                            "How to hide the constant Spotify notification.",
                            style: Theme.of(context).textTheme.subtitle2,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                        highlightColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  const MinimizeNotificationPage()));
                        },
                        icon: Icon(
                          Icons.info_outlined,
                          color:
                              Theme.of(context).highlightColor.withOpacity(0.5),
                        ))
                  ],
                ),
                SizedBox(
                  height: 30.h,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Show introduction screen",
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 1,
                          ),
                          Text(
                            "Forgot how Spartial works? You can reopen the introcution screen here.",
                            style: Theme.of(context).textTheme.subtitle2,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                        highlightColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const IntroductionPage(
                                    reopened: true,
                                  )));
                        },
                        icon: Icon(
                          Icons.mobile_screen_share,
                          color:
                              Theme.of(context).highlightColor.withOpacity(0.5),
                        ))
                  ],
                ),
                SizedBox(
                  height: 60.h,
                ),

                Center(
                  child: Container(
                    color: widget.highlightStorage
                        ? Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3)
                        : Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Storage",
                          style: Theme.of(context).textTheme.headline2,
                        ),
                        SizedBox(
                          height: 60.h,
                        ),
                        // Current storage capacity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Current storage capacity:",
                              style: Theme.of(context).textTheme.subtitle1,
                              maxLines: 1,
                            ),
                            Text(
                              "${Storage.songStorage.keys.length}/${Settings.getSongStorageCapacity()}",
                              style: Theme.of(context).textTheme.headline3,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 60.h,
                        ),
                        Text(
                          "Upgrades",
                          style: Theme.of(context).textTheme.subtitle1,
                          maxLines: 1,
                        ),
                        // Storage upgrade 1
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Storage upgrade ${Settings.storageCap1}",
                                  style: Theme.of(context).textTheme.subtitle1,
                                  maxLines: 1,
                                ),
                                Text(
                                  "You can store up to ${Settings.storageCap1} songs",
                                  style: Theme.of(context).textTheme.subtitle2,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerRight),
                              child: Text("€ ${Settings.storageCap1Price}",
                                  style: Theme.of(context).textTheme.headline3),
                              onPressed: () {
                                Settings.upgradeStorageCapacityTo(
                                    Settings.storageCap1);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        // Storage upgrade 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Storage upgrade ${Settings.storageCap2}",
                                  style: Theme.of(context).textTheme.subtitle1,
                                  maxLines: 1,
                                ),
                                Text(
                                  "You can store up to ${Settings.storageCap2} songs",
                                  style: Theme.of(context).textTheme.subtitle2,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerRight),
                              child: Text("€ ${Settings.storageCap2Price}",
                                  style: Theme.of(context).textTheme.headline3),
                              onPressed: () {
                                Settings.upgradeStorageCapacityTo(
                                    Settings.storageCap2);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        // Storage upgrade 3
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Storage upgrade ${Settings.storageCap3}",
                                  style: Theme.of(context).textTheme.subtitle1,
                                  maxLines: 1,
                                ),
                                Text(
                                  "You can store up to ${Settings.storageCap3} songs",
                                  style: Theme.of(context).textTheme.subtitle2,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerRight),
                              child: Text("€ ${Settings.storageCap3Price}",
                                  style: Theme.of(context).textTheme.headline3),
                              onPressed: () {
                                Settings.upgradeStorageCapacityTo(
                                    Settings.storageCap3);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 60.h,
                ),
                // Logout button
                TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft),
                    onPressed: () {
                      Storage.deleteSpotifyCredentials();
                      ForegroundTask.stop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NavigationWrapper(
                                  checkShared: false,
                                  startForegroundTask: false,
                                )),
                      );
                    },
                    child: Text("Logout",
                        style: Theme.of(context).textTheme.subtitle1)),
                SizedBox(
                  height: Settings.showDevOptions() ? 200.h : 0,
                ),
                // DEV OPTIONS
                Settings.showDevOptions()
                    ? Container(
                        color: Colors.red.withOpacity(0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DEV OPTIONS",
                              style: Theme.of(context).textTheme.headline2,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Restart foreground task",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        "Manually restart the Spartial foreground task.",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2,
                                        maxLines: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                    highlightColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    onPressed: () async {
                                      if (await ForegroundTask
                                          .isRunningService()) {
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
                                    },
                                    icon: Icon(
                                      Icons.refresh,
                                      color: Theme.of(context)
                                          .highlightColor
                                          .withOpacity(0.5),
                                    ))
                              ],
                            ),
                            SizedBox(
                              height: 60.h,
                            ),
                            SolidRoundedButton(
                                onPressed: () {
                                  Settings.setShowDevOptions(false);
                                  setState(() {});
                                },
                                text: "Hide dev options"),
                            SolidRoundedButton(
                                onPressed: () {
                                  setState(() {
                                    Settings.setStorageCapacity(100);
                                  });
                                },
                                text: "Set storage cap back to 100"),
                            SolidRoundedButton(
                                onPressed: () {
                                  Logger.clearErrorLogs();
                                  setState(() {});
                                },
                                text: "Clear error logs"),
                            SolidRoundedButton(
                                onPressed: () {
                                  Logger.clearInfoLogs();
                                  setState(() {});
                                },
                                text: "Clear info logs"),
                            SolidRoundedButton(
                                onPressed: () {
                                  Logger.shareErrorLogs();
                                },
                                text: "Share error logs"),
                            SolidRoundedButton(
                                onPressed: () {
                                  Logger.shareInfoLogs();
                                  setState(() {});
                                },
                                text: "Share info logs"),
                            SizedBox(
                              height: 60.h,
                            ),
                            // Logs
                            Text(
                              "Error logs",
                              style: Theme.of(context).textTheme.headline3,
                            ),
                            Container(
                              color: Colors.red,
                              child: errorLogs.isEmpty
                                  ? const Text("No error logs yet.")
                                  : Column(
                                      children: List.generate(
                                          errorLogs.length,
                                          (index) => SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Text(
                                                  ". " + errorLogs[index],
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ))),
                            ),
                            SizedBox(
                              height: 60.h,
                            ),
                            Text(
                              "Info logs",
                              style: Theme.of(context).textTheme.headline3,
                            ),
                            Container(
                              color: Colors.red,
                              child: infoLogs.isEmpty
                                  ? const Text("No info logs yet.")
                                  : Column(
                                      children: List.generate(
                                          infoLogs.length,
                                          (index) => SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Text(
                                                  ". " + infoLogs[index],
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ))),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Made by",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      TextButton(
                          onPressed: () async {
                            try {
                              await launch("https://github.com/Ruud14");
                            } on Exception catch (e) {
                              Logger.error(e);
                            }
                          },
                          child: Text("Ruud Brouwers",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              )))
                    ],
                  ),
                ),
                SizedBox(
                  height: 60.h,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
