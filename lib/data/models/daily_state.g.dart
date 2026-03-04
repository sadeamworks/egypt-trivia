import 'package:hive/hive.dart';
import 'daily_state.dart';

/// Type adapter for DailyState
class DailyStateAdapter extends TypeAdapter<DailyState> {
  @override
  final int typeId = 1;

  @override
  DailyState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyState(
      dateKey: fields[0] as String,
      completed: fields[1] as bool,
      score: fields[2] as int,
      correctAnswers: fields[3] as int,
      currentStreak: fields[4] as int,
      bestStreak: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyState obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.completed)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.correctAnswers)
      ..writeByte(4)
      ..write(obj.currentStreak)
      ..writeByte(5)
      ..write(obj.bestStreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
