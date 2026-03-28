// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_asset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeneratedAssetAdapter extends TypeAdapter<GeneratedAsset> {
  @override
  final int typeId = 7;

  @override
  GeneratedAsset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeneratedAsset(
      id: fields[0] as String,
      projectId: fields[1] as String,
      taskId: fields[2] as String?,
      prompt: fields[3] as String,
      metadata: (fields[4] as Map).cast<String, dynamic>(),
      fileUrl: fields[5] as String,
      format: fields[6] as GeneratedAssetFormat,
      version: (fields[7] as num).toInt(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime?,
      status: fields[10] as GeneratedAssetStatus,
    );
  }

  @override
  void write(BinaryWriter writer, GeneratedAsset obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.taskId)
      ..writeByte(3)
      ..write(obj.prompt)
      ..writeByte(4)
      ..write(obj.metadata)
      ..writeByte(5)
      ..write(obj.fileUrl)
      ..writeByte(6)
      ..write(obj.format)
      ..writeByte(7)
      ..write(obj.version)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedAssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GeneratedAssetFormatAdapter extends TypeAdapter<GeneratedAssetFormat> {
  @override
  final int typeId = 5;

  @override
  GeneratedAssetFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GeneratedAssetFormat.glb;
      case 1:
        return GeneratedAssetFormat.fbx;
      case 2:
        return GeneratedAssetFormat.png;
      case 3:
        return GeneratedAssetFormat.usdz;
      default:
        return GeneratedAssetFormat.glb;
    }
  }

  @override
  void write(BinaryWriter writer, GeneratedAssetFormat obj) {
    switch (obj) {
      case GeneratedAssetFormat.glb:
        writer.writeByte(0);
        break;
      case GeneratedAssetFormat.fbx:
        writer.writeByte(1);
        break;
      case GeneratedAssetFormat.png:
        writer.writeByte(2);
        break;
      case GeneratedAssetFormat.usdz:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedAssetFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GeneratedAssetStatusAdapter extends TypeAdapter<GeneratedAssetStatus> {
  @override
  final int typeId = 6;

  @override
  GeneratedAssetStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GeneratedAssetStatus.pending;
      case 1:
        return GeneratedAssetStatus.processing;
      case 2:
        return GeneratedAssetStatus.completed;
      case 3:
        return GeneratedAssetStatus.failed;
      default:
        return GeneratedAssetStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, GeneratedAssetStatus obj) {
    switch (obj) {
      case GeneratedAssetStatus.pending:
        writer.writeByte(0);
        break;
      case GeneratedAssetStatus.processing:
        writer.writeByte(1);
        break;
      case GeneratedAssetStatus.completed:
        writer.writeByte(2);
        break;
      case GeneratedAssetStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedAssetStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeneratedAsset _$GeneratedAssetFromJson(Map<String, dynamic> json) =>
    _GeneratedAsset(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      taskId: json['task_id'] as String?,
      prompt: json['prompt'] as String? ?? '',
      metadata: json['metadata'] == null
          ? const <String, dynamic>{}
          : _metadataFromJson(json['metadata']),
      fileUrl: json['file_url'] as String? ?? '',
      format: json['format'] == null
          ? GeneratedAssetFormat.glb
          : _formatFromJson(json['format']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: _requiredDateTimeFromJson(json['created_at']),
      updatedAt: _optionalDateTimeFromJson(json['updated_at']),
      status: json['status'] == null
          ? GeneratedAssetStatus.pending
          : _statusFromJson(json['status']),
    );

Map<String, dynamic> _$GeneratedAssetToJson(_GeneratedAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'task_id': instance.taskId,
      'prompt': instance.prompt,
      'metadata': _metadataToJson(instance.metadata),
      'file_url': instance.fileUrl,
      'format': _formatToJson(instance.format),
      'version': instance.version,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'status': _statusToJson(instance.status),
    };
