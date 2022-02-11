import 'package:hive/hive.dart';

part 'song.g.dart';

// To generate hive types: flutter packages pub run build_runner build
// To clear hive: https://stackoverflow.com/questions/61440070/how-to-reset-a-hive-database-in-flutter

/// Instances of this object represent Songs added to Spartial
/// They are stored in the hive database.
@HiveType(typeId: 0)
class Song extends HiveObject {
  // Constructor with arguments.
  Song.fromData(this.id, this.name, this.artist, this.imageReference,
      this.durationSeconds, this.added);

  // Constructor without arguments.
  Song();

  /// Spotify id of the song.
  @HiveField(0)
  late String id;

  /// Name of the song.
  @HiveField(1)
  late String name;

  /// First artist of the song.
  @HiveField(2)
  late String artist;

  /// Url to song cover image.
  @HiveField(3)
  String? imageReference;

  /// Duration of the song in seconds.
  @HiveField(4)
  late int durationSeconds;

  /// Time ranges for which part(s) to skip.
  @HiveField(5)
  List<int> timeRanges = [];

  /// Time added (used for sorting)
  @HiveField(6)
  late DateTime added;
}
