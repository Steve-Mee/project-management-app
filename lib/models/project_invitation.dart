import 'package:uuid/uuid.dart';

/// Model for project invitations
class ProjectInvitation {
  static final Uuid _uuid = Uuid();

  final String id;
  final String email;
  final String projectId;
  final String role;
  final String invitedBy;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? token; // Token for accepting invitation
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProjectInvitation({
    required this.id,
    required this.email,
    required this.projectId,
    required this.role,
    required this.invitedBy,
    required this.status,
    this.token,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory for creating with generated ID
  factory ProjectInvitation.create({
    required String email,
    required String projectId,
    required String role,
    required String invitedBy,
    String status = 'pending',
    String? token,
  }) {
    final id = _uuid.v4();
    return ProjectInvitation(
      id: id,
      email: email,
      projectId: projectId,
      role: role,
      invitedBy: invitedBy,
      status: status,
      token: token,
      createdAt: DateTime.now(),
    );
  }

  /// Factory constructor for creating from JSON
  factory ProjectInvitation.fromJson(Map<String, dynamic> json) {
    return ProjectInvitation(
      id: json['id'] as String,
      email: json['email'] as String,
      projectId: json['project_id'] as String,
      role: json['role'] as String,
      invitedBy: json['invited_by'] as String,
      status: json['status'] as String,
      token: json['token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'project_id': projectId,
      'role': role,
      'invited_by': invitedBy,
      'status': status,
      'token': token,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with updated fields
  ProjectInvitation copyWith({
    String? id,
    String? email,
    String? projectId,
    String? role,
    String? invitedBy,
    String? status,
    String? token,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectInvitation(
      id: id ?? this.id,
      email: email ?? this.email,
      projectId: projectId ?? this.projectId,
      role: role ?? this.role,
      invitedBy: invitedBy ?? this.invitedBy,
      status: status ?? this.status,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}