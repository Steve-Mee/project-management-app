import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_project_management_app/core/services/project_members_service.dart';
import 'package:my_project_management_app/core/services/project_invitation_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';

class ProjectMembersScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectMembersScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends ConsumerState<ProjectMembersScreen> {
  final _membersService = ProjectMembersService();
  final _invitationService = ProjectInvitationService(Supabase.instance.client);

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _currentUserRole;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });

      // Get current user's role
      try {
        final membership = await Supabase.instance.client
            .from('project_members')
            .select('role')
            .eq('project_id', widget.projectId)
            .eq('user_id', user.id)
            .single();

        if (membership['error'] == null) {
          setState(() {
            _currentUserRole = membership['data']['role'];
          });
        }
      } catch (e) {
        AppLogger.instance.e('Failed to load user role', error: e);
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = await _membersService.getProjectMembers(widget.projectId);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden leden: $e')),
        );
      }
    }
  }

  bool get _canManageMembers {
    return _currentUserRole == 'owner' || _currentUserRole == 'admin';
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    String selectedRole = 'member';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gebruiker uitnodigen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email adres',
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                DropdownMenuItem(value: 'member', child: Text('Member')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedRole = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Uitnodigen'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty) {
      try {
        await _invitationService.sendInvitation(
          widget.projectId,
          emailController.text.trim(),
          selectedRole,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uitnodiging verzonden!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij uitnodigen: $e')),
          );
        }
      }
    }
  }

  Future<void> _changeMemberRole(String userId, String newRole) async {
    try {
      await _membersService.changeRole(
        projectId: widget.projectId,
        targetUserId: userId,
        newRole: newRole,
      );

      // Update local state
      setState(() {
        final index = _members.indexWhere((m) => m['user_id'] == userId);
        if (index != -1) {
          _members[index]['role'] = newRole;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol bijgewerkt!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij wijzigen rol: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lid verwijderen'),
        content: Text('Weet je zeker dat je $email wilt verwijderen uit dit project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _membersService.removeMember(
        projectId: widget.projectId,
        targetUserId: userId,
      );

      // Update local state
      setState(() {
        _members.removeWhere((m) => m['user_id'] == userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lid verwijderd!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij verwijderen lid: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Leden'),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('Geen leden gevonden'))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isCurrentUser = member['user_id'] == _currentUserId;
                    final canEdit = _canManageMembers && !isCurrentUser; // Can't edit own role
                    final canDelete = _canManageMembers && !isCurrentUser; // Can't delete self

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(member['email'][0].toUpperCase()),
                      ),
                      title: Text(member['email']),
                      subtitle: Text('Rol: ${member['role']}'),
                      trailing: _canManageMembers
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Role dropdown
                                DropdownButton<String>(
                                  value: member['role'],
                                  items: const [
                                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                                    DropdownMenuItem(value: 'member', child: Text('Member')),
                                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                  ],
                                  onChanged: canEdit
                                      ? (newRole) {
                                          if (newRole != null) {
                                            _changeMemberRole(member['user_id'], newRole);
                                          }
                                        }
                                      : null,
                                ),
                                // Delete button
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeMember(member['user_id'], member['email']),
                                  ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
      floatingActionButton: _canManageMembers
          ? FloatingActionButton(
              onPressed: _showInviteDialog,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}