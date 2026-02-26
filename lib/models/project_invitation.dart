// ignore_for_file: prefer_const_constructors, invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'project_invitation.freezed.dart';
part 'project_invitation.g.dart';

/// Model for project invitations
@freezed
abstract class ProjectInvitation with _$ProjectInvitation {
  const ProjectInvitation._();

  static const Uuid _uuid = Uuid();

  const factory ProjectInvitation({
    required String id,
    required String email,
    @JsonKey(name: 'project_id') required String projectId,
    required String role,
    @JsonKey(name: 'invited_by') required String invitedBy,
    required String status,
    String? token,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProjectInvitation;

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

  factory ProjectInvitation.fromJson(Map<String, dynamic> json) =>
      _$ProjectInvitationFromJson(json);
}
