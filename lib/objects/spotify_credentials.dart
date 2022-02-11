import 'package:hive/hive.dart';
import 'package:spotify/spotify.dart';

part 'spotify_credentials.g.dart';

// This is basically a copy of 'spotify_credentials' from the dart spotify library.
// https://github.com/rinukkusu/spotify-dart/blob/master/lib/src/spotify_credentials.dart
// Had to make this copy in order to make it work with storing it in hive.
@HiveType(typeId: 3)
class SpotifyCredentials extends HiveObject {
  /// The client identifier for this Spotify client.
  ///
  /// Spotify issues each client a separate client identifier and secret,
  /// which allows the server to tell which client is accessing it.
  @HiveField(0)
  String? clientId;

  /// The client secret for this Spotify client.
  ///
  /// Spotify issues each client a separate client identifier and secret,
  /// which allows the server to tell which client is accessing it.
  @HiveField(1)
  String? clientSecret;

  /// The token that is sent to Spotify to prove the authorization of a client.
  @HiveField(2)
  String? accessToken;

  /// The token that is sent to Spotify to refresh the credentials.
  ///
  /// This may be `null`, indicating that the credentials can't be refreshed.
  @HiveField(3)
  String? refreshToken;

  /// The URL of the Spotify endpoint that's used to refresh the credentials.
  ///
  /// This may be `null`, indicating that the credentials can't be refreshed.
  @HiveField(4)
  String? tokenEndpoint;

  /// The specific permissions being requested from Spotify.
  ///
  /// See https://developer.spotify.com/documentation/general/guides/scopes/
  /// for a full list of available scopes.
  @HiveField(5)
  List<String>? scopes;

  /// The date at which these credentials will expire, stored in the user's
  /// local time.
  ///
  /// This is likely to be a few seconds earlier than the server's idea of the
  /// expiration date.
  @HiveField(6)
  DateTime? expiration;

  SpotifyCredentials();

  /// Constructor from SpotifyApiCredentials
  SpotifyCredentials.fromSpotifyApiCredentials(
      SpotifyApiCredentials credentials) {
    clientId = credentials.clientId;
    clientSecret = credentials.clientSecret;
    accessToken = credentials.accessToken;
    refreshToken = credentials.refreshToken;
    scopes = credentials.scopes;
    expiration = credentials.expiration;
    tokenEndpoint = credentials.tokenEndpoint.toString();
  }

  /// Converts this object to type SpotifyApiCredentials.
  SpotifyApiCredentials toSpotifyApiCredentials() {
    return SpotifyApiCredentials(
      clientId,
      clientSecret,
      accessToken: accessToken,
      refreshToken: refreshToken,
      scopes: scopes,
      expiration: expiration,
    );
  }
}
