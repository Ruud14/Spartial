// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsObjectAdapter extends TypeAdapter<SettingsObject> {
  @override
  final int typeId = 2;

  @override
  SettingsObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsObject()
      ..shownIntroductionScreen = fields[0] as bool
      ..onlyOnThisDevice = fields[1] as bool
      ..songStorageCapacity = fields[2] as int
      ..sortBy = fields[3] as String
      ..sortAscending = fields[4] as bool
      ..showDevOptions = fields[5] as bool
      ..clientID = fields[6] as String
      ..checkForUpdates = fields[7] as bool
      ..secondsBetweenIdleApiCalls = fields[8] as int;
  }

  @override
  void write(BinaryWriter writer, SettingsObject obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.shownIntroductionScreen)
      ..writeByte(1)
      ..write(obj.onlyOnThisDevice)
      ..writeByte(2)
      ..write(obj.songStorageCapacity)
      ..writeByte(3)
      ..write(obj.sortBy)
      ..writeByte(4)
      ..write(obj.sortAscending)
      ..writeByte(5)
      ..write(obj.showDevOptions)
      ..writeByte(6)
      ..write(obj.clientID)
      ..writeByte(7)
      ..write(obj.checkForUpdates)
      ..writeByte(8)
      ..write(obj.secondsBetweenIdleApiCalls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
