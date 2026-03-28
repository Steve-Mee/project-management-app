import 'package:pma_core/models/generated_asset.dart';

import '../data/repositories/three_d_visualization_repository.dart';

class GetGeneratedAssetsUseCase {
  const GetGeneratedAssetsUseCase(this._repository);

  final ThreeDVisualizationRepository _repository;

  Future<List<GeneratedAsset>> call({
    String? projectId,
    int limit = 100,
  }) {
    if (projectId != null && projectId.isNotEmpty) {
      return _repository.getGeneratedAssetsForProject(projectId, limit: limit);
    }
    return _repository.getAllGeneratedAssets(limit: limit);
  }
}
