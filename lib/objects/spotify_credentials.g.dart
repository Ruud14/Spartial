// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spotify_credentials.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpotifyCredentialsAdapter extends TypeAdapter<SpotifyCredentials> {
  @override
  final int typeId = 3;

  @override
  SpotifyCredentials read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpotifyCredentials()
      ..clientId = fields[0] as String?
      ..clientSecret = fields[1] as String?
      ..accessToken = fields[2] as String?
      ..refreshToken = fields[3] as String?
      ..tokenEndpoint = fields[4] as String?
      ..scopes = (fields[5] as List?)?.cast<String>()
      ..expiration = fields[6] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, SpotifyCredentials obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.clientId)
      ..writeByte(1)
      ..write(obj.clientSecret)
      ..writeByte(2)
      ..write(obj.accessToken)
      ..writeByte(3)
      ..write(obj.refreshToken)
      ..writeByte(4)
      ..write(obj.tokenEndpoint)
      ..writeByte(5)
      ..write(obj.scopes)
      ..writeByte(6)
      ..write(obj.expiration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotifyCredentialsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
