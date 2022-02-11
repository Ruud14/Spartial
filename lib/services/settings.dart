import 'package:spartial/objects/settings.dart';
import 'package:spartial/services/storage.dart';

/// Service for changing settings.
class Settings {
  // Storage capacity upgrades.
  static int storageCap0 = 100;
  static int storageCap1 = 1000;
  static int storageCap2 = 10000;
  static int storageCap3 = 100000;

  // Prices for storage capacity upgrades (in euros.)
  static double storageCap1Price = 0;
  static double storageCap2Price = 0;
  static double storageCap3Price = 0;
  // static double storageCap1Price = 0.49;
  // static double storageCap2Price = 1.49;
  // static double storageCap3Price = 2.49;

  // Default client id.
  static const String defaultClientID = "e42acad7f2704a9e9296a3d8623d559d";

  /// Sorting options mapped to the name of the sorting option that should be displayed.
  static Map<String, String> sortingOptions = {
    'title': 'Title',
    'artist': 'Artist',
    'date': 'Time added',
    'duration': 'Duration'
  };

  /// Private method for getting the settings from the storage.
  static SettingsObject _getSettings() {
    return Storage.getSettings();
  }

  /// Sets whether the introduction screen has been shown or not.
  static void setShownIntroductionScreen(bool value) {
    SettingsObject settings = _getSettings();
    settings.shownIntroductionScreen = value;
    Storage.saveSettings(settings);
  }

  /// Sets bool indicating whether to let Spartial only do it's job when listening on this device.
  static void setOnlyOnThisDevice(bool value) {
    SettingsObject settings = _getSettings();
    settings.onlyOnThisDevice = value;
    Storage.saveSettings(settings);
  }

  /// Sets the number of songs the user can store.
  static void setStorageCapacity(int value) {
    SettingsObject settings = _getSettings();
    settings.songStorageCapacity = value;
    Storage.saveSettings(settings);
  }

  /// Sets the number of songs the user can store only
  /// if the current storage capacity is less than the new value.
  static void upgradeStorageCapacityTo(int value) {
    SettingsObject settings = _getSettings();
    if (value <= settings.songStorageCapacity) {
      return;
    }
    settings.songStorageCapacity = value;
    Storage.saveSettings(settings);
  }

  /// Whether the introduction screen has been shown or not.
  static bool shownIntroductionScreen() {
    return _getSettings().shownIntroductionScreen;
  }

  /// Only let Spartial do it's job when listening on this device.
  static bool onlyOnThisDevice() {
    return _getSettings().onlyOnThisDevice;
  }

  /// Returns the number of songs the user can store.
  static int getSongStorageCapacity() {
    return _getSettings().songStorageCapacity;
  }

  /// Get what the songs list is sorted by.
  static String sortBy() {
    return _getSettings().sortBy;
  }

  /// Returns whether the songs list should be sorted in ascending order.
  static bool sortAscending() {
    return _getSettings().sortAscending;
  }

  /// Set what the songs list should be sorted by.
  static void setSortBy(String value) {
    if (!sortingOptions.keys.contains(value)) {
      throw Exception("No such sorting: " + value.toString());
    }
    SettingsObject settings = _getSettings();
    settings.sortBy = value;
    Storage.saveSettings(settings);
  }

  /// Set whether the songs list should be sorted in ascending oder.
  static void setSortAscending(bool value) {
    SettingsObject settings = _getSettings();
    settings.sortAscending = value;
    Storage.saveSettings(settings);
  }

  /// Set whether the dev options should be shown.
  static void setShowDevOptions(bool value) {
    SettingsObject settings = _getSettings();
    settings.showDevOptions = value;
    Storage.saveSettings(settings);
  }

  /// Returns whether the songs list should be sorted in ascending order.
  static bool showDevOptions() {
    return _getSettings().showDevOptions;
  }

  /// Set the client ID.
  static void setClientID(String value) {
    SettingsObject settings = _getSettings();
    settings.clientID = value;
    Storage.saveSettings(settings);
  }

  /// Get the client ID.
  static String clientID() {
    return _getSettings().clientID;
  }

  /// Set whether we should check for updates.
  static void setCheckForUpdates(bool value) {
    SettingsObject settings = _getSettings();
    settings.checkForUpdates = value;
    Storage.saveSettings(settings);
  }

  /// Whether we should check for updates.
  static bool checkForUpdates() {
    return _getSettings().checkForUpdates;
  }

  /// Set the number of seconds between api calls when Spartial is idle.
  static void setSecondsBetweenIdleApiCalls(int value) {
    SettingsObject settings = _getSettings();
    settings.secondsBetweenIdleApiCalls = value;
    Storage.saveSettings(settings);
  }

  /// Number of seconds between api calls when Spartial is idle.
  static int secondsBetweenApiCalls() {
    return _getSettings().secondsBetweenIdleApiCalls;
  }
}
