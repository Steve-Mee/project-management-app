// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'generated_asset.freezed.dart';
part 'generated_asset.g.dart';

@HiveType(typeId: 5)
enum GeneratedAssetFormat {
  @HiveField(0)
  glb,
  @HiveField(1)
  fbx,
  @HiveField(2)
  png,
  @HiveField(3)
  usdz,
}

@HiveType(typeId: 6)
enum GeneratedAssetStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
}

@freezed
@HiveType(typeId: 7)
abstract class GeneratedAsset with _$GeneratedAsset {
  const GeneratedAsset._();

  @JsonSerializable(explicitToJson: true)
  const factory GeneratedAsset({
    @HiveField(0) @Default('') String id,
    @HiveField(1) @JsonKey(name: 'project_id') @Default('') String projectId,
    @HiveField(2) @JsonKey(name: 'task_id') String? taskId,
    @HiveField(3) @Default('') String prompt,
    @HiveField(4)
    @JsonKey(
      fromJson: _metadataFromJson,
      toJson: _metadataToJson,
    )
    @Default(<String, dynamic>{})
    Map<String, dynamic> metadata,
    @HiveField(5) @JsonKey(name: 'file_url') @Default('') String fileUrl,
    @HiveField(6)
    @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
    @Default(GeneratedAssetFormat.glb)
    GeneratedAssetFormat format,
    @HiveField(7) @Default(1) int version,
    @HiveField(8)
    @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
    required DateTime createdAt,
    @HiveField(9)
    @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
    DateTime? updatedAt,
    @HiveField(10)
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
    @Default(GeneratedAssetStatus.pending)
    GeneratedAssetStatus status,
  }) = _GeneratedAsset;

  factory GeneratedAsset.fromJson(Map<String, dynamic> json) =>
      _$GeneratedAssetFromJson(json);
}

Map<String, dynamic> _metadataFromJson(Object? value) {
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _metadataToJson(Map<String, dynamic> value) => value;

GeneratedAssetFormat _formatFromJson(Object? value) {
  final raw = (value as String?)?.trim().toLowerCase();
  switch (raw) {
    case 'fbx':
      return GeneratedAssetFormat.fbx;
    case 'png':
      return GeneratedAssetFormat.png;
    case 'usdz':
      return GeneratedAssetFormat.usdz;
    case 'glb':
    default:
      return GeneratedAssetFormat.glb;
  }
}

String _formatToJson(GeneratedAssetFormat value) => value.name;

GeneratedAssetStatus _statusFromJson(Object? value) {
  final raw = (value as String?)?.trim().toLowerCase();
  switch (raw) {
    case 'processing':
      return GeneratedAssetStatus.processing;
    case 'completed':
      return GeneratedAssetStatus.completed;
    case 'failed':
      return GeneratedAssetStatus.failed;
    case 'pending':
    default:
      return GeneratedAssetStatus.pending;
  }
}

String _statusToJson(GeneratedAssetStatus value) => value.name;

DateTime _requiredDateTimeFromJson(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}

DateTime? _optionalDateTimeFromJson(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
