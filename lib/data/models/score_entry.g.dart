import 'package:hive_flutter/hive_flutter.dart';
import 'score_entry.dart';

/// Hive type adapter for ScoreEntry
class ScoreEntryAdapter extends TypeAdapter<ScoreEntry> {
  @override
  final int typeId = 0;

  @override
  ScoreEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreEntry(
      category: fields[0] as String,
      score: fields[1] as int,
      streak: fields[2] as int,
      correctAnswers: fields[3] as int,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.streak)
      ..writeByte(3)
      ..write(obj.correctAnswers)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
