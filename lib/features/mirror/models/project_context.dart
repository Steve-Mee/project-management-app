import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_context.freezed.dart';

enum ProjectContextTeamRole {
  architect('Architect'),
  coder('Coder'),
  reviewer('Reviewer');

  const ProjectContextTeamRole(this.label);

  final String label;

  static ProjectContextTeamRole? fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'architect':
        return ProjectContextTeamRole.architect;
      case 'coder':
        return ProjectContextTeamRole.coder;
      case 'reviewer':
        return ProjectContextTeamRole.reviewer;
      default:
        return null;
    }
  }
}

enum ProjectContextPreviewReuseStrategy {
  @JsonValue('none')
  none('none'),
  @JsonValue('server_version_token')
  serverVersionToken('server_version_token');

  const ProjectContextPreviewReuseStrategy(this.value);

  final String value;

  static ProjectContextPreviewReuseStrategy fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'server_version_token':
      case 'serverversiontoken':
        return ProjectContextPreviewReuseStrategy.serverVersionToken;
      case 'none':
      case null:
      case '':
        return ProjectContextPreviewReuseStrategy.none;
      default:
        return ProjectContextPreviewReuseStrategy.none;
    }
  }
}

@freezed
abstract class ProjectContextPreviewReusePayload
    with _$ProjectContextPreviewReusePayload {
  const ProjectContextPreviewReusePayload._();

  const factory ProjectContextPreviewReusePayload({
    required String token,
    required String fingerprint,
    required String outputSha256,
    required String inlineOutput,
    required bool inlineOutputTruncated,
  }) = _ProjectContextPreviewReusePayload;

  factory ProjectContextPreviewReusePayload.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProjectContextPreviewReusePayload(
      token: _readString(json, 'token') ?? '',
      fingerprint: _readString(json, 'fingerprint') ?? '',
      outputSha256: _readString(json, 'outputSha256') ?? '',
      inlineOutput: _readString(json, 'inlineOutput') ?? '',
      inlineOutputTruncated: _readBool(json['inlineOutputTruncated']) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'fingerprint': fingerprint,
      'outputSha256': outputSha256,
      'inlineOutput': inlineOutput,
      'inlineOutputTruncated': inlineOutputTruncated,
    };
  }
}

@freezed
abstract class ProjectContextMetadata with _$ProjectContextMetadata {
  const ProjectContextMetadata._();

  const factory ProjectContextMetadata({
    String? selectedFile,
    String? trigger,
    String? buildTarget,
    String? priority,
    String? branch,
    @Default(<String>[]) List<String> requiredFiles,
    @Default(false) bool teamModeEnabled,
    @Default(<ProjectContextTeamRole>[]) List<ProjectContextTeamRole> teamRoles,
    String? teamGoal,
    String? previewContextFingerprint,
    String? previewCompileFingerprint,
    String? previewCompileOutputSha256,
    @Default(false) bool previewReuseRequested,
    @Default(ProjectContextPreviewReuseStrategy.none)
    ProjectContextPreviewReuseStrategy previewReuseStrategy,
    String? previewServerVersionToken,
    String? previewArtifactPath,
    ProjectContextPreviewReusePayload? previewReusePayload,
    String? compileFingerprint,
    String? idempotencyKey,
  }) = _ProjectContextMetadata;

  factory ProjectContextMetadata.fromJson(Map<String, dynamic> json) {
    final selectedFile = _firstNonBlank(<String?>[
      _readString(json, 'selectedFile'),
      _readString(json, 'selected_file'),
      _readString(json, 'activeFile'),
      _readString(json, 'active_file'),
    ]);

    final requiredFiles = _readStringList(json, const <String>[
      'requiredFiles',
      'required_files',
      'requiredFilePaths',
      'required_file_paths',
      'requiredPaths',
      'required_paths',
    ]);

    final parsedRoles = _readTeamRoles(json);
    final teamGoal = _firstNonBlank(<String?>[
      _readString(json, 'teamGoal'),
      _readString(json, 'team_goal'),
    ]);
    final previewReusePayloadRaw = json['previewReusePayload'];

    return ProjectContextMetadata(
      selectedFile: selectedFile,
      trigger: _readString(json, 'trigger'),
      buildTarget: _readString(json, 'buildTarget'),
      priority: _readString(json, 'priority'),
      branch: _readString(json, 'branch'),
      requiredFiles: List<String>.unmodifiable(requiredFiles),
      teamModeEnabled: _readBool(_firstDefined(<Object?>[
            json['teamMode'],
            json['team_mode'],
            json['multiAgent'],
          ])) ??
          false,
      teamRoles: List<ProjectContextTeamRole>.unmodifiable(parsedRoles),
      teamGoal: teamGoal,
      previewContextFingerprint: _readString(json, 'previewContextFingerprint'),
      previewCompileFingerprint: _readString(json, 'previewCompileFingerprint'),
      previewCompileOutputSha256:
          _readString(json, 'previewCompileOutputSha256'),
      previewReuseRequested: _readBool(json['previewReuseRequested']) ?? false,
      previewReuseStrategy: ProjectContextPreviewReuseStrategy.fromRaw(
        json['previewReuseStrategy'],
      ),
      previewServerVersionToken: _readString(json, 'previewServerVersionToken'),
      previewArtifactPath: _readString(json, 'previewArtifactPath'),
      previewReusePayload: previewReusePayloadRaw is Map
          ? ProjectContextPreviewReusePayload.fromJson(
              Map<String, dynamic>.from(previewReusePayloadRaw),
            )
          : null,
      compileFingerprint: _readString(json, 'compileFingerprint'),
      idempotencyKey: _firstNonBlank(<String?>[
        _readString(json, 'idempotencyKey'),
        _readString(json, 'x-idempotency-key'),
      ]),
    );
  }

  static const List<ProjectContextTeamRole> _defaultTeamRoles =
      <ProjectContextTeamRole>[
    ProjectContextTeamRole.architect,
    ProjectContextTeamRole.coder,
    ProjectContextTeamRole.reviewer,
  ];

  bool get hasTeamMode =>
      teamModeEnabled ||
      teamRoles.isNotEmpty ||
      (teamGoal?.isNotEmpty ?? false);

  List<ProjectContextTeamRole> get effectiveTeamRoles => teamRoles.isNotEmpty
      ? teamRoles
      : (teamModeEnabled
          ? _defaultTeamRoles
          : const <ProjectContextTeamRole>[]);

  String? get activeFile => selectedFile;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (selectedFile != null && selectedFile!.isNotEmpty) {
      json['selectedFile'] = selectedFile;
    }
    if (trigger != null && trigger!.isNotEmpty) {
      json['trigger'] = trigger;
    }
    if (buildTarget != null && buildTarget!.isNotEmpty) {
      json['buildTarget'] = buildTarget;
    }
    if (priority != null && priority!.isNotEmpty) {
      json['priority'] = priority;
    }
    if (branch != null && branch!.isNotEmpty) {
      json['branch'] = branch;
    }
    if (requiredFiles.isNotEmpty) {
      json['requiredFiles'] = List<String>.from(requiredFiles);
    }
    if (teamModeEnabled) {
      json['teamMode'] = true;
    }
    if (teamRoles.isNotEmpty) {
      json['teamRoles'] =
          teamRoles.map((role) => role.name).toList(growable: false);
    }
    if (teamGoal != null && teamGoal!.isNotEmpty) {
      json['teamGoal'] = teamGoal;
    }
    if (previewContextFingerprint != null &&
        previewContextFingerprint!.isNotEmpty) {
      json['previewContextFingerprint'] = previewContextFingerprint;
    }
    if (previewCompileFingerprint != null &&
        previewCompileFingerprint!.isNotEmpty) {
      json['previewCompileFingerprint'] = previewCompileFingerprint;
    }
    if (previewCompileOutputSha256 != null &&
        previewCompileOutputSha256!.isNotEmpty) {
      json['previewCompileOutputSha256'] = previewCompileOutputSha256;
    }

    final shouldWritePreviewReuseFields = previewReuseRequested ||
        previewReuseStrategy != ProjectContextPreviewReuseStrategy.none ||
        (previewServerVersionToken?.isNotEmpty ?? false) ||
        (previewArtifactPath?.isNotEmpty ?? false) ||
        previewReusePayload != null;
    if (shouldWritePreviewReuseFields) {
      json['previewReuseRequested'] = previewReuseRequested;
      json['previewReuseStrategy'] = previewReuseStrategy.value;
    }
    if (previewServerVersionToken != null &&
        previewServerVersionToken!.isNotEmpty) {
      json['previewServerVersionToken'] = previewServerVersionToken;
    }
    if (previewArtifactPath != null && previewArtifactPath!.isNotEmpty) {
      json['previewArtifactPath'] = previewArtifactPath;
    }
    if (previewReusePayload != null) {
      json['previewReusePayload'] = previewReusePayload!.toJson();
    }
    if (compileFingerprint != null && compileFingerprint!.isNotEmpty) {
      json['compileFingerprint'] = compileFingerprint;
    }
    if (idempotencyKey != null && idempotencyKey!.isNotEmpty) {
      json['idempotencyKey'] = idempotencyKey;
    }

    return json;
  }

  static List<ProjectContextTeamRole> _readTeamRoles(
      Map<String, dynamic> json) {
    final raw = _firstDefined(<Object?>[
      json['teamRoles'],
      json['team_roles'],
      json['agents'],
    ]);
    if (raw is! Iterable) {
      return const <ProjectContextTeamRole>[];
    }

    final resolved = <ProjectContextTeamRole>{};
    for (final item in raw) {
      final parsed = ProjectContextTeamRole.fromRaw(item);
      if (parsed != null) {
        resolved.add(parsed);
      }
    }
    return resolved.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
  }
}

@freezed
abstract class ProjectContext with _$ProjectContext {
  const ProjectContext._();

  const factory ProjectContext({
    required String projectId,
    required String taskId,
    @Default(<String, String>{}) Map<String, String> files,
    @Default(ProjectContextMetadata()) ProjectContextMetadata metadata,
  }) = _ProjectContext;

  factory ProjectContext.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final files = <String, String>{};
    if (rawFiles is Map) {
      for (final entry in rawFiles.entries) {
        files[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    final rawMetadata = json['metadata'];
    return ProjectContext(
      projectId: _readString(json, 'projectId') ?? '',
      taskId: _readString(json, 'taskId') ?? '',
      files: files,
      metadata: rawMetadata is Map
          ? ProjectContextMetadata.fromJson(
              Map<String, dynamic>.from(rawMetadata),
            )
          : const ProjectContextMetadata(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projectId': projectId,
      'taskId': taskId,
      'files': Map<String, String>.from(files),
      'metadata': metadata.toJson(),
    };
  }

  ProjectContext freeze() {
    return ProjectContext(
      projectId: projectId,
      taskId: taskId,
      files:
          UnmodifiableMapView<String, String>(Map<String, String>.from(files)),
      metadata: metadata.copyWith(
        requiredFiles: List<String>.unmodifiable(metadata.requiredFiles),
        teamRoles:
            List<ProjectContextTeamRole>.unmodifiable(metadata.teamRoles),
      ),
    );
  }
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

bool? _readBool(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized == 'true' || normalized == '1' || normalized == 'enabled') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'disabled') {
    return false;
  }
  return null;
}

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  final raw =
      _firstDefined(keys.map((key) => json[key]).toList(growable: false));
  if (raw == null) {
    return const <String>[];
  }

  if (raw is Iterable) {
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  final normalized = raw.toString().trim();
  if (normalized.isEmpty) {
    return const <String>[];
  }

  final stripped = normalized.startsWith('[') && normalized.endsWith(']')
      ? normalized.substring(1, normalized.length - 1)
      : normalized;
  return stripped
      .split(RegExp(r'[\n,;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String? _firstNonBlank(List<String?> values) {
  for (final value in values) {
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

Object? _firstDefined(List<Object?> values) {
  for (final value in values) {
    if (value != null) {
      return value;
    }
  }
  return null;
}
