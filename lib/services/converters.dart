import 'package:spartial/objects/song.dart';
import 'package:spartial/services/logger.dart';
import 'package:spartial/services/spotify.dart';

/// Class containing all kinds of convert methods.
class Converters {
  /// Prefix for shared song(s).
  static const String shareUriPrefix = "spartial.app/share/";
  static const String _shareUriSeparator = ";";
  static const String _idAndRangeSeparator = "-";

  /// Converts songs list to a url that can be shared.
  static String songsToShareUrl(List<Song> songs) {
    List<String> songIDs = [];
    for (Song s in songs) {
      songIDs.add(s.id);
    }

    List<String> stringSongs = [];

    for (Song s in songs) {
      stringSongs
          .add("${s.id}$_idAndRangeSeparator${(s.timeRanges).toString()}");
    }
    String decodedUri = stringSongs.join(_shareUriSeparator);
    String encodedUri = shareUriPrefix + Uri.encodeComponent(decodedUri);
    return encodedUri;
  }

  /// Converts a url to a songs list.
  static Future<List<Song>> urlToSongs(String url) async {
    if (url.startsWith("https://")) {
      url = url.replaceAll("https://", "");
    }
    String encodedUri = url.replaceAll(shareUriPrefix, "");
    String decodedUri = Uri.decodeComponent(encodedUri);

    List<String> stringSongs = decodedUri.split(_shareUriSeparator);
    Map<String, List<int>> songPairs = {};
    for (String strSong in stringSongs) {
      // Try to convert the strSong to a song with time ranges.
      try {
        List<String> splitStrSong = strSong.split(_idAndRangeSeparator);
        List<int> rangeNumbers = List<int>.from(
            (splitStrSong[1].replaceAll("[", "").replaceAll("]", "").split(","))
                .map((e) => int.parse(e)));
        if (!(rangeNumbers.length % 2 == 0) || rangeNumbers.isEmpty) {
          throw Exception("Uneven number of time ranges.");
        }
        songPairs[splitStrSong[0]] = rangeNumbers;
      } on Exception catch (e) {
        Logger.error(Exception(
            "Could not decode song: '$strSong' error message: ${e.toString()}"));
      }
    }

    List<Song> songs =
        await SpotifyWebApi.getSongs(List<String>.from(songPairs.keys));

    for (Song s in songs) {
      s.timeRanges = songPairs[s.id]!;
    }

    return songs;
  }
}
