import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/models/generated_asset.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../data/repositories/supabase_three_d_visualization_repository.dart';
import '../data/repositories/three_d_visualization_repository.dart';

class GeneratedAssetsQuery {
  const GeneratedAssetsQuery({
    this.projectId,
    this.taskId,
    this.limit = 100,
  });

  final String? projectId;
  final String? taskId;
  final int limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GeneratedAssetsQuery &&
        other.projectId == projectId &&
        other.taskId == taskId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(projectId, taskId, limit);
}

class ThreeDGenerationRequest {
  const ThreeDGenerationRequest({
    required this.projectId,
    this.taskId,
    required this.prompt,
    this.settings = const ThreeDGenerationSettings(),
    this.metadata = const <String, dynamic>{},
  });

  final String projectId;
  final String? taskId;
  final String prompt;
  final ThreeDGenerationSettings settings;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projectId': projectId,
      if (taskId != null && taskId!.isNotEmpty) 'taskId': taskId,
      'prompt': prompt,
      'settings': settings.toJson(),
      'metadata': metadata,
    };
  }
}

class ThreeDGenerationSettings {
  const ThreeDGenerationSettings({
    this.resolution = '1024',
    this.format = 'glb',
    this.engine = 'blender',
  });

  final String resolution;
  final String format;
  final String engine;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'resolution': resolution,
      'format': format,
      'engine': engine,
    };
  }
}

class ThreeDGenerationJob {
  const ThreeDGenerationJob({
    required this.jobId,
    required this.status,
    required this.projectId,
    this.taskId,
  });

  final String jobId;
  final String status;
  final String projectId;
  final String? taskId;

  factory ThreeDGenerationJob.fromJson(Map<String, dynamic> json) {
    return ThreeDGenerationJob(
      jobId: json['jobId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'queued',
      projectId: json['projectId']?.toString() ?? '',
      taskId: json['taskId']?.toString(),
    );
  }
}

final threeDVisualizationSupabaseClientProvider =
    Provider<SupabaseClient>((ref) {
  return ref.read(supabaseClientProvider);
});

final threeDVisualizationRepositoryProvider =
    Provider<ThreeDVisualizationRepository>((ref) {
  return SupabaseThreeDVisualizationRepository(
    supabaseClient: ref.read(threeDVisualizationSupabaseClientProvider),
  );
});

class ThreeDGenerationNotifier extends AsyncNotifier<ThreeDGenerationJob?> {
  @override
  Future<ThreeDGenerationJob?> build() async {
    return null;
  }

  Future<ThreeDGenerationJob?> generate(ThreeDGenerationRequest request) async {
    state = const AsyncValue.loading();

    try {
      final client = ref.read(threeDVisualizationSupabaseClientProvider);
      final response = await client.functions.invoke(
        'generate-3d-asset',
        body: request.toJson(),
      );

      final responseData = response.data;
      if (responseData is! Map) {
        throw StateError('Invalid generate-3d-asset response payload');
      }

      final json = responseData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final job = ThreeDGenerationJob.fromJson(json);

      state = AsyncValue.data(job);
      return job;
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'three_d_generation_failed',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final threeDGenerationProvider =
    AsyncNotifierProvider<ThreeDGenerationNotifier, ThreeDGenerationJob?>(
  ThreeDGenerationNotifier.new,
);

final generatedAssetsRealtimeSubscriptionProvider =
    Provider.autoDispose.family<void, GeneratedAssetsQuery>((ref, query) {
  final client = ref.read(threeDVisualizationSupabaseClientProvider);
  final channelName =
      'generated-assets-${query.projectId ?? 'all'}-${query.taskId ?? 'all'}';
  final channel = client.channel(channelName);

  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'generated_assets',
        callback: (PostgresChangePayload _) {},
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
});

final generatedAssetsProvider =
    StreamProvider.autoDispose.family<List<GeneratedAsset>, GeneratedAssetsQuery>((
  ref,
  query,
) {
  ref.watch(generatedAssetsRealtimeSubscriptionProvider(query));

  final client = ref.read(threeDVisualizationSupabaseClientProvider);
  final baseStream = client
      .from('generated_assets')
      .stream(primaryKey: const ['id']);

  final hasProject = query.projectId != null && query.projectId!.isNotEmpty;
  final hasTask = query.taskId != null && query.taskId!.isNotEmpty;

    // Supabase stream filter builder supports a single equality filter here.
    // Prefer task filter when both are present because it is more selective.
    final Stream<List<Map<String, dynamic>>> stream = hasTask
      ? baseStream.eq('task_id', query.taskId!)
      : hasProject
        ? baseStream.eq('project_id', query.projectId!)
        : baseStream;

  return stream.map((rows) {
    try {
      final mapped = rows
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
          .map(GeneratedAsset.fromJson)
          .where((asset) {
          final matchesProject =
            query.projectId == null || query.projectId!.isEmpty
              ? true
              : asset.projectId == query.projectId;
          final matchesTask = query.taskId == null || query.taskId!.isEmpty
            ? true
            : asset.taskId == query.taskId;
          return matchesProject && matchesTask;
          })
          .toList(growable: false);

      mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mapped.length <= query.limit) {
        return mapped;
      }
      return mapped.take(query.limit).toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'generated_assets_stream_mapping_failed',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  });
});

final threeDPreviewProvider =
    FutureProvider.family<Uri, GeneratedAsset>((ref, asset) async {
  try {
    if (asset.format != GeneratedAssetFormat.glb) {
      throw StateError(
        'Preview currently supports only GLB assets. Received: ${asset.format.name}',
      );
    }

    final uri = Uri.tryParse(asset.fileUrl);
    if (uri == null || (!uri.hasScheme && !uri.hasAuthority)) {
      throw FormatException('Invalid GLB file URL', asset.fileUrl);
    }

    return uri;
  } catch (error, stackTrace) {
    AppLogger.instance.e(
      'three_d_preview_failed',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});
