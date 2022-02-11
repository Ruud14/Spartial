import 'package:hive/hive.dart';
import 'package:spartial/services/settings.dart';
part 'settings.g.dart';

/// Object of which an instance is stored in the hive database to store settings.
@HiveType(typeId: 2)
class SettingsObject extends HiveObject {
  SettingsObject();

  SettingsObject.withInitialSongStorageCapacity(
      {required this.songStorageCapacity});

  /// Whether the introduction screen has been shown or not.
  @HiveField(0)
  bool shownIntroductionScreen = false;

  /// Only let Spartial do it's job when listening on this device.
  @HiveField(1)
  bool onlyOnThisDevice = false;

  /// The number of songs the user can store.
  @HiveField(2)
  int songStorageCapacity = 100;

  /// By what the songs list should be sorted.
  /// 'title', 'artist', 'date', 'duration'
  @HiveField(3)
  String sortBy = "title";

  /// Sorting order.
  @HiveField(4)
  bool sortAscending = true;

  /// Whether or not the dev options should be shown.
  @HiveField(5)
  bool showDevOptions = false;

  /// Client ID
  @HiveField(6)
  String clientID = Settings.defaultClientID;

  /// Whether or not to check for updates.
  @HiveField(7)
  bool checkForUpdates = true;

  /// Seconds between idle API calls.
  @HiveField(8)
  int secondsBetweenIdleApiCalls = 8;
}
