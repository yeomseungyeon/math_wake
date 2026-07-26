// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String,
      label: fields[1] as String,
      hour: fields[2] as int,
      minute: fields[3] as int,
      repeatDays: (fields[4] as List?)?.cast<bool>(),
      isEnabled: fields[5] as bool,
      difficulty: fields[6] as AlarmDifficulty,
      problemCount: fields[7] as int,
      soundAsset: fields[8] as String,
      volume: fields[9] as double,
      fadeIn: fields[10] as bool,
      vibrationPattern: fields[11] as VibrationPattern,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.repeatDays)
      ..writeByte(5)
      ..write(obj.isEnabled)
      ..writeByte(6)
      ..write(obj.difficulty)
      ..writeByte(7)
      ..write(obj.problemCount)
      ..writeByte(8)
      ..write(obj.soundAsset)
      ..writeByte(9)
      ..write(obj.volume)
      ..writeByte(10)
      ..write(obj.fadeIn)
      ..writeByte(11)
      ..write(obj.vibrationPattern);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmDifficultyAdapter extends TypeAdapter<AlarmDifficulty> {
  @override
  final int typeId = 1;

  @override
  AlarmDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmDifficulty.easy;
      case 1:
        return AlarmDifficulty.medium;
      case 2:
        return AlarmDifficulty.hard;
      default:
        return AlarmDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmDifficulty obj) {
    switch (obj) {
      case AlarmDifficulty.easy:
        writer.writeByte(0);
        break;
      case AlarmDifficulty.medium:
        writer.writeByte(1);
        break;
      case AlarmDifficulty.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VibrationPatternAdapter extends TypeAdapter<VibrationPattern> {
  @override
  final int typeId = 2;

  @override
  VibrationPattern read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VibrationPattern.off;
      case 1:
        return VibrationPattern.shortPulse;
      case 2:
        return VibrationPattern.longPulse;
      case 3:
        return VibrationPattern.strong;
      default:
        return VibrationPattern.off;
    }
  }

  @override
  void write(BinaryWriter writer, VibrationPattern obj) {
    switch (obj) {
      case VibrationPattern.off:
        writer.writeByte(0);
        break;
      case VibrationPattern.shortPulse:
        writer.writeByte(1);
        break;
      case VibrationPattern.longPulse:
        writer.writeByte(2);
        break;
      case VibrationPattern.strong:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VibrationPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
