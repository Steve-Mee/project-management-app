import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/models/generated_asset.dart';

import '../../../core/config/feature_flags.dart';
import '../providers/three_d_visualization_providers.dart';
import 'widgets/three_d_preview_widget.dart';

class ThreeDVisualizationScreen extends ConsumerWidget {
  const ThreeDVisualizationScreen({
    super.key,
    this.projectId,
  });

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = _ThreeDScreenStrings.of(context);
    final flagsAsync = ref.watch(featureFlagProvider);
    final isEnabled = flagsAsync.maybeWhen(
      data: (flags) => FeatureFlagResolver.isEnabled(
        flags,
        AppFeatureFlags.threeDVisualizationEnabled,
        defaultValue: true,
      ),
      orElse: () => true,
    );

    if (!isEnabled) {
      return Scaffold(
        body: Center(
          child: Text(strings.disabledByAdmin),
        ),
      );
    }

    final assetsAsync = ref.watch(
      generatedAssetsProvider(
        GeneratedAssetsQuery(projectId: projectId),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.screenTitle)),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return Center(
              child: Text(strings.noAssets),
            );
          }

          return ListView.separated(
            itemCount: assets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.view_in_ar_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              asset.prompt.isEmpty ? asset.id : asset.prompt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(asset.status.name),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        asset.format.name.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (asset.format == GeneratedAssetFormat.glb &&
                          asset.fileUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ThreeDPreviewWidget(
                          glbUrl: asset.fileUrl,
                          height: 220,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(strings.failedToLoad(error))),
      ),
    );
  }
}

class _ThreeDScreenStrings {
  _ThreeDScreenStrings(this.localeCode);

  factory _ThreeDScreenStrings.of(BuildContext context) {
    return _ThreeDScreenStrings(Localizations.localeOf(context).languageCode);
  }

  final String localeCode;

  bool get _isDutch => localeCode.toLowerCase().startsWith('nl');

  String get screenTitle => _isDutch ? '3D Visualisatie' : '3D Visualization';
  String get disabledByAdmin => _isDutch
      ? '3D-visualisatie is momenteel uitgeschakeld door de beheerder.'
      : '3D visualization is currently disabled by admin.';
  String get noAssets => _isDutch
      ? 'Nog geen gegenereerde 3D-assets beschikbaar.'
      : 'No generated 3D assets available yet.';
  String failedToLoad(Object error) => _isDutch
      ? 'Assets laden mislukt: $error'
      : 'Failed to load assets: $error';
}
