// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final int typeId = 0;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as String,
      name: fields[1] as String,
      progress: (fields[2] as num).toDouble(),
      directoryPath: fields[3] as String?,
      tasks: (fields[4] as List).cast<String>(),
      status: fields[5] as String,
      description: fields[6] as String?,
      category: fields[9] as String?,
      aiAssistant: fields[10] as String?,
      planJson: fields[11] as String?,
      helpLevel: fields[12] as HelpLevel,
      complexity: fields[13] as Complexity,
      history: (fields[14] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      sharedUsers: (fields[7] as List).cast<String>(),
      sharedGroups: (fields[8] as List).cast<String>(),
      priority: fields[15] as String?,
      startDate: fields[16] as DateTime?,
      dueDate: fields[17] as DateTime?,
      tags: (fields[18] as List).cast<String>(),
      customFields: (fields[19] as Map?)?.cast<String, dynamic>(),
      comments: (fields[20] as List).cast<CommentModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.progress)
      ..writeByte(3)
      ..write(obj.directoryPath)
      ..writeByte(4)
      ..write(obj.tasks)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.aiAssistant)
      ..writeByte(11)
      ..write(obj.planJson)
      ..writeByte(12)
      ..write(obj.helpLevel)
      ..writeByte(13)
      ..write(obj.complexity)
      ..writeByte(14)
      ..write(obj.history)
      ..writeByte(7)
      ..write(obj.sharedUsers)
      ..writeByte(8)
      ..write(obj.sharedGroups)
      ..writeByte(15)
      ..write(obj.priority)
      ..writeByte(16)
      ..write(obj.startDate)
      ..writeByte(17)
      ..write(obj.dueDate)
      ..writeByte(18)
      ..write(obj.tags)
      ..writeByte(19)
      ..write(obj.customFields)
      ..writeByte(20)
      ..write(obj.comments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
