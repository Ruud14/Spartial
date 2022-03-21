import 'package:flutter/services.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/objects/spotify_credentials.dart';
import 'package:spartial/services/foreground_task.dart';
import 'package:spartial/services/logger.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/storage.dart';
import 'dart:core';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:device_info/device_info.dart';
import 'package:oauth2/src/client.dart';
import 'package:oauth2/src/credentials.dart';
import 'package:oauth2/src/authorization_exception.dart';

/// Spotify api that uses the spotify web api.
class SpotifyWebApi {
  static String clientID() {
    return Settings.clientID();
  }

  /// The URI to redirect to after the user grants or denies permission.
  static const String redirectUri = "spartial://callback";

  /// Scopes for spotify web api access.
  static final scopes = [
    'user-read-email',
    'user-read-private', // Necessary to check for premium.
    'playlist-modify-private',
    'playlist-modify-public',
    'user-read-playback-state',
    'user-modify-playback-state'
  ];

  /// Maximum number of songs per getSongs request.
  static const int maxSongsPerRequest = 50;

  /// Spotify api object.
  static SpotifyApi? spotify;

  /// Puts the 'creds' into SpotifyCredentials storage.
  static void _saveCredentials(SpotifyApiCredentials creds) {
    Storage.setSpotifyCredentials(
        SpotifyCredentials.fromSpotifyApiCredentials(creds));
  }

  /// Is run whenever the refresh token is expired.
  /// it automatically refreshes the token if it's expired.
  /// We set the new credentials in storage.
  static void _onCredentialsRefreshed(Credentials newCred) {
    SpotifyApiCredentials newApiCred = SpotifyApiCredentials(clientID(), null,
        accessToken: newCred.accessToken,
        refreshToken: newCred.refreshToken,
        scopes: newCred.scopes,
        expiration: newCred.expiration);
    _saveCredentials(newApiCred);
    if (newCred.refreshToken != null) {
      Logger.info("Refresh token has automatically been refreshed.");
    }
    ForegroundTask.restart();
  }

  /// assigns 'spotify' based on the stored Spotify credentials.
  static void _createSpotifyFromStoredCredentials() {
    if (Storage.spotifyCredentialsStorage.containsKey('SpotifyCredentials')) {
      // Get the spotify credentials from storage.
      SpotifyApiCredentials creds = Storage.spotifyCredentialsStorage
          .get('SpotifyCredentials')!
          .toSpotifyApiCredentials();

      // Had to manually create a new oauth2 client and then create a SpotifyApi instance with .fromClient.
      // Because using SpotifyApi(creds) didn't work with PKCE.
      // https://github.com/rinukkusu/spotify-dart/issues/81
      Credentials credentials = Credentials(creds.accessToken!,
          refreshToken: creds.refreshToken,
          idToken: creds.clientId,
          tokenEndpoint: creds.tokenEndpoint,
          scopes: creds.scopes,
          expiration: creds.expiration);
      Client client = Client(credentials,
          identifier: clientID(),
          secret: null,
          basicAuth: true,
          httpClient: http.Client(),
          // Set onCredentialsRefreshed so that it automatically refreshes the token if it's expired.
          onCredentialsRefreshed: _onCredentialsRefreshed);

      spotify = SpotifyApi.fromClient(client);
    } else {
      throw AuthorizationException("", "", Uri.parse(""));
    }
  }

  /// Get the current player state.
  /// Throws SocketException when a connection cannot be established.
  static Future<Player> _getPlayerState() async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }

    Player player = await spotify!.me.currentlyPlaying();
    return player;
  }

  /// Plays song with id 'id' in spotify and restarts the foreground service so that
  /// Spartial is immediately active when playing.
  static void playInSpotify(String id) async {
    String url = "spotify:track:" + id;

    try {
      await launch(url);
    } on PlatformException {
      await launch(
          "https://play.google.com/store/apps/details?id=com.spotify.music");
    }

    ForegroundTask.restart();
  }

  /// Creates a playlist in spotify with songs (based on 'ids')
  /// NOTE THAT THIS METHOD USES URI's INSTEAD OF ID's.
  /// Returns true for success, false otherwise.
  static Future<bool> createSpotifyPlaylist(List<String> trackUris,
      String title, String description, bool isPrivate) async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }
    try {
      description =
          "Spartial Lets you automatically skip parts of songs that you don't want to hear. Check it out at Spartial.app";

      // Create the playlist
      String? id = (await spotify!.me.get()).id;
      Playlist playlist = await spotify!.playlists.createPlaylist(id!, title,
          description: description, public: !isPrivate);
      // Maximum number of songs that can be added to a playlist at once.
      int maxNumberOfSongsPerApiCall = 99;

      // Add songs to the playlist.
      int numberOfCalls =
          (trackUris.length / maxNumberOfSongsPerApiCall).ceil();
      for (int i = 1; i < numberOfCalls + 1; i++) {
        await spotify!.playlists.addTracks(
            trackUris.sublist(
                (i - 1) * maxNumberOfSongsPerApiCall,
                i * maxNumberOfSongsPerApiCall > trackUris.length
                    ? trackUris.length
                    : i * maxNumberOfSongsPerApiCall),
            playlist.id!);
      }

      return true;
    } on Exception catch (e) {
      Logger.error(e);
      return false;
    }
  }

  /// Get a song based on the id.
  /// Throws SocketException when a connection cannot be established.
  static Future<Song> getSong(String id) async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }

    Track track = await spotify!.tracks.get(id);
    Song song = Song.fromData(
        id,
        track.name!,
        track.artists![0].name!,
        track.album!.images![0].url,
        (track.durationMs! / 1000).floor(),
        DateTime.now());

    return song;
  }

  /// Get songs based on the ids.
  /// Throws SocketException when a connection cannot be established.
  static Future<List<Song>> getSongs(List<String> ids) async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }

    List<Song> songs = [];

    /// Spotify requests can take up to maxSongsPerRequest songs at once, so we must split.
    if (ids.length > maxSongsPerRequest) {
      List<List<int>> groups = [];
      int numberOfGroups = (ids.length / maxSongsPerRequest).ceil();
      for (int i = 0; i < numberOfGroups; i++) {
        if (i + 1 == numberOfGroups) {
          groups.add([i * maxSongsPerRequest, ids.length]);
        } else {
          groups.add([i * maxSongsPerRequest, (i + 1) * maxSongsPerRequest]);
        }
      }
      for (List<int> group in groups) {
        List<String> idsToGet = ids.sublist(group[0], group[1]);
        songs += await getSongs(idsToGet);
      }
    } else {
      List<Track> tracks = List<Track>.from(await spotify!.tracks.list(ids));
      for (Track t in tracks) {
        Song song = Song.fromData(
            t.id!,
            t.name!,
            t.artists![0].name!,
            t.album!.images![0].url,
            (t.durationMs! / 1000).floor(),
            DateTime.now());
        songs.add(song);
      }
    }

    return songs;
  }

  /// Wether or not spotify is currently playing.
  static Future<bool?> getSpotifyIsPlaying() async {
    // If we only want to run spartial on this device.
    if (Settings.onlyOnThisDevice()) {
      try {
        String thisDeviceName = (await DeviceInfoPlugin().androidInfo).model;
        List<Device> devices = await SpotifyWebApi.getDevices();
        bool thisDeviceActive = false;
        for (Device d in devices) {
          if (d.name == thisDeviceName &&
              d.isActive != null &&
              d.isActive == true) {
            thisDeviceActive = true;
            break;
          }
        }
        // Return fals if the current device is not active.
        if (!thisDeviceActive) {
          return false;
        }
      } on Exception {}
    }
    return (await _getPlayerState()).is_playing;
  }

  /// Get a list of devices on which spotify can play.
  static Future<List<Device>> getDevices() async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }
    return List<Device>.from(await spotify!.me.devices());
  }

  /// Skips the current song to next one.
  static Future<void> skipSong() async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }
    Uri path = Uri.parse("https://api.spotify.com/v1/me/player/next");
    String? token = (await spotify!.getCredentials()).accessToken;
    if (token != null) {
      http.Response response = await http.post(path, headers: {
        "Authorization": "Bearer " + token,
      });

      // Refresh the token if the response returns an error.
      if (response.statusCode.toString().startsWith("40")) {
        Logger.error(Exception(
            "Received error code ${response.statusCode} while trying to skip song."));
      }
    } else {
      Logger.error(
          Exception("NO TOKEN FOUND IN SPOTIFYAPI while trying to skip song."));
    }
  }

  /// Sets the current playback position time to positionMS.
  static Future<void> seekToPosition(int positionMS) async {
    if (spotify == null) {
      _createSpotifyFromStoredCredentials();
    }
    Uri path = Uri.parse(
        "https://api.spotify.com/v1/me/player/seek?position_ms=" +
            positionMS.toString());
    String? token = (await spotify!.getCredentials()).accessToken;
    if (token != null) {
      http.Response response = await http.put(path, headers: {
        "Authorization": "Bearer " + token,
      });

      // Refresh the token if the response returns an error.
      if (response.statusCode.toString().startsWith("40")) {
        Logger.error(Exception(
            "Received error code ${response.statusCode} while trying to seek position in player."));
      }
    } else {
      Logger.error(Exception(
          "NO TOKEN FOUND IN SPOTIFYAPI while trying to seek position in player."));
    }
  }

  /// Variables used to prevent double skipping. (the sloppy way.)
  static const int secondsBetweenSkips = 2;
  static DateTime? lastSkip;

  /// Checks if the currently playing song is a stored song.
  /// If it is, it will skip to the right time range.
  /// Throws error if a connection with the player can't be established.
  static Future<void> checkAndChangePlaybackTime(
      {required Function onSkip}) async {
    // Get the player state.
    // This will throw an error if a connection with the player can't be established.
    Player player = await _getPlayerState();
    Track? track = player.item;
    // If there is a track playing
    if (track != null) {
      String? trackID = track.id;
      int? playbackPosition = player.progress_ms;
      // Check wether the currently playing song is stored.
      if (trackID != null &&
          playbackPosition != null &&
          Storage.songStorage.containsKey(trackID)) {
        Song song = Storage.getSong(trackID);
        // Convert all song integer (Seconds) time ranges to int (Miliseconds) time ranges.
        List<int> timeRanges = [0];
        for (int range in song.timeRanges) {
          timeRanges.add(range * 1000);
        }
        timeRanges.add((song.durationSeconds * 1000));
        // Loop over all time ranges.
        for (int i = 0; i < timeRanges.length - 1; i++) {
          // If the current playback position is the time range.
          if (playbackPosition > timeRanges[i] &&
              playbackPosition < timeRanges[i + 1]) {
            // Skip to the next timerange if the current playback position is outside of a timerange.
            if (i % 2 == 0) {
              // Implemented this to prevent double skipping.
              // This is a really sloppy workaround but I couldn't quickly find out why it skipped twice.
              if (lastSkip == null) {
                lastSkip = DateTime.now();
              } else if (DateTime.now().difference(lastSkip!).inSeconds <
                  secondsBetweenSkips) {
                Logger.info("Prevented a double skip");
                break;
              } else {
                lastSkip = DateTime.now();
              }
              // seek to the right position in the song.
              // Skip the song if the next position is at the end.
              onSkip();
              if (timeRanges[i + 1] == song.durationSeconds * 1000) {
                await skipSong();
              } else {
                await seekToPosition(timeRanges[i + 1]);
              }
            }
            break;
          }
        }
      }
    }
  }

  /// Authenticate with spotify through a webview.
  /// This should only be done if we've never authenticated before
  /// or the refresh token has been revoked for some reason.
  /// Throws SocketException when a connection cannot be established.
  static Future<void> authenticate(
      {required Function onNoPremium,
      required Function onNotRegisteredInDashboard}) async {
    final credentials = SpotifyApiCredentials(clientID(), null);
    final grant = SpotifyApi.authorizationCodeGrant(credentials);

    // Create the authUri.
    final authUri = grant.getAuthorizationUrl(
      Uri.parse(redirectUri),
      scopes: scopes,
    );

    // Launch the auth uri in the browser.
    if (await canLaunch(authUri.toString())) {
      await launch(authUri.toString());

      // Listen for the response
      linkStream.listen((String? link) async {
        if (link == null) {
          throw Exception("Link == null!");
        } else {
          if (link.startsWith(redirectUri)) {
            // Manually hide the web view on iOS.
            if (Platform.isIOS){
              try {
                await closeWebView();
              } on Exception catch (e){
                Logger.error(e);
              }
              
            }
            String responseUri = link;
            // Deal with access being denied.
            if (responseUri.endsWith('access_denied')) {
              return;
            }
            try {
              spotify = SpotifyApi.fromAuthCodeGrant(grant, responseUri);
              // Check if the user has premium.
              User user = await spotify!.me.get();
              // According to https://developer.spotify.com/documentation/web-api/reference/#/operations/get-current-users-profile
              // 'open' can be considered the same as 'free'.
              if (user.product == "free" || user.product == "open") {
                onNoPremium();
                return;
              }
              // Put the spotify credentials in storage.
              Storage.setSpotifyCredentials(
                  SpotifyCredentials.fromSpotifyApiCredentials(
                await spotify!.getCredentials(),
              ));
            } on AuthorizationException catch (e) {
              Logger.error(e);
              // User not registered in the Developer Dashboard
            } on FormatException catch (e) {
              Logger.error(e);
              onNotRegisteredInDashboard();
            } on Exception catch (e) {
              Logger.error(Exception(
                  "Exception during authentication: ${e.toString()}"));
            }
          }
        }
      });
    }
  }
}
