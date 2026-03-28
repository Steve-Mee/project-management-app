import 'package:pma_core/models/generated_asset.dart';

abstract class ThreeDVisualizationRepository {
  Future<void> upsertGeneratedAsset(GeneratedAsset asset);

  Future<void> deleteGeneratedAsset(String assetId);

  Future<List<GeneratedAsset>> getGeneratedAssetsForProject(
    String projectId, {
    int limit = 100,
  });

  Future<List<GeneratedAsset>> getGeneratedAssetsForTask(
    String taskId, {
    int limit = 100,
  });

  Future<List<GeneratedAsset>> getAllGeneratedAssets({
    int limit = 100,
  });
}
