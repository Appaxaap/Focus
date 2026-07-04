// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_completion_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusCompletionEventAdapter extends TypeAdapter<FocusCompletionEvent> {
  @override
  final int typeId = 1;

  @override
  FocusCompletionEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusCompletionEvent(
      id: fields[0] as String,
      taskId: fields[1] as String,
      completedAt: fields[2] as DateTime,
      quadrantAtCompletion: fields[3] as Quadrant,
      titleSnapshot: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FocusCompletionEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.completedAt)
      ..writeByte(3)
      ..write(obj.quadrantAtCompletion)
      ..writeByte(4)
      ..write(obj.titleSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusCompletionEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
