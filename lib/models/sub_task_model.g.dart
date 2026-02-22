// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubTaskAdapter extends TypeAdapter<SubTask> {
  @override
  final int typeId = 4;

  @override
  SubTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubTask(
      id: fields[0] as String,
      taskId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      isCompleted: fields[4] as bool,
      assignedTo: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SubTask obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.assignedTo)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
