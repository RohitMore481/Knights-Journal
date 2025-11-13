// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameModelAdapter extends TypeAdapter<GameModel> {
  @override
  final int typeId = 1;

  @override
  GameModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameModel(
      white: fields[0] as String,
      black: fields[1] as String,
      event: fields[2] as String,
      location: fields[3] as String,
      date: fields[4] as String,
      notes: fields[5] as String,
      result: fields[6] as String,
      movesSan: (fields[7] as List).cast<String>(),
      pgn: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GameModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.white)
      ..writeByte(1)
      ..write(obj.black)
      ..writeByte(2)
      ..write(obj.event)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.result)
      ..writeByte(7)
      ..write(obj.movesSan)
      ..writeByte(8)
      ..write(obj.pgn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
