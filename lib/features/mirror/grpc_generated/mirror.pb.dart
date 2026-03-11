// This is a generated file - do not edit.
//
// Generated from mirror.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CompileRequest extends $pb.GeneratedMessage {
  factory CompileRequest({
    $core.String? prompt,
    $core.String? projectId,
    $core.String? taskId,
    $core.String? mode,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? files,
    $core.String? metadataJson,
  }) {
    final result = create();
    if (prompt != null) result.prompt = prompt;
    if (projectId != null) result.projectId = projectId;
    if (taskId != null) result.taskId = taskId;
    if (mode != null) result.mode = mode;
    if (files != null) result.files.addEntries(files);
    if (metadataJson != null) result.metadataJson = metadataJson;
    return result;
  }

  CompileRequest._();

  factory CompileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompileRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'mirror.compute.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'prompt')
    ..aOS(2, _omitFieldNames ? '' : 'projectId')
    ..aOS(3, _omitFieldNames ? '' : 'taskId')
    ..aOS(4, _omitFieldNames ? '' : 'mode')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'files',
        entryClassName: 'CompileRequest.FilesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('mirror.compute.v1'))
    ..aOS(6, _omitFieldNames ? '' : 'metadataJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompileRequest copyWith(void Function(CompileRequest) updates) =>
      super.copyWith((message) => updates(message as CompileRequest))
          as CompileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompileRequest create() => CompileRequest._();
  @$core.override
  CompileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompileRequest>(create);
  static CompileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get prompt => $_getSZ(0);
  @$pb.TagNumber(1)
  set prompt($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrompt() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrompt() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get projectId => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProjectId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get taskId => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTaskId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mode => $_getSZ(3);
  @$pb.TagNumber(4)
  set mode($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get files => $_getMap(4);

  @$pb.TagNumber(6)
  $core.String get metadataJson => $_getSZ(5);
  @$pb.TagNumber(6)
  set metadataJson($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMetadataJson() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetadataJson() => $_clearField(6);
}

class CompileResponse extends $pb.GeneratedMessage {
  factory CompileResponse({
    $core.bool? success,
    $core.String? output,
    $core.Iterable<$core.String>? errors,
    $core.Iterable<$core.String>? warnings,
    $core.Iterable<$core.String>? logs,
    $core.String? signedUrl,
    $core.String? artifactPath,
    $core.String? errorJson,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (output != null) result.output = output;
    if (errors != null) result.errors.addAll(errors);
    if (warnings != null) result.warnings.addAll(warnings);
    if (logs != null) result.logs.addAll(logs);
    if (signedUrl != null) result.signedUrl = signedUrl;
    if (artifactPath != null) result.artifactPath = artifactPath;
    if (errorJson != null) result.errorJson = errorJson;
    return result;
  }

  CompileResponse._();

  factory CompileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompileResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'mirror.compute.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'output')
    ..pPS(3, _omitFieldNames ? '' : 'errors')
    ..pPS(4, _omitFieldNames ? '' : 'warnings')
    ..pPS(5, _omitFieldNames ? '' : 'logs')
    ..aOS(6, _omitFieldNames ? '' : 'signedUrl')
    ..aOS(7, _omitFieldNames ? '' : 'artifactPath')
    ..aOS(8, _omitFieldNames ? '' : 'errorJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompileResponse copyWith(void Function(CompileResponse) updates) =>
      super.copyWith((message) => updates(message as CompileResponse))
          as CompileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompileResponse create() => CompileResponse._();
  @$core.override
  CompileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompileResponse>(create);
  static CompileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get output => $_getSZ(1);
  @$pb.TagNumber(2)
  set output($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutput() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutput() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get errors => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get warnings => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get logs => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get signedUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set signedUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSignedUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignedUrl() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get artifactPath => $_getSZ(6);
  @$pb.TagNumber(7)
  set artifactPath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasArtifactPath() => $_has(6);
  @$pb.TagNumber(7)
  void clearArtifactPath() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get errorJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set errorJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasErrorJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearErrorJson() => $_clearField(8);
}

class ApplyRequest extends $pb.GeneratedMessage {
  factory ApplyRequest({
    $core.String? prompt,
    $core.String? projectId,
    $core.String? taskId,
    $core.String? mode,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? files,
    $core.String? metadataJson,
  }) {
    final result = create();
    if (prompt != null) result.prompt = prompt;
    if (projectId != null) result.projectId = projectId;
    if (taskId != null) result.taskId = taskId;
    if (mode != null) result.mode = mode;
    if (files != null) result.files.addEntries(files);
    if (metadataJson != null) result.metadataJson = metadataJson;
    return result;
  }

  ApplyRequest._();

  factory ApplyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'mirror.compute.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'prompt')
    ..aOS(2, _omitFieldNames ? '' : 'projectId')
    ..aOS(3, _omitFieldNames ? '' : 'taskId')
    ..aOS(4, _omitFieldNames ? '' : 'mode')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'files',
        entryClassName: 'ApplyRequest.FilesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('mirror.compute.v1'))
    ..aOS(6, _omitFieldNames ? '' : 'metadataJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyRequest copyWith(void Function(ApplyRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyRequest))
          as ApplyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyRequest create() => ApplyRequest._();
  @$core.override
  ApplyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyRequest>(create);
  static ApplyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get prompt => $_getSZ(0);
  @$pb.TagNumber(1)
  set prompt($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrompt() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrompt() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get projectId => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProjectId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get taskId => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTaskId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mode => $_getSZ(3);
  @$pb.TagNumber(4)
  set mode($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get files => $_getMap(4);

  @$pb.TagNumber(6)
  $core.String get metadataJson => $_getSZ(5);
  @$pb.TagNumber(6)
  set metadataJson($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMetadataJson() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetadataJson() => $_clearField(6);
}

class ApplyResponse extends $pb.GeneratedMessage {
  factory ApplyResponse({
    $core.bool? success,
    $core.String? output,
    $core.Iterable<$core.String>? errors,
    $core.Iterable<$core.String>? warnings,
    $core.Iterable<$core.String>? logs,
    $core.String? signedUrl,
    $core.String? artifactPath,
    $core.String? errorJson,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (output != null) result.output = output;
    if (errors != null) result.errors.addAll(errors);
    if (warnings != null) result.warnings.addAll(warnings);
    if (logs != null) result.logs.addAll(logs);
    if (signedUrl != null) result.signedUrl = signedUrl;
    if (artifactPath != null) result.artifactPath = artifactPath;
    if (errorJson != null) result.errorJson = errorJson;
    return result;
  }

  ApplyResponse._();

  factory ApplyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'mirror.compute.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'output')
    ..pPS(3, _omitFieldNames ? '' : 'errors')
    ..pPS(4, _omitFieldNames ? '' : 'warnings')
    ..pPS(5, _omitFieldNames ? '' : 'logs')
    ..aOS(6, _omitFieldNames ? '' : 'signedUrl')
    ..aOS(7, _omitFieldNames ? '' : 'artifactPath')
    ..aOS(8, _omitFieldNames ? '' : 'errorJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyResponse copyWith(void Function(ApplyResponse) updates) =>
      super.copyWith((message) => updates(message as ApplyResponse))
          as ApplyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyResponse create() => ApplyResponse._();
  @$core.override
  ApplyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyResponse>(create);
  static ApplyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get output => $_getSZ(1);
  @$pb.TagNumber(2)
  set output($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutput() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutput() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get errors => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get warnings => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get logs => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get signedUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set signedUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSignedUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignedUrl() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get artifactPath => $_getSZ(6);
  @$pb.TagNumber(7)
  set artifactPath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasArtifactPath() => $_has(6);
  @$pb.TagNumber(7)
  void clearArtifactPath() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get errorJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set errorJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasErrorJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearErrorJson() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
