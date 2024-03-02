import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spartial/screens/add_song.dart';
import 'package:spartial/screens/allow_ignoring_battery_optimization.dart';
import 'package:spartial/screens/introduction.dart';
import 'package:spartial/screens/loading.dart';
import 'package:spartial/screens/minimize_notification.dart';
import 'package:spartial/screens/reauthenticate.dart';
import 'package:spartial/screens/import_songs.dart';
import 'package:spartial/screens/songs.dart';
import 'package:hive/hive.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:spartial/screens/storage_limit_reached.dart';
import 'package:spartial/services/converters.dart';
import 'package:spartial/services/notifications.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/services/foreground_task.dart';

/// Navigates the user to the right screens.
class NavigationWrapper extends StatefulWidget {
  /// Wether or not to check for shared content.
  final bool checkShared;

  /// Whether the hide notification instruction page should be shown.
  final bool openHideNotificationInstructions;

  /// Whether the foreground task should be started.
  final bool startForegroundTask;
  const NavigationWrapper(
      {Key? key,
      this.checkShared = true,
      this.openHideNotificationInstructions = false,
      this.startForegroundTask = true})
      : super(key: key);

  @override
  _NavigationWrapperState createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  /// Stream for listening for shared data.
  late StreamSubscription _intentDataStreamSubscription;

  /// Whether battery optimization for spartial is disabled.
  bool? isIgnoringBatteryOptimization;

  /// Whether the user has been sent to the AllowIgnoringBatteryOptimizationPage.
  bool hasRoutedToAllowIgnoringBatteryOptimizationPage = false;

  // Close the local database whenever the app is closed.
  @override
  void dispose() {
    Hive.close();
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  /// Deals with the data that has been shared to Spartial.
  /// The add_song screen will be opened if the shared url is a spotify song.
  /// The ImportSongsPage will be shown if the shared url contains spartial song data.
  void handleSharedData(String value) async {
    bool sharedSpotifySong =
        value.startsWith("https://open.spotify.com/track/");
    bool sharedStoredSongs =
        value.toString().startsWith("https://" + Converters.shareUriPrefix) ||
            value.toString().startsWith(Converters.shareUriPrefix);

    // Return if something else than a spotify song or a list of songs is shared.
    if (!(sharedSpotifySong || sharedStoredSongs)) {
      return;
    }
    // Only show the add song screen when the user has passed the intro screen.
    if (!Settings.shownIntroductionScreen()) {
      // Show a message when the user shares a song before passing intro screen.
      showSharedBeforeCompletIntroDialog();
    } else {
      // Only allow sharing when when ignoring battery optimization is disabled.
      bool isDisabled = await handleNotIgnoringBatteryOptimization();
      if (isDisabled) {
        // Check if the shared data is a shared spotify song.
        if (sharedSpotifySong) {
          // Only show the add song screen when the user has passed the intro screen.
          String id = value.split('/').last.split('?').first;

          // Check if the shared song is already in storage.
          // If it is, then set the editingSong.
          if (Storage.songStorage.containsKey(id)) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddSongScreen(
                      trackID: id,
                      initialSong: Storage.getSong(id),
                      sharedStoredSong: true,
                    )));
          } else {
            if (Storage.hasReachedSongsLimit()) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const StorageLimitReachedPage()));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AddSongScreen(
                        trackID: id,
                      )));
            }
          }
          // Check if the shared data is a list of songs.
        } else if (sharedStoredSongs) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ImportSongsPage(
                    sharedUri: value,
                  )));
        }
      }
    }
  }

  /// Starts the foreground task if it isn't running already
  /// and widget.startForegroundTask is set to true.
  void startForegroundTask() async {
    if (widget.startForegroundTask) {
      bool isRunninService = await ForegroundTask.isRunningService();
      if (!isRunninService) {
        ForegroundTask.initAndStartForegroundTask();
      }
    }
  }

  /// Check wether the user has disabbled battery optimisation and handles accordingly.
  /// Redirects to AllowIgnoringBatteryOptimizationPage if the user hasn't disabled.
  Future<bool> handleNotIgnoringBatteryOptimization() async {
    bool isIgnoring = await ForegroundTask.isIgnoringBatteryOptimizations();

    // Go to AllowIgnoringBatteryOptimizationPage if not ignoring
    if (!isIgnoring && !hasRoutedToAllowIgnoringBatteryOptimizationPage) {
      hasRoutedToAllowIgnoringBatteryOptimizationPage = true;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const AllowIgnoringBatteryOptimizationPage()),
      );
      if (result == true) {
        isIgnoring = result;
      }
    }
    setState(() {
      isIgnoringBatteryOptimization = isIgnoring;
    });
    return isIgnoring;
  }

  /// Shows a dialog that tells the user that they sould first
  /// complete the intro before adding any song.
  void showSharedBeforeCompletIntroDialog() {
    showDialog(
        context: context,
        builder: (context) {
          // Create a blurry background behind the dialog.
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                "Damn you're quick!",
                style: Theme.of(context).textTheme.headline2,
              ),
              content: Text(
                "Please complete the intro before adding any songs ;)",
                style: Theme.of(context).textTheme.headline3,
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Ok',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ))),
              ],
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    LocalNotification.init();
    if (widget.checkShared) {
      // Set up sharing to the app.
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> files) {
          if (files.isEmpty) return;
          handleSharedData(files[0].path);
      }, onError: (err) {});

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> files) {
        if (files.isEmpty) return;
        handleSharedData(files[0].path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the prefered device orientation.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Show the intro page if it hasn't been shown before.
    if (!Settings.shownIntroductionScreen()) {
      return const IntroductionPage();
    } else {
      if (isIgnoringBatteryOptimization == true) {
        // Start the foregound task
        startForegroundTask();
        // Navigate to the reauthentication page when the login is expired.
        if (Storage.getSpotifyCredentials() == null) {
          return const ReauthenticatePage();
        }
        // Show the minimizeNotificationPage if thats specified.
        if (widget.openHideNotificationInstructions) {
          return const MinimizeNotificationPage(
            backPage: SongsPage(),
          );
        } else {
          return const SongsPage();
        }
      } else {
        handleNotIgnoringBatteryOptimization();
        return const LoadingScreen();
      }
    }
  }
}
