import 'package:pma_core/core/services/analytics_events.dart';
import 'package:pma_core/core/services/analytics_service.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/repository/impl/hive_project_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stub for future cloud sync (Supabase/etc.).
class CloudSyncService {
  final SupabaseClient supabaseClient;
  final HiveProjectRepository? repository;
  AnalyticsService? _analyticsService;

  CloudSyncService({
    required this.supabaseClient,
    this.repository,
    AnalyticsService? analyticsService,
  }) : _analyticsService = analyticsService;

  AnalyticsService get _analytics =>
      _analyticsService ??= SupabaseAnalyticsService(supabaseClient);

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String value) {
    return _uuidRegex.hasMatch(value);
  }

  Future<void> _insertAnalytics(
    String event, {
    String? entityId,
    String? projectId,
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    if (projectId != null && projectId.isNotEmpty && !_isValidUuid(projectId)) {
      AppLogger.instance.w('Invalid project_id $projectId for event $event');
      return;
    }

    await _analytics.logEvent(
      event,
      parameters: {
        if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
        if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
        if (userId != null && userId.isNotEmpty) 'actor_user_id': userId,
        if (metadata != null && metadata.isNotEmpty) ...metadata,
      },
    );

    AppLogger.event(event, params: {
      if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
      if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
      if (userId != null && userId.isNotEmpty) 'actor_user_id': userId,
    });
  }

  Future<void> syncProjectCreate(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // Insert project into Supabase (assuming projects table exists)
    // Note: In a real implementation, you'd sync the full project data
    // For now, just ensure membership is created
    try {
      await supabaseClient.from('projects').insert({
        'id': projectId,
        'name': metadata?['name'] ??
            'New Project', // Assuming name is passed in metadata
        'user_id': currentUser.id, // Zorg voor auth.uid()
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // Add other fields as needed
      });
      AppLogger.instance.i('Project $projectId inserted into Supabase');
    } catch (e) {
      AppLogger.instance
          .w('Project insert failed, might already exist', error: e);
      // Continue anyway - membership is more important
    }

    // Insert membership with owner role
    try {
      await supabaseClient.from('project_members').insert({
        'project_id': projectId,
        'user_id': currentUser.id, // Zorg voor auth.uid()
        'role': 'owner',
      });
      AppLogger.instance.i(
          'Membership created for user ${currentUser.id} in project $projectId');
    } catch (e) {
      AppLogger.instance
          .e('Membership insert failed for project $projectId', error: e);
      // This is critical - rethrow to fail the operation
      rethrow;
    }

    // Canonical `project_created` analytics is logged at repository create callsite
    // to prevent duplicate counting during sync operations.
  }

  Future<void> syncProjectUpdate(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // Upsert project data to Supabase
    try {
      final updateData = <String, Object?>{
        'id': projectId,
        'updated_at': DateTime.now().toIso8601String(),
        'user_id': currentUser.id,
      };

      if (metadata != null) {
        // Add metadata fields to update data
        updateData.addAll(metadata);
      }

      await supabaseClient.from('projects').upsert(updateData);
      AppLogger.instance.i('Project $projectId upserted to Supabase');
    } catch (e) {
      AppLogger.instance.w('Project upsert failed for $projectId', error: e);
    }

    await _insertAnalytics(
      AnalyticsEventName.projectUpdated,
      entityId: projectId,
      projectId: projectId,
      userId: currentUser.id,
      metadata: metadata,
    );
  }

  Future<void> syncProjectDelete(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // Delete project from Supabase
    try {
      await supabaseClient.from('projects').delete().eq('id', projectId);
      AppLogger.instance.i('Project $projectId deleted from Supabase');
    } catch (e) {
      AppLogger.instance.w('Project delete failed for $projectId', error: e);
    }

    await _insertAnalytics(
      AnalyticsEventName.projectDeleted,
      entityId: projectId,
      projectId: projectId,
      userId: currentUser.id,
      metadata: metadata,
    );
  }

  Future<void> syncProjectBulkDelete({String? userId}) async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // NOTE: Vervang door Supabase call later; controleer auth sessie.
    AppLogger.instance.i('Placeholder sync bulk delete');
    await _insertAnalytics(AnalyticsEventName.projectBulkDeleted,
        userId: currentUser.id);
  }

  Future<void> syncAll({String? userId}) async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    if (repository == null) {
      AppLogger.instance.w('Skipping project sync: no repository provided');
      return;
    }

    // Fetch all projects from Supabase for sync
    try {
      final response = await supabaseClient.from('projects').select();
      AppLogger.instance
          .i('Fetched ${response.length} projects from Supabase for sync');

      final localProjects = await repository!.getAllProjects();
      // final remoteProjects = response.map((json) => ProjectModel.fromJson(json)).toList();

      // Sync differences
      final localMap = {for (var p in localProjects) p.id: p};

      for (final remoteJson in response) {
        final remote = ProjectModel.fromJson(remoteJson);
        final remoteTime = DateTime.parse(remoteJson['updated_at'] as String);
        final local = localMap[remote.id];
        if (local == null || remoteTime.isAfter(local.lastUpdated)) {
          // Download remote
          await repository!.updateProject(remote.id, remote);
          AppLogger.instance.i('Downloaded project ${remote.id} from Supabase');
        } else if (local.lastUpdated.isAfter(remoteTime)) {
          // Upload local
          await syncProjectUpdate(local.id, metadata: local.toJson());
          AppLogger.instance.i('Uploaded project ${local.id} to Supabase');
        }
      }

      // Upload local projects not in remote
      for (final local in localProjects) {
        if (!response.any((r) => r['id'] == local.id)) {
          await syncProjectUpdate(local.id, metadata: local.toJson());
          AppLogger.instance.i('Uploaded new project ${local.id} to Supabase');
        }
      }
    } catch (e) {
      AppLogger.instance.w('Failed to sync projects', error: e);
    }

    await _insertAnalytics(AnalyticsEventName.syncAll, userId: currentUser.id);
  }

  // Fully implemented in 040-supabase-sync-cleanup.md

  /// Get real-time stream of projects changes
  Stream<List<Map<String, dynamic>>> getProjectsStream() {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Cannot stream projects: no authenticated user');
      return const Stream.empty();
    }

    return supabaseClient.from('projects').stream(primaryKey: ['id']);
  }

  Future<void> authSignIn(
    String userId, {
    Map<String, Object?>? metadata,
  }) async {
    AppLogger.instance.i('Auth sign-in sync event: $userId');
    await _insertAnalytics(
      AnalyticsEventName.authSignIn,
      userId: userId,
      metadata: metadata,
    );
  }

  Future<void> authSignOut({String? userId}) async {
    AppLogger.instance.i('Auth sign-out sync event');
    await _insertAnalytics(AnalyticsEventName.authSignOut, userId: userId);
  }
}
