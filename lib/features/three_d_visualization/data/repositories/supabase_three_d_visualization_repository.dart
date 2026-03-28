import 'package:pma_core/models/generated_asset.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'three_d_visualization_repository.dart';

class SupabaseThreeDVisualizationRepository
    implements ThreeDVisualizationRepository {
  SupabaseThreeDVisualizationRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  @override
  Future<void> upsertGeneratedAsset(GeneratedAsset asset) async {
    await _supabaseClient.from('generated_assets').upsert(asset.toJson());
  }

  @override
  Future<void> deleteGeneratedAsset(String assetId) async {
    await _supabaseClient.from('generated_assets').delete().eq('id', assetId);
  }

  @override
  Future<List<GeneratedAsset>> getGeneratedAssetsForProject(
    String projectId, {
    int limit = 100,
  }) async {
    final rows = await _supabaseClient
        .from('generated_assets')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .limit(limit);

    return _mapRows(rows);
  }

  @override
  Future<List<GeneratedAsset>> getGeneratedAssetsForTask(
    String taskId, {
    int limit = 100,
  }) async {
    final rows = await _supabaseClient
        .from('generated_assets')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: false)
        .limit(limit);

    return _mapRows(rows);
  }

  @override
  Future<List<GeneratedAsset>> getAllGeneratedAssets({
    int limit = 100,
  }) async {
    final rows = await _supabaseClient
        .from('generated_assets')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return _mapRows(rows);
  }

  List<GeneratedAsset> _mapRows(dynamic rows) {
    if (rows is! List) {
      return const <GeneratedAsset>[];
    }

    return rows
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .map(GeneratedAsset.fromJson)
        .toList(growable: false);
  }
}
