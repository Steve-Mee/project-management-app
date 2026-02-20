class RoleDefinition {
  final String id;
  final String name;
  final List<String> permissions;

  const RoleDefinition({
    required this.id,
    required this.name,
    required this.permissions,
  });

  RoleDefinition copyWith({
    String? id,
    String? name,
    List<String>? permissions,
  }) {
    return RoleDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions,
    };
  }

  static RoleDefinition fromMap(Map<String, dynamic> map) {
    return RoleDefinition(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      permissions:
          (map['permissions'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class GroupDefinition {
  final String id;
  final String name;
  final String roleId;
  final List<String> members;

  const GroupDefinition({
    required this.id,
    required this.name,
    required this.roleId,
    required this.members,
  });

  GroupDefinition copyWith({
    String? id,
    String? name,
    String? roleId,
    List<String>? members,
  }) {
    return GroupDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'roleId': roleId,
      'members': members,
    };
  }

  static GroupDefinition fromMap(Map<String, dynamic> map) {
    return GroupDefinition(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      members: (map['members'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
