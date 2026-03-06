import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_models.freezed.dart';
part 'role_models.g.dart';

@freezed
abstract class RoleDefinition with _$RoleDefinition {
  const RoleDefinition._();

  const factory RoleDefinition({
    @Default('') String id,
    @Default('') String name,
    @Default(<String>[]) List<String> permissions,
  }) = _RoleDefinition;

  factory RoleDefinition.fromJson(Map<String, dynamic> json) =>
      _$RoleDefinitionFromJson(json);

  Map<String, dynamic> toMap() {
    return toJson();
  }

  static RoleDefinition fromMap(Map<String, dynamic> map) {
    return RoleDefinition.fromJson(map);
  }
}

@freezed
abstract class GroupDefinition with _$GroupDefinition {
  const GroupDefinition._();

  const factory GroupDefinition({
    @Default('') String id,
    @Default('') String name,
    @Default('') String roleId,
    @Default(<String>[]) List<String> members,
  }) = _GroupDefinition;

  factory GroupDefinition.fromJson(Map<String, dynamic> json) =>
      _$GroupDefinitionFromJson(json);

  Map<String, dynamic> toMap() {
    return toJson();
  }

  static GroupDefinition fromMap(Map<String, dynamic> map) {
    return GroupDefinition.fromJson(map);
  }
}
