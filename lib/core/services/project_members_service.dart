import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing project memberships and invitations
class ProjectMembersService {
  /// Invite a user to a project by email
  Future<void> inviteUser({
    required String email,
    required String projectId,
    required String role,
  }) async {
    if (!['owner', 'admin', 'member', 'viewer'].contains(role)) {
      throw Exception('Invalid role: $role');
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await Supabase.instance.client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to invite users');
    }

    // Check if invitation already exists
    final existingInvitation = await Supabase.instance.client
        .from('invitations')
        .select('id')
        .eq('project_id', projectId)
        .eq('email', email)
        .eq('status', 'pending');

    if (existingInvitation.isNotEmpty) {
      throw Exception('Invitation already sent to this email');
    }

    // Create invitation
    await Supabase.instance.client.from('invitations').insert({
      'email': email,
      'project_id': projectId,
      'role': role,
      'invited_by': currentUser.id,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }).select('minimal');

    AppLogger.instance.i('Invited $email to project $projectId with role $role');
  }

  /// Accept an invitation
  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Get invitation details
    final invitation = await Supabase.instance.client
        .from('invitations')
        .select('email, project_id, role')
        .eq('id', invitationId)
        .eq('status', 'pending')
        .single();

    if (invitation['email'] != currentUser.email) {
      throw Exception('Invitation is not for this user');
    }

    // Check if already a member
    final existingMember = await Supabase.instance.client
        .from('project_members')
        .select('user_id')
        .eq('project_id', invitation['project_id'])
        .eq('user_id', currentUser.id);

    if (existingMember.isNotEmpty) {
      throw Exception('User is already a member of this project');
    }

    // Add to project_members
    await Supabase.instance.client.from('project_members').insert({
      'project_id': invitation['project_id'],
      'user_id': currentUser.id,  // Zorg voor auth.uid()
      'role': invitation['role'],
    }).select('minimal');

    // Update invitation status
    await Supabase.instance.client
        .from('invitations')
        .update({'status': 'accepted'})
        .eq('id', invitationId);

    AppLogger.instance.i('Accepted invitation $invitationId for project ${invitation['project_id']}');
  }

  /// Change a member's role
  Future<void> changeRole({
    required String projectId,
    required String targetUserId,
    required String newRole,
  }) async {
    if (!['owner', 'admin', 'member', 'viewer'].contains(newRole)) {
      throw Exception('Invalid role: $newRole');
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await Supabase.instance.client
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
      final owners = await Supabase.instance.client
          .from('project_members')
          .select('user_id')
          .eq('project_id', projectId)
          .eq('role', 'owner');

      if (owners.length == 1 && owners[0]['user_id'] == targetUserId) {
        throw Exception('Cannot remove the last owner from the project');
      }
    }

    await Supabase.instance.client
        .from('project_members')
        .update({'role': newRole})
        .eq('project_id', projectId)
        .eq('user_id', targetUserId);

    AppLogger.instance.i('Changed role of $targetUserId in project $projectId to $newRole');
  }

  /// Remove a member from a project
  Future<void> removeMember({
    required String projectId,
    required String targetUserId,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await Supabase.instance.client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to remove members');
    }

    // Prevent removing the last owner
    final targetMembership = await Supabase.instance.client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', targetUserId)
        .single();

    if (targetMembership['role'] == 'owner') {
      final owners = await Supabase.instance.client
          .from('project_members')
          .select('user_id')
          .eq('project_id', projectId)
          .eq('role', 'owner');

      if (owners.length == 1) {
        throw Exception('Cannot remove the last owner from the project');
      }
    }

    await Supabase.instance.client
        .from('project_members')
        .delete()
        .eq('project_id', projectId)
        .eq('user_id', targetUserId);

    AppLogger.instance.i('Removed member $targetUserId from project $projectId');
  }

  /// Get all members of a project with their roles
  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if user is member of the project
    try {
      await Supabase.instance.client
          .from('project_members')
          .select('role')
          .eq('project_id', projectId)
          .eq('user_id', currentUser.id)
          .single();
    } catch (e) {
      throw Exception('Access denied');
    }

    // Get all members
    final members = await Supabase.instance.client
        .from('project_members')
        .select('user_id, role')
        .eq('project_id', projectId);

    // Get user emails (assuming we can access auth.users or have a users table)
    // For now, return with user_id - in real app, you'd join with users table
    final membersWithInfo = <Map<String, dynamic>>[];
    for (final member in members) {
      // Try to get user info from auth.users (admin required) or assume email is stored
      // For demo, just use user_id as email placeholder
      membersWithInfo.add({
        'user_id': member['user_id'],
        'email': member['user_id'], // Placeholder - replace with actual email lookup
        'role': member['role'],
      });
    }

    return membersWithInfo;
  }
}