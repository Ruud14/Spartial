import 'package:spartial/objects/settings.dart';
import 'package:spartial/objects/song.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spartial/objects/spotify_credentials.dart';
import 'package:spartial/services/foreground_task.dart';
import 'package:spartial/services/settings.dart';

/// Handles everything storage related.
/// Storing songs, settings and Spotify credentials.
class Storage {
  /// Hive boxes.
  static var songStorage = Hive.box<Song>('songs');
  static var settingsStorage = Hive.box<SettingsObject>('settings');
  static var spotifyCredentialsStorage =
      Hive.box<SpotifyCredentials>('SpotifyCredentials');

  /// Hive box streams.
  static final songStorageStream = Hive.box<Song>('songs').listenable();
  static final spotifyCredentialsStorageStream =
      Hive.box<SpotifyCredentials>('SpotifyCredentials').listenable();

  /// Gets the spotify credentials from storage.
  static SpotifyCredentials? getSpotifyCredentials() {
    return spotifyCredentialsStorage.get('SpotifyCredentials');
  }

  /// Deletes the stored spotify credentials.
  static SpotifyCredentials? deleteSpotifyCredentials() {
    SpotifyCredentials? creds =
        spotifyCredentialsStorage.get('SpotifyCredentials');
    if (creds != null) {
      creds.delete();
    }
  }

  /// Sets the spotify credentials in storage.
  static void setSpotifyCredentials(SpotifyCredentials creds) {
    spotifyCredentialsStorage.put('SpotifyCredentials', creds);
  }

  /// Add a song to the hive storage with song.id as key.
  static void addSong(Song s) {
    songStorage.put(s.id, s);
    // Restart the service so that the foreground task isolate storage is up to date as wel.
    // This is a hacky workaround, TODO: find a better solution.
    ForegroundTask.restart();
  }

  /// Add multiple songs to the hive storage with song.id as key.
  /// Use this method instead of multiple calls to addSong
  /// to prevent restarting the foreground service multiple times.
  static void addSongs(List<Song> songs) {
    for (Song s in songs) {
      songStorage.put(s.id, s);
    }
    // Restart the service so that the foreground task isolate storage is up to date as wel.
    // This is a hacky workaround, TODO: find a better solution.
    ForegroundTask.restart();
  }

  /// Gets the settings.
  /// Returns new settings when no settings were found in storage.
  static SettingsObject getSettings() {
    SettingsObject? settings = settingsStorage.get('settings');
    if (settings != null) {
      return settings;
    } else {
      return SettingsObject.withInitialSongStorageCapacity(
          songStorageCapacity: Settings.storageCap2);
    }
  }

  /// Save settings s.
  static void saveSettings(SettingsObject s) {
    settingsStorage.put('settings', s);
  }

  /// Get a song from storage using it's id.
  /// Throws an exception if there is no such song.
  static Song getSong(String id) {
    var storedSong = songStorage.get(id);
    if (storedSong == null) {
      throw Exception("Song $id could not be found in storage.");
    } else {
      return storedSong;
    }
  }

  /// Get all songs from storage.
  static List<Song> getAllSongs() {
    return songStorage.values.toList();
  }

  /// Update a song in the storage
  static void updateSong(Song s) {
    s.save();
    // See addSong
    ForegroundTask.restart();
  }

  /// Remove a song from storage.
  static void deleteSong(Song s) {
    s.delete();
    // See addSong
    ForegroundTask.restart();
  }

  /// Remove a list of songs from storage.
  static void deleteSongs(List<Song> songs) {
    for (Song s in songs) {
      s.delete();
    }
    // See addSong
    ForegroundTask.restart();
  }

  /// Clear the songs storage.
  static void clearSongs() {
    songStorage.clear();
  }

  /// Returns whether the user has reached the song storage limit.
  static bool hasReachedSongsLimit() {
    return songStorage.keys.length >= getSettings().songStorageCapacity;
  }

  /// Returns the amount of storage the user would get if he/she were to buy the next storage upgrade.
  static int getNextStorageUpgradeCapacity() {
    int currentStorageCap = Settings.getSongStorageCapacity();
    if (currentStorageCap < Settings.storageCap1) {
      return Settings.storageCap1;
    } else if (currentStorageCap < Settings.storageCap2) {
      return Settings.storageCap2;
    } else if (currentStorageCap < Settings.storageCap3) {
      return Settings.storageCap3;
    } else {
      return currentStorageCap;
    }
  }

  /// Returns the price for the next storage upgrade. (in euros)
  static double getNextStorageUpgradePrice() {
    int currentStorageCap = Settings.getSongStorageCapacity();
    if (currentStorageCap < Settings.storageCap1) {
      return Settings.storageCap1Price;
    } else if (currentStorageCap < Settings.storageCap2) {
      return Settings.storageCap2Price;
    } else if (currentStorageCap < Settings.storageCap3) {
      return Settings.storageCap3Price;
    } else {
      return 0.0;
    }
  }
}
