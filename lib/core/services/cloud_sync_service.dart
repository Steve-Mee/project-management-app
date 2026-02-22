import 'dart:convert';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stub for future cloud sync (Supabase/Firestore/etc.).
class CloudSyncService {
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
    try {
      final supabase = Supabase.instance.client;

      // Optioneel: check auth status
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.instance.w('Skipping analytics: no authenticated user');
        return;
      }

      // JWT claim check (om te debuggen of hook werkt)
      final session = supabase.auth.currentSession;
      final token = session?.accessToken;
      if (token != null) {
        final payloadStr = token.split('.')[1];
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(payloadStr)));
        AppLogger.instance.d('JWT payload: $payload');  // Check op "app_role"
      }

      final payload = <String, Object?>{
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': currentUser.id,  // altijd user_id van authenticated user
      };

      if (entityId != null && entityId.isNotEmpty) {
        payload['entity_id'] = entityId;
      }

      if (projectId != null && projectId.isNotEmpty) {
        if (!_isValidUuid(projectId)) {
          AppLogger.instance.w('Invalid project_id $projectId for event $event');
          return;
        }
        payload['project_id'] = projectId;
      } // else: geen project_id → alleen als policy dat toelaat

      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }

      AppLogger.instance.d('Attempting analytics insert: $payload');

      await supabase.from('analytics').insert(payload);

      AppLogger.event(event, params: payload);
    } catch (e, stack) {
      AppLogger.instance.w('Analytics insert failed for $event', error: e, stackTrace: stack);
    }
  }

  Future<void> syncProjectCreate(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // Insert project into Supabase (assuming projects table exists)
    // Note: In a real implementation, you'd sync the full project data
    // For now, just ensure membership is created
    try {
      await Supabase.instance.client.from('projects').insert({
        'id': projectId,
        'name': metadata?['name'] ?? 'New Project', // Assuming name is passed in metadata
        'user_id': currentUser.id,  // Zorg voor auth.uid()
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // Add other fields as needed
      });
      AppLogger.instance.i('Project $projectId inserted into Supabase');
    } catch (e) {
      AppLogger.instance.w('Project insert failed, might already exist', error: e);
      // Continue anyway - membership is more important
    }

    // Insert membership with owner role
    try {
      await Supabase.instance.client.from('project_members').insert({
        'project_id': projectId,
        'user_id': currentUser.id,  // Zorg voor auth.uid()
        'role': 'owner',
      });
      AppLogger.instance.i('Membership created for user ${currentUser.id} in project $projectId');
    } catch (e) {
      AppLogger.instance.e('Membership insert failed for project $projectId', error: e);
      // This is critical - rethrow to fail the operation
      rethrow;
    }

    // Then analytics
    await _insertAnalytics(
      'project_created',
      entityId: projectId,
      projectId: projectId,
      userId: currentUser.id,
      metadata: metadata,
    );
  }

  Future<void> syncProjectUpdate(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // NOTE: Vervang door Supabase call later; controleer auth sessie.
    AppLogger.instance.i('Placeholder sync update: $projectId');
    await _insertAnalytics(
      'project_updated',
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
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // NOTE: Vervang door Supabase call later; controleer auth sessie.
    AppLogger.instance.i('Placeholder sync delete: $projectId');
    await _insertAnalytics(
      'project_deleted',
      entityId: projectId,
      projectId: projectId,
      userId: currentUser.id,
      metadata: metadata,
    );
  }

  Future<void> syncProjectBulkDelete({String? userId}) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // NOTE: Vervang door Supabase call later; controleer auth sessie.
    AppLogger.instance.i('Placeholder sync bulk delete');
    await _insertAnalytics('project_bulk_deleted', userId: currentUser.id);
  }

  Future<void> syncAll({String? userId}) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      AppLogger.instance.w('Skipping project sync: no authenticated user');
      return;
    }

    // NOTE: Vervang door Supabase call later; controleer auth sessie.
    AppLogger.instance.i('Placeholder sync full');
    await _insertAnalytics('sync_all', userId: currentUser.id);
  }

  Future<void> authSignInPlaceholder(
    String userId, {
    Map<String, Object?>? metadata,
  }) async {
    // NOTE: Vervang door Supabase auth sign-in; bewaar sessie.
    AppLogger.instance.i('Placeholder auth sign-in: $userId');
    await _insertAnalytics(
      'auth_sign_in',
      userId: userId,
      metadata: metadata,
    );
  }

  Future<void> authSignOutPlaceholder({String? userId}) async {
    // NOTE: Vervang door Supabase auth sign-out; clear sessie.
    AppLogger.instance.i('Placeholder auth sign-out');
    await _insertAnalytics('auth_sign_out', userId: userId);
  }
}
