import 'dart:io';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:spartial/objects/settings.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/objects/spotify_credentials.dart';
import 'package:spartial/services/logger.dart';
import 'package:spartial/services/notifications.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/spotify.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oauth2/src/authorization_exception.dart';
import 'package:spartial/services/storage.dart';

/// The foreground task start callback function should always be a top-level function.
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

/// Class containing methods that perform actions on the foreground task.
class ForegroundTask {
  /// Number of miliseconds between every foreground task onEvent call.
  static const int _eventIntervalTimeMS = 1000;

  /// The message shown on the notification right after the foreground task starts.
  static String initialNotificationMessage = "Starting...";

  /// Calls both initForegroundTask and startForegroundTask
  static void initAndStartForegroundTask() async {
    await _initForegroundTask();
    await _startForegroundTask();
  }

  /// Restarts the foreground service.
  static void restart() async {
    await FlutterForegroundTask.restartService();
  }

  /// Stopst the foreground service.
  static void stop() {
    FlutterForegroundTask.stopService();
  }

  /// Initializes the forground task.
  static Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.MIN,
        priority: NotificationPriority.MIN,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher_icon',
        ),
        buttons: [
          const NotificationButton(id: 'stopButton', text: 'Stop'),
          //const NotificationButton(id: 'restartButton', text: 'Restart'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: _eventIntervalTimeMS,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
  }

  /// Returns whether or not the foreground task is running.
  static Future<bool> isRunningService() async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Starts the foreground task.
  static Future<void> _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Spartial',
        notificationText: initialNotificationMessage,
        callback: startCallback,
      );
    }
  }

  /// Asks for persion to ignore battery optimisation if the permision hasn't been granted yet.
  /// Returns true if the user has (already) accepted.
  static Future<bool> requestIgnoreBatteryOptimization() async {
    bool isIgnoring = await isIgnoringBatteryOptimizations();
    // Ask the user to allow ignoring battery optimisation.
    if (!isIgnoring) {
      return FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } else {
      return true;
    }
  }

  /// Returns whether or not isIgnoringBatteryOptimizations.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  /// Opens the phone settings to ignore battery optimization.
  static Future<bool> openIgnoreBatteryOptimizationSettings() async {
    return await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
  }
}

/// Foreground task handler that uses the spotify web api.
class ForegroundTaskHandler extends TaskHandler {
  /// Whether Spotify is playing.
  bool? isSpotifyPlaying = false;

  /// Whether we have an internet connection.
  bool hasInternet = true;

  /// Whether reauthentication is required.
  bool reauthRequired = true;

  /// Forground notification message texts.
  String reauthRequiredMessage = "Login expired, Login to contiue...";
  String noInternetConnectionMessage =
      "Cannot connect to Spotify, check your internet connection...";
  String isPlayingMessage = "Running. Tap to open.";
  String idleMessage = "Idle. Waiting for Spotify to play.";

  /// Current notification message text.
  String currentMessage = ForegroundTask.initialNotificationMessage;

  /// Time until checking the playerState again.
  DateTime? waitUntilChecking;

  /// Seconds to wait between every player state check when not playing.
  int secondsBetweenChecking = 8;

  /// Seconds to wait after a skip before skipping again.
  int secondsAfterSkip = SpotifyWebApi.secondsBetweenSkips;

  /// Time until stop checking the player state.
  /// This is used whenever the player is paused. In that case we should wait before disconnecting.
  DateTime waitUntilStopChecking = DateTime.now();

  /// Time before disonecting after the player has paused/stopped playing.
  int secondsBeforeStopChecking = 20;

  /// Runs when the foreground task (Re)starts.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Initialize hive whenever the foreground task starts.
    // This is needed because hive boxes have to be reopened in every isolate.
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(SpotifyCredentialsAdapter());
    Hive.registerAdapter(SettingsObjectAdapter());
    await Hive.openBox<Song>('songs');
    await Hive.openBox<SpotifyCredentials>('SpotifyCredentials');
    await Hive.openBox<SettingsObject>('settings');
    // Set the number of seconds between api calls.
    secondsBetweenChecking = Settings.secondsBetweenApiCalls();
    // Don't stop checking the player state in the first secondsBeforeStopChecking seconds.
    // This Immediately activates spartial when pressing 'play in spotify' (which restarts the foreground task).
    _setWaitSecondsBeforeStopChecking(secondsBeforeStopChecking);
  }

  /// Sets the value of waitUntilChecking.
  /// Waits for 'seconds' if seconds > current waiting time.
  /// Waits for current waiting time if 'seconds' < current waiting time.
  void _waitSecondsBeforeChecking(int seconds) {
    if (waitUntilChecking == null ||
        waitUntilChecking!.difference(DateTime.now()).inSeconds < seconds ||
        waitUntilChecking!.difference(DateTime.now()).inSeconds.abs() <
            seconds) {
      waitUntilChecking = DateTime.now().add(Duration(seconds: seconds));
    }
  }

  /// Set time at wich we should, at it's earliest, stop checking the player state.
  void _setWaitSecondsBeforeStopChecking(int seconds) {
    waitUntilStopChecking = DateTime.now().add(Duration(seconds: seconds));
  }

  /// Update the text of the forground notification.
  void _updateNotification(String message) async {
    currentMessage = message;
    FlutterForegroundTask.updateService(
        notificationTitle: "Spartial",
        notificationText: message,
        callback: null);
  }

  /// Runs every _eventIntervalTimeMS while the foreground task is running.
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Wait when there is still time to wait.
    if (waitUntilChecking != null) {
      if (waitUntilChecking!.difference(DateTime.now()).inSeconds > 0) {
        return;
      } else {
        waitUntilChecking = null;
      }
    }

    // Try to get the spotify player state.
    try {
      // Check wether spotify is playing.
      isSpotifyPlaying = await SpotifyWebApi.getSpotifyIsPlaying();
      hasInternet = true;
      reauthRequired = false;
      if (isSpotifyPlaying == null) {
        // Still in search for a bug:
        Logger.error(Exception("ISPLAYING IS NULL!"));
      } else if (isSpotifyPlaying!) {
        // Check and change player if needed when a song is playing.
        await SpotifyWebApi.checkAndChangePlaybackTime(onSkip: () {
          // wait time after a skip to prevent an accidental double skip.
          _waitSecondsBeforeChecking(secondsAfterSkip);
        });
        // Set time at wich we should, at it's earliest, stop checking the player state.
        _setWaitSecondsBeforeStopChecking(secondsBeforeStopChecking);
      } else {
        // Stop checking player state if waitUntilStopChecking is over.
        if (waitUntilStopChecking.difference(DateTime.now()).inSeconds < 0) {
          _waitSecondsBeforeChecking(secondsBetweenChecking);
        }
      }
      // Hide the reauth required notification if it is present.
      LocalNotification.hide();
      // Catch SocketExceptions (e.g. no internet)
    } on SocketException catch (e) {
      await Logger.error(e);
      hasInternet = false;
    } on AuthorizationException catch (e) {
      await Logger.error(e);
      reauthRequired = true;
      Storage.deleteSpotifyCredentials();
    } on Exception catch (e) {
      await Logger.error(e);
    }

    // Update the foreground task notification text
    // whenever something has changed.
    if (!hasInternet && !(currentMessage == noInternetConnectionMessage)) {
      _updateNotification(noInternetConnectionMessage);
    } else if (reauthRequired &&
        !(currentMessage == reauthRequiredMessage) &&
        hasInternet) {
      try {
        // Let the user know that they must reauthenticate.
        LocalNotification.show(
            title: "Spartial Login required",
            body: "Your login has expired, Tap to reauthenticate.");
      } on Exception catch (e) {
        Logger.error(e);
      }
      _updateNotification(reauthRequiredMessage);
    } else if (isSpotifyPlaying! &&
        !(currentMessage == isPlayingMessage) &&
        hasInternet &&
        !reauthRequired) {
      _updateNotification(isPlayingMessage);
    } else if (isSpotifyPlaying == null) {
      // Still in search for a bug:
      _updateNotification("ISPLAYING IS NULL!");
    } else {
      if (!(currentMessage == idleMessage) &&
          hasInternet &&
          !reauthRequired &&
          !isSpotifyPlaying!) {
        _updateNotification(idleMessage);
      }
    }
  }

  /// Callback for when a button on the foreground task is pressed.
  @override
  void onButtonPressed(String id) {
    if (id == 'stopButton') {
      ForegroundTask.stop();
    } else if (id == 'restartButton') {
      ForegroundTask.restart();
    }
  }

  /// Is run when the foreground task is stopped.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await FlutterForegroundTask.clearAllData();
  }
}
