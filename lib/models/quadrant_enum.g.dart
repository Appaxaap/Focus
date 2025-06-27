// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quadrant_enum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuadrantAdapter extends TypeAdapter<Quadrant> {
  @override
  final int typeId = 1;

  @override
  Quadrant read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Quadrant.urgentImportant;
      case 1:
        return Quadrant.notUrgentImportant;
      case 2:
        return Quadrant.urgentNotImportant;
      case 3:
        return Quadrant.notUrgentNotImportant;
      default:
        return Quadrant.urgentImportant;
    }
  }

  @override
  void write(BinaryWriter writer, Quadrant obj) {
    switch (obj) {
      case Quadrant.urgentImportant:
        writer.writeByte(0);
        break;
      case Quadrant.notUrgentImportant:
        writer.writeByte(1);
        break;
      case Quadrant.urgentNotImportant:
        writer.writeByte(2);
        break;
      case Quadrant.notUrgentNotImportant:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuadrantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
