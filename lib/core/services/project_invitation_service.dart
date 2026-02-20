import 'package:my_project_management_app/models/project_invitation.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for managing project invitations
class ProjectInvitationService {
  final SupabaseClient _supabaseClient;
  static final Uuid _uuid = Uuid();

  ProjectInvitationService(this._supabaseClient);

  /// Send an invitation to a user for a project
  Future<String> sendInvitation(
    String projectId,
    String email,
    String role,
  ) async {
    // Validate role
    if (!['owner', 'admin', 'member', 'viewer'].contains(role)) {
      throw Exception('Invalid role: $role');
    }

    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await _supabaseClient
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to invite users');
    }

    // Check if invitation already exists and is pending
    final existingInvitation = await _supabaseClient
        .from('invitations')
        .select('id')
        .eq('project_id', projectId)
        .eq('email', email)
        .eq('status', 'pending');

    if (existingInvitation.isNotEmpty) {
      throw Exception('Invitation already sent to this email');
    }

    // Generate unique token
    final token = _uuid.v4();

    // Create invitation record
    final invitation = ProjectInvitation.create(
      email: email,
      projectId: projectId,
      role: role,
      invitedBy: currentUser.id,
      token: token,
    );

    await _supabaseClient.from('invitations').insert(invitation.toJson()).select('minimal');

    AppLogger.instance.i('Sent invitation to $email for project $projectId with role $role');

    return token;
  }

  /// Accept an invitation using the token
  Future<void> acceptInvitation(String token) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Get invitation by token
    final invitation = await _supabaseClient
        .from('invitations')
        .select('*')
        .eq('token', token)
        .eq('status', 'pending')
        .single();

    // Check if invitation is not expired (e.g., 7 days)
    final createdAt = DateTime.parse(invitation['created_at']);
    final expiryDate = createdAt.add(const Duration(days: 7));
    if (DateTime.now().isAfter(expiryDate)) {
      throw Exception('Invitation has expired');
    }

    // Check if user email matches invitation email
    if (currentUser.email != invitation['email']) {
      throw Exception('Invitation is for a different email address');
    }

    // Check if user is already a member
    final existingMembers = await _supabaseClient
        .from('project_members')
        .select('user_id')
        .eq('project_id', invitation['project_id'])
        .eq('user_id', currentUser.id);

    if (existingMembers.isNotEmpty) {
      throw Exception('User is already a member of this project');
    }

    // Add to project_members
    await _supabaseClient
        .from('project_members')
        .insert({
          'project_id': invitation['project_id'],
          'user_id': currentUser.id,  // Zorg voor auth.uid()
          'role': invitation['role'],
        }).select('minimal');

    // Update invitation status
    await _supabaseClient
        .from('invitations')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', invitation['id']);

    AppLogger.instance.i('Accepted invitation ${invitation['id']} for project ${invitation['project_id']}');
  }

  /// Update a member's role in a project
  Future<void> updateMemberRole(String projectId, String userId, String newRole) async {
    if (!['owner', 'admin', 'member', 'viewer'].contains(newRole)) {
      throw Exception('Invalid role: $newRole');
    }

    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await _supabaseClient
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to change member roles');
    }

    // Prevent demoting the last owner
    if (newRole != 'owner') {
      final owners = await _supabaseClient
          .from('project_members')
          .select('user_id')
          .eq('project_id', projectId)
          .eq('role', 'owner');

      if (owners.length == 1 && owners[0]['user_id'] == userId) {
        throw Exception('Cannot remove the last owner from the project');
      }
    }

    // Update role
    await _supabaseClient
        .from('project_members')
        .update({'role': newRole})
        .eq('project_id', projectId)
        .eq('user_id', userId);
  }

  /// Remove a member from a project
  Future<void> removeMember(String projectId, String userId) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await _supabaseClient
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to remove members');
    }

    // Prevent removing the last owner
    final targetMembership = await _supabaseClient
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .single();

    if (targetMembership['role'] == 'owner') {
      final owners = await _supabaseClient
          .from('project_members')
          .select('user_id')
          .eq('project_id', projectId)
          .eq('role', 'owner');

      if (owners.length == 1) {
        throw Exception('Cannot remove the last owner from the project');
      }
    }

    // Remove member
    await _supabaseClient
        .from('project_members')
        .delete()
        .eq('project_id', projectId)
        .eq('user_id', userId);
  }

  /// Get all members of a project with their metadata
  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if user is member of the project
    try {
      await _supabaseClient
          .from('project_members')
          .select('role')
          .eq('project_id', projectId)
          .eq('user_id', currentUser.id)
          .single();
      // If we get here, user is a member
    } catch (e) {
      throw Exception('Access denied');
    }

    // Get all members
    final members = await _supabaseClient
        .from('project_members')
        .select('user_id, role')
        .eq('project_id', projectId);

    // Get user metadata (in a real app, you'd have a users table or use admin API)
    // For now, using placeholder data
    final membersWithInfo = <Map<String, dynamic>>[];
    for (final member in members) {
      // Placeholder - in production, fetch from users table or auth.users
      final userInfo = await _getUserInfo(member['user_id']);
      membersWithInfo.add({
        'user_id': member['user_id'],
        'email': userInfo['email'] ?? member['user_id'], // Fallback to user_id
        'name': userInfo['name'] ?? 'Unknown User',
        'role': member['role'],
      });
    }

    return membersWithInfo;
  }

  /// Helper to get user info (placeholder - implement based on your user table)
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    // In a real implementation, you might have a users table:
    // const { data, error } = await _supabaseClient
    //     .from('users')
    //     .select('email, name')
    //     .eq('id', userId)
    //     .single();

    // For now, return placeholder
    return {
      'email': '$userId@example.com', // Placeholder
      'name': 'User $userId', // Placeholder
    };
  }
}