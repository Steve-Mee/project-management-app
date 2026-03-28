import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/core/providers.dart' as core_providers;
import 'package:pma_core/models/generated_asset.dart';
import 'package:pma_core/providers/payment/payment_providers.dart';
import 'package:pma_core/services/app_logger.dart';

import '../../providers/three_d_visualization_providers.dart';

class ThreeDVisualizeAssistant extends ConsumerStatefulWidget {
  const ThreeDVisualizeAssistant({
    super.key,
    required this.projectId,
    this.taskId,
    this.taskDescription,
    this.attachments = const <String>[],
    this.compact = false,
  });

  final String projectId;
  final String? taskId;
  final String? taskDescription;
  final List<String> attachments;
  final bool compact;

  @override
  ConsumerState<ThreeDVisualizeAssistant> createState() =>
      _ThreeDVisualizeAssistantState();
}

class _ThreeDVisualizeAssistantState
    extends ConsumerState<ThreeDVisualizeAssistant> {
  static const Map<String, String> _industryExamples =
      <String, String>{
    'Architecture':
        'Generate a modern mixed-use tower with podium retail and rooftop garden.',
    'Manufacturing':
        'Create a compact robotic arm assembly fixture with safety casing.',
    'Healthcare':
        'Design an ergonomic medication cart with lockable compartments.',
    'Retail':
        'Model a modular point-of-sale kiosk with product shelving.',
    'Education':
        'Build a flexible classroom desk system with cable management.',
    'Gaming':
        'Create a stylized sci-fi cargo drone with clean hard-surface panels.',
  };

  final TextEditingController _promptController = TextEditingController();
  final Map<String, GeneratedAssetStatus> _assetStatusesById =
      <String, GeneratedAssetStatus>{};
  bool _initialAssetSnapshotLoaded = false;

  String _selectedResolution = '1024';
  String _selectedFormat = 'glb';
  String _selectedEngine = 'blender';

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  String _composeContextAwarePrompt(String userPrompt) {
    final description = widget.taskDescription?.trim();
    final contextLines = <String>[
      userPrompt,
      if (description != null && description.isNotEmpty)
        'Task context: $description',
      if (widget.attachments.isNotEmpty)
        'Attachments: ${widget.attachments.join(', ')}',
    ];

    return contextLines.join('\n');
  }

  Future<void> _submitPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    final request = ThreeDGenerationRequest(
      projectId: widget.projectId,
      taskId: widget.taskId,
      prompt: _composeContextAwarePrompt(prompt),
      settings: ThreeDGenerationSettings(
        resolution: _selectedResolution,
        format: _selectedFormat,
        engine: _selectedEngine,
      ),
      metadata: <String, dynamic>{
        'original_prompt': prompt,
        if (widget.taskDescription != null && widget.taskDescription!.trim().isNotEmpty)
          'task_description': widget.taskDescription!.trim(),
        if (widget.attachments.isNotEmpty) 'attachments': widget.attachments,
      },
    );

    try {
      await ref.read(threeDGenerationProvider.notifier).generate(request);
      if (mounted) {
        _promptController.clear();
      }
    } catch (_) {
      // Error UI comes from provider state card below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _ThreeDAssistantStrings.of(context);
    final spacing = widget.compact ? 8.0 : 10.0;
    final generationState = ref.watch(threeDGenerationProvider);
    final assetsQuery = GeneratedAssetsQuery(
      projectId: widget.projectId,
      taskId: widget.taskId,
      limit: 20,
    );
    ref.listen<AsyncValue<List<GeneratedAsset>>>(
      generatedAssetsProvider(assetsQuery),
      (_, next) {
        next.whenData((assets) {
          if (!_initialAssetSnapshotLoaded) {
            for (final asset in assets) {
              _assetStatusesById[asset.id] = asset.status;
            }
            _initialAssetSnapshotLoaded = true;
            return;
          }

          for (final asset in assets) {
            final previousStatus = _assetStatusesById[asset.id];
            final transitionedToCompleted =
                previousStatus != GeneratedAssetStatus.completed &&
                    asset.status == GeneratedAssetStatus.completed;

            if (transitionedToCompleted) {
              _logRenderCompletedEvent(asset);
            }

            _assetStatusesById[asset.id] = asset.status;
          }
        });
      },
    );
    final assetsAsync = ref.watch(generatedAssetsProvider(assetsQuery));
    final renderCreditsAsync = ref.watch(renderCreditsProvider);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.view_in_ar_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.assistantTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _buildRenderCreditsChip(context, renderCreditsAsync, strings),
                      _buildRealtimeStatusChip(context, assetsAsync, strings),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: <Widget>[
                  const Icon(Icons.view_in_ar_outlined),
                  const SizedBox(width: 8),
                  Text(
                    strings.assistantTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _buildRenderCreditsChip(context, renderCreditsAsync, strings),
                  const SizedBox(width: 8),
                  _buildRealtimeStatusChip(context, assetsAsync, strings),
                ],
              ),
            SizedBox(height: spacing),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _industryExamples.entries.map((entry) {
                return ActionChip(
                  label: Text(entry.key),
                  onPressed: () {
                    _promptController.text = entry.value;
                  },
                );
              }).toList(growable: false),
            ),
            SizedBox(height: spacing),
            TextField(
              controller: _promptController,
              minLines: widget.compact ? 2 : 3,
              maxLines: widget.compact ? 4 : 6,
              decoration: InputDecoration(
                labelText: strings.describeAssetLabel,
                hintText: strings.describeAssetHint,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: spacing),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildSettingDropdown(
                  context,
                  label: strings.resolutionLabel,
                  value: _selectedResolution,
                  items: const <String>['512', '1024', '2048', '4k'],
                  onChanged: (String value) {
                    setState(() {
                      _selectedResolution = value;
                    });
                  },
                ),
                _buildSettingDropdown(
                  context,
                  label: strings.formatLabel,
                  value: _selectedFormat,
                  items: const <String>['glb', 'fbx', 'png', 'usdz'],
                  onChanged: (String value) {
                    setState(() {
                      _selectedFormat = value;
                    });
                  },
                ),
                _buildSettingDropdown(
                  context,
                  label: strings.engineLabel,
                  value: _selectedEngine,
                  items: const <String>['blender', 'tripo', 'hunyuan3d'],
                  onChanged: (String value) {
                    setState(() {
                      _selectedEngine = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: generationState.isLoading ? null : _submitPrompt,
                    icon: generationState.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(strings.generateButtonLabel),
                  ),
                ),
              ],
            ),
            if (generationState.hasError)
              Padding(
                padding: EdgeInsets.only(top: spacing),
                child: Text(
                  strings.generationFailed(generationState.error),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SizedBox(height: spacing),
            _buildContextCard(context, strings),
            SizedBox(height: spacing),
            Expanded(
              child: assetsAsync.when(
                data: (assets) {
                  if (assets.isEmpty) {
                    return Center(
                      child: Text(strings.noGeneratedAssetsYet),
                    );
                  }

                  return ListView.separated(
                    itemCount: assets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return ListTile(
                        dense: widget.compact,
                        leading: Icon(
                          asset.status == GeneratedAssetStatus.completed
                              ? Icons.check_circle_outline
                              : asset.status == GeneratedAssetStatus.failed
                                  ? Icons.error_outline
                                  : Icons.timelapse,
                        ),
                        title: Text(
                          asset.prompt.isEmpty ? asset.id : asset.prompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${asset.format.name.toUpperCase()} • ${asset.status.name}',
                        ),
                        trailing: asset.format == GeneratedAssetFormat.glb
                            ? IconButton(
                                tooltip: strings.previewGlbTooltip,
                                icon: const Icon(Icons.remove_red_eye_outlined),
                                onPressed: () async {
                                  final preview = await ref.read(
                                    threeDPreviewProvider(asset).future,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text(strings.previewUrl(preview))),
                                  );
                                },
                              )
                            : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(strings.failedToLoadAssets(error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logRenderCompletedEvent(GeneratedAsset asset) {
    final resolution = _resolveResolution(asset);
    final duration = _resolveDurationSeconds(asset);

    ref
        .read(core_providers.analyticsServiceProvider)
        .logEvent(
          '3d_render_completed',
          parameters: <String, dynamic>{
            'format': asset.format.name,
            'resolution': resolution,
            'duration': duration,
          },
        )
        .catchError((Object error, StackTrace stackTrace) {
          AppLogger.instance.w(
            '3d_render_completed_analytics_failed',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  String _resolveResolution(GeneratedAsset asset) {
    final metadata = asset.metadata;
    final direct = metadata['resolution'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }

    final settings = metadata['settings'];
    if (settings is Map && settings['resolution'] != null) {
      final nested = settings['resolution'].toString().trim();
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    return 'unknown';
  }

  int _resolveDurationSeconds(GeneratedAsset asset) {
    final metadata = asset.metadata;

    final seconds = _coerceToInt(
      metadata['duration_seconds'] ??
          metadata['duration_sec'] ??
          metadata['duration'],
    );
    if (seconds != null && seconds >= 0) {
      return seconds;
    }

    final milliseconds = _coerceToInt(
      metadata['duration_ms'] ?? metadata['render_duration_ms'],
    );
    if (milliseconds != null && milliseconds >= 0) {
      return (milliseconds / 1000).round();
    }

    final end = asset.updatedAt ?? DateTime.now();
    final derived = end.difference(asset.createdAt).inSeconds;
    if (derived < 0) {
      return 0;
    }
    return derived;
  }

  int? _coerceToInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  Widget _buildRenderCreditsChip(
    BuildContext context,
    AsyncValue<int> creditsAsync,
    _ThreeDAssistantStrings strings,
  ) {
    final creditsLabel = creditsAsync.when(
      data: strings.creditsLabel,
      loading: () => strings.creditsLoading,
      error: (_, __) => strings.creditsUnavailable,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        creditsLabel,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  Widget _buildContextCard(
    BuildContext context,
    _ThreeDAssistantStrings strings,
  ) {
    final hasDescription =
        widget.taskDescription != null && widget.taskDescription!.trim().isNotEmpty;
    final hasAttachments = widget.attachments.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.contextAwareInput,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            hasDescription
                ? strings.taskDescriptionIncluded
                : strings.noTaskDescription,
          ),
          Text(
            hasAttachments
                ? strings.attachmentsIncluded(widget.attachments.length)
                : strings.noAttachments,
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeStatusChip(
    BuildContext context,
    AsyncValue<List<GeneratedAsset>> assetsAsync,
    _ThreeDAssistantStrings strings,
  ) {
    final latest = assetsAsync.valueOrNull?.isNotEmpty == true
        ? assetsAsync.valueOrNull!.first
        : null;

    String label = strings.statusIdle;
    Color color = Theme.of(context).colorScheme.outline;

    if (latest != null) {
      switch (latest.status) {
        case GeneratedAssetStatus.pending:
          label = strings.statusPreviewQueued;
          color = Colors.orange;
          break;
        case GeneratedAssetStatus.processing:
          label = strings.statusRendering;
          color = Colors.blue;
          break;
        case GeneratedAssetStatus.completed:
          label = strings.statusCompleted;
          color = Colors.green;
          break;
        case GeneratedAssetStatus.failed:
          label = strings.statusFailed;
          color = Colors.red;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Widget _buildSettingDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButton<String>(
            value: value,
            borderRadius: BorderRadius.circular(8),
            icon: const Icon(Icons.expand_more),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text('$label: $item'),
                  ),
                )
                .toList(growable: false),
            onChanged: (selected) {
              if (selected != null) {
                onChanged(selected);
              }
            },
          ),
        ),
      ),
    );
  }
}

  class _ThreeDAssistantStrings {
    _ThreeDAssistantStrings(this.localeCode);

    factory _ThreeDAssistantStrings.of(BuildContext context) {
    return _ThreeDAssistantStrings(Localizations.localeOf(context).languageCode);
    }

    final String localeCode;

    bool get _isDutch => localeCode.toLowerCase().startsWith('nl');

    String get assistantTitle => _isDutch ? '3D Visualisatie Assistent' : '3D Visualize Assistant';
    String get describeAssetLabel => _isDutch ? 'Beschrijf het 3D-item' : 'Describe the 3D asset';
    String get describeAssetHint => _isDutch
      ? 'Voorbeeld: modulair kantoor met glazen wanden en een dakraam'
      : 'Example: modular office layout with glass walls and skylight';
    String get resolutionLabel => _isDutch ? 'Resolutie' : 'Resolution';
    String get formatLabel => _isDutch ? 'Formaat' : 'Format';
    String get engineLabel => _isDutch ? 'Engine' : 'Engine';
    String get generateButtonLabel => _isDutch ? 'Genereer 3D' : 'Generate 3D';
    String generationFailed(Object? error) => _isDutch
      ? 'Generatie mislukt: $error'
      : 'Generation failed: $error';
    String get noGeneratedAssetsYet =>
      _isDutch ? 'Nog geen gegenereerde assets.' : 'No generated assets yet.';
    String failedToLoadAssets(Object error) => _isDutch
      ? 'Assets laden mislukt: $error'
      : 'Failed to load assets: $error';
    String get previewGlbTooltip => _isDutch ? 'Bekijk GLB' : 'Preview GLB';
    String previewUrl(Uri url) =>
      _isDutch ? 'Preview-URL: $url' : 'Preview URL: $url';
    String creditsLabel(int credits) =>
      _isDutch ? '$credits credits' : '$credits credits';
    String get creditsLoading => _isDutch ? '... credits' : '... credits';
    String get creditsUnavailable => _isDutch ? '-- credits' : '-- credits';
    String get contextAwareInput => _isDutch ? 'Contextbewuste invoer' : 'Context-aware input';
    String get taskDescriptionIncluded => _isDutch
      ? 'Taakomschrijving wordt automatisch meegenomen.'
      : 'Task description will be included automatically.';
    String get noTaskDescription => _isDutch
      ? 'Geen taakomschrijving gevonden.'
      : 'No current task description found.';
    String attachmentsIncluded(int count) => _isDutch
      ? '$count bijlage(n) worden als context meegestuurd.'
      : '$count attachment(s) will be attached as context.';
    String get noAttachments =>
      _isDutch ? 'Geen taakbijlagen gevonden.' : 'No task attachments detected.';
    String get statusIdle => _isDutch ? 'Inactief' : 'Idle';
    String get statusPreviewQueued => _isDutch ? 'Preview in wachtrij' : 'Preview queued';
    String get statusRendering => _isDutch ? 'Preview -> Volledige render' : 'Preview -> Full render';
    String get statusCompleted => _isDutch ? 'Render voltooid' : 'Full render complete';
    String get statusFailed => _isDutch ? 'Render mislukt' : 'Render failed';
  }
