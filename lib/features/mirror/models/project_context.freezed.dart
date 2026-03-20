// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectContextPreviewReusePayload {
  String get token;
  String get fingerprint;
  String get outputSha256;
  String get inlineOutput;
  bool get inlineOutputTruncated;

  /// Create a copy of ProjectContextPreviewReusePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectContextPreviewReusePayloadCopyWith<ProjectContextPreviewReusePayload>
      get copyWith => _$ProjectContextPreviewReusePayloadCopyWithImpl<
              ProjectContextPreviewReusePayload>(
          this as ProjectContextPreviewReusePayload, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectContextPreviewReusePayload &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint) &&
            (identical(other.outputSha256, outputSha256) ||
                other.outputSha256 == outputSha256) &&
            (identical(other.inlineOutput, inlineOutput) ||
                other.inlineOutput == inlineOutput) &&
            (identical(other.inlineOutputTruncated, inlineOutputTruncated) ||
                other.inlineOutputTruncated == inlineOutputTruncated));
  }

  @override
  int get hashCode => Object.hash(runtimeType, token, fingerprint, outputSha256,
      inlineOutput, inlineOutputTruncated);

  @override
  String toString() {
    return 'ProjectContextPreviewReusePayload(token: $token, fingerprint: $fingerprint, outputSha256: $outputSha256, inlineOutput: $inlineOutput, inlineOutputTruncated: $inlineOutputTruncated)';
  }
}

/// @nodoc
abstract mixin class $ProjectContextPreviewReusePayloadCopyWith<$Res> {
  factory $ProjectContextPreviewReusePayloadCopyWith(
          ProjectContextPreviewReusePayload value,
          $Res Function(ProjectContextPreviewReusePayload) _then) =
      _$ProjectContextPreviewReusePayloadCopyWithImpl;
  @useResult
  $Res call(
      {String token,
      String fingerprint,
      String outputSha256,
      String inlineOutput,
      bool inlineOutputTruncated});
}

/// @nodoc
class _$ProjectContextPreviewReusePayloadCopyWithImpl<$Res>
    implements $ProjectContextPreviewReusePayloadCopyWith<$Res> {
  _$ProjectContextPreviewReusePayloadCopyWithImpl(this._self, this._then);

  final ProjectContextPreviewReusePayload _self;
  final $Res Function(ProjectContextPreviewReusePayload) _then;

  /// Create a copy of ProjectContextPreviewReusePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? fingerprint = null,
    Object? outputSha256 = null,
    Object? inlineOutput = null,
    Object? inlineOutputTruncated = null,
  }) {
    return _then(_self.copyWith(
      token: null == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      fingerprint: null == fingerprint
          ? _self.fingerprint
          : fingerprint // ignore: cast_nullable_to_non_nullable
              as String,
      outputSha256: null == outputSha256
          ? _self.outputSha256
          : outputSha256 // ignore: cast_nullable_to_non_nullable
              as String,
      inlineOutput: null == inlineOutput
          ? _self.inlineOutput
          : inlineOutput // ignore: cast_nullable_to_non_nullable
              as String,
      inlineOutputTruncated: null == inlineOutputTruncated
          ? _self.inlineOutputTruncated
          : inlineOutputTruncated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectContextPreviewReusePayload].
extension ProjectContextPreviewReusePayloadPatterns
    on ProjectContextPreviewReusePayload {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ProjectContextPreviewReusePayload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectContextPreviewReusePayload() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ProjectContextPreviewReusePayload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextPreviewReusePayload():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ProjectContextPreviewReusePayload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextPreviewReusePayload() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String token, String fingerprint, String outputSha256,
            String inlineOutput, bool inlineOutputTruncated)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectContextPreviewReusePayload() when $default != null:
        return $default(_that.token, _that.fingerprint, _that.outputSha256,
            _that.inlineOutput, _that.inlineOutputTruncated);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String token, String fingerprint, String outputSha256,
            String inlineOutput, bool inlineOutputTruncated)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextPreviewReusePayload():
        return $default(_that.token, _that.fingerprint, _that.outputSha256,
            _that.inlineOutput, _that.inlineOutputTruncated);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String token, String fingerprint, String outputSha256,
            String inlineOutput, bool inlineOutputTruncated)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextPreviewReusePayload() when $default != null:
        return $default(_that.token, _that.fingerprint, _that.outputSha256,
            _that.inlineOutput, _that.inlineOutputTruncated);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectContextPreviewReusePayload
    extends ProjectContextPreviewReusePayload {
  const _ProjectContextPreviewReusePayload(
      {required this.token,
      required this.fingerprint,
      required this.outputSha256,
      required this.inlineOutput,
      required this.inlineOutputTruncated})
      : super._();

  @override
  final String token;
  @override
  final String fingerprint;
  @override
  final String outputSha256;
  @override
  final String inlineOutput;
  @override
  final bool inlineOutputTruncated;

  /// Create a copy of ProjectContextPreviewReusePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectContextPreviewReusePayloadCopyWith<
          _ProjectContextPreviewReusePayload>
      get copyWith => __$ProjectContextPreviewReusePayloadCopyWithImpl<
          _ProjectContextPreviewReusePayload>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectContextPreviewReusePayload &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.fingerprint, fingerprint) ||
                other.fingerprint == fingerprint) &&
            (identical(other.outputSha256, outputSha256) ||
                other.outputSha256 == outputSha256) &&
            (identical(other.inlineOutput, inlineOutput) ||
                other.inlineOutput == inlineOutput) &&
            (identical(other.inlineOutputTruncated, inlineOutputTruncated) ||
                other.inlineOutputTruncated == inlineOutputTruncated));
  }

  @override
  int get hashCode => Object.hash(runtimeType, token, fingerprint, outputSha256,
      inlineOutput, inlineOutputTruncated);

  @override
  String toString() {
    return 'ProjectContextPreviewReusePayload(token: $token, fingerprint: $fingerprint, outputSha256: $outputSha256, inlineOutput: $inlineOutput, inlineOutputTruncated: $inlineOutputTruncated)';
  }
}

/// @nodoc
abstract mixin class _$ProjectContextPreviewReusePayloadCopyWith<$Res>
    implements $ProjectContextPreviewReusePayloadCopyWith<$Res> {
  factory _$ProjectContextPreviewReusePayloadCopyWith(
          _ProjectContextPreviewReusePayload value,
          $Res Function(_ProjectContextPreviewReusePayload) _then) =
      __$ProjectContextPreviewReusePayloadCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String token,
      String fingerprint,
      String outputSha256,
      String inlineOutput,
      bool inlineOutputTruncated});
}

/// @nodoc
class __$ProjectContextPreviewReusePayloadCopyWithImpl<$Res>
    implements _$ProjectContextPreviewReusePayloadCopyWith<$Res> {
  __$ProjectContextPreviewReusePayloadCopyWithImpl(this._self, this._then);

  final _ProjectContextPreviewReusePayload _self;
  final $Res Function(_ProjectContextPreviewReusePayload) _then;

  /// Create a copy of ProjectContextPreviewReusePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? token = null,
    Object? fingerprint = null,
    Object? outputSha256 = null,
    Object? inlineOutput = null,
    Object? inlineOutputTruncated = null,
  }) {
    return _then(_ProjectContextPreviewReusePayload(
      token: null == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      fingerprint: null == fingerprint
          ? _self.fingerprint
          : fingerprint // ignore: cast_nullable_to_non_nullable
              as String,
      outputSha256: null == outputSha256
          ? _self.outputSha256
          : outputSha256 // ignore: cast_nullable_to_non_nullable
              as String,
      inlineOutput: null == inlineOutput
          ? _self.inlineOutput
          : inlineOutput // ignore: cast_nullable_to_non_nullable
              as String,
      inlineOutputTruncated: null == inlineOutputTruncated
          ? _self.inlineOutputTruncated
          : inlineOutputTruncated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$ProjectContextMetadata {
  String? get selectedFile;
  String? get trigger;
  String? get buildTarget;
  String? get priority;
  String? get branch;
  List<String> get requiredFiles;
  bool get teamModeEnabled;
  List<ProjectContextTeamRole> get teamRoles;
  String? get teamGoal;
  String? get previewContextFingerprint;
  String? get previewCompileFingerprint;
  String? get previewCompileOutputSha256;
  bool get previewReuseRequested;
  ProjectContextPreviewReuseStrategy get previewReuseStrategy;
  String? get previewServerVersionToken;
  String? get previewArtifactPath;
  ProjectContextPreviewReusePayload? get previewReusePayload;
  String? get compileFingerprint;
  String? get idempotencyKey;

  /// Create a copy of ProjectContextMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectContextMetadataCopyWith<ProjectContextMetadata> get copyWith =>
      _$ProjectContextMetadataCopyWithImpl<ProjectContextMetadata>(
          this as ProjectContextMetadata, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectContextMetadata &&
            (identical(other.selectedFile, selectedFile) ||
                other.selectedFile == selectedFile) &&
            (identical(other.trigger, trigger) || other.trigger == trigger) &&
            (identical(other.buildTarget, buildTarget) ||
                other.buildTarget == buildTarget) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.branch, branch) || other.branch == branch) &&
            const DeepCollectionEquality()
                .equals(other.requiredFiles, requiredFiles) &&
            (identical(other.teamModeEnabled, teamModeEnabled) ||
                other.teamModeEnabled == teamModeEnabled) &&
            const DeepCollectionEquality().equals(other.teamRoles, teamRoles) &&
            (identical(other.teamGoal, teamGoal) ||
                other.teamGoal == teamGoal) &&
            (identical(other.previewContextFingerprint,
                    previewContextFingerprint) ||
                other.previewContextFingerprint == previewContextFingerprint) &&
            (identical(other.previewCompileFingerprint,
                    previewCompileFingerprint) ||
                other.previewCompileFingerprint == previewCompileFingerprint) &&
            (identical(other.previewCompileOutputSha256,
                    previewCompileOutputSha256) ||
                other.previewCompileOutputSha256 ==
                    previewCompileOutputSha256) &&
            (identical(other.previewReuseRequested, previewReuseRequested) ||
                other.previewReuseRequested == previewReuseRequested) &&
            (identical(other.previewReuseStrategy, previewReuseStrategy) ||
                other.previewReuseStrategy == previewReuseStrategy) &&
            (identical(other.previewServerVersionToken,
                    previewServerVersionToken) ||
                other.previewServerVersionToken == previewServerVersionToken) &&
            (identical(other.previewArtifactPath, previewArtifactPath) ||
                other.previewArtifactPath == previewArtifactPath) &&
            (identical(other.previewReusePayload, previewReusePayload) ||
                other.previewReusePayload == previewReusePayload) &&
            (identical(other.compileFingerprint, compileFingerprint) ||
                other.compileFingerprint == compileFingerprint) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        selectedFile,
        trigger,
        buildTarget,
        priority,
        branch,
        const DeepCollectionEquality().hash(requiredFiles),
        teamModeEnabled,
        const DeepCollectionEquality().hash(teamRoles),
        teamGoal,
        previewContextFingerprint,
        previewCompileFingerprint,
        previewCompileOutputSha256,
        previewReuseRequested,
        previewReuseStrategy,
        previewServerVersionToken,
        previewArtifactPath,
        previewReusePayload,
        compileFingerprint,
        idempotencyKey
      ]);

  @override
  String toString() {
    return 'ProjectContextMetadata(selectedFile: $selectedFile, trigger: $trigger, buildTarget: $buildTarget, priority: $priority, branch: $branch, requiredFiles: $requiredFiles, teamModeEnabled: $teamModeEnabled, teamRoles: $teamRoles, teamGoal: $teamGoal, previewContextFingerprint: $previewContextFingerprint, previewCompileFingerprint: $previewCompileFingerprint, previewCompileOutputSha256: $previewCompileOutputSha256, previewReuseRequested: $previewReuseRequested, previewReuseStrategy: $previewReuseStrategy, previewServerVersionToken: $previewServerVersionToken, previewArtifactPath: $previewArtifactPath, previewReusePayload: $previewReusePayload, compileFingerprint: $compileFingerprint, idempotencyKey: $idempotencyKey)';
  }
}

/// @nodoc
abstract mixin class $ProjectContextMetadataCopyWith<$Res> {
  factory $ProjectContextMetadataCopyWith(ProjectContextMetadata value,
          $Res Function(ProjectContextMetadata) _then) =
      _$ProjectContextMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String? selectedFile,
      String? trigger,
      String? buildTarget,
      String? priority,
      String? branch,
      List<String> requiredFiles,
      bool teamModeEnabled,
      List<ProjectContextTeamRole> teamRoles,
      String? teamGoal,
      String? previewContextFingerprint,
      String? previewCompileFingerprint,
      String? previewCompileOutputSha256,
      bool previewReuseRequested,
      ProjectContextPreviewReuseStrategy previewReuseStrategy,
      String? previewServerVersionToken,
      String? previewArtifactPath,
      ProjectContextPreviewReusePayload? previewReusePayload,
      String? compileFingerprint,
      String? idempotencyKey});

  $ProjectContextPreviewReusePayloadCopyWith<$Res>? get previewReusePayload;
}

/// @nodoc
class _$ProjectContextMetadataCopyWithImpl<$Res>
    implements $ProjectContextMetadataCopyWith<$Res> {
  _$ProjectContextMetadataCopyWithImpl(this._self, this._then);

  final ProjectContextMetadata _self;
  final $Res Function(ProjectContextMetadata) _then;

  /// Create a copy of ProjectContextMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedFile = freezed,
    Object? trigger = freezed,
    Object? buildTarget = freezed,
    Object? priority = freezed,
    Object? branch = freezed,
    Object? requiredFiles = null,
    Object? teamModeEnabled = null,
    Object? teamRoles = null,
    Object? teamGoal = freezed,
    Object? previewContextFingerprint = freezed,
    Object? previewCompileFingerprint = freezed,
    Object? previewCompileOutputSha256 = freezed,
    Object? previewReuseRequested = null,
    Object? previewReuseStrategy = null,
    Object? previewServerVersionToken = freezed,
    Object? previewArtifactPath = freezed,
    Object? previewReusePayload = freezed,
    Object? compileFingerprint = freezed,
    Object? idempotencyKey = freezed,
  }) {
    return _then(_self.copyWith(
      selectedFile: freezed == selectedFile
          ? _self.selectedFile
          : selectedFile // ignore: cast_nullable_to_non_nullable
              as String?,
      trigger: freezed == trigger
          ? _self.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as String?,
      buildTarget: freezed == buildTarget
          ? _self.buildTarget
          : buildTarget // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      branch: freezed == branch
          ? _self.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredFiles: null == requiredFiles
          ? _self.requiredFiles
          : requiredFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      teamModeEnabled: null == teamModeEnabled
          ? _self.teamModeEnabled
          : teamModeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      teamRoles: null == teamRoles
          ? _self.teamRoles
          : teamRoles // ignore: cast_nullable_to_non_nullable
              as List<ProjectContextTeamRole>,
      teamGoal: freezed == teamGoal
          ? _self.teamGoal
          : teamGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      previewContextFingerprint: freezed == previewContextFingerprint
          ? _self.previewContextFingerprint
          : previewContextFingerprint // ignore: cast_nullable_to_non_nullable
              as String?,
      previewCompileFingerprint: freezed == previewCompileFingerprint
          ? _self.previewCompileFingerprint
          : previewCompileFingerprint // ignore: cast_nullable_to_non_nullable
              as String?,
      previewCompileOutputSha256: freezed == previewCompileOutputSha256
          ? _self.previewCompileOutputSha256
          : previewCompileOutputSha256 // ignore: cast_nullable_to_non_nullable
              as String?,
      previewReuseRequested: null == previewReuseRequested
          ? _self.previewReuseRequested
          : previewReuseRequested // ignore: cast_nullable_to_non_nullable
              as bool,
      previewReuseStrategy: null == previewReuseStrategy
          ? _self.previewReuseStrategy
          : previewReuseStrategy // ignore: cast_nullable_to_non_nullable
              as ProjectContextPreviewReuseStrategy,
      previewServerVersionToken: freezed == previewServerVersionToken
          ? _self.previewServerVersionToken
          : previewServerVersionToken // ignore: cast_nullable_to_non_nullable
              as String?,
      previewArtifactPath: freezed == previewArtifactPath
          ? _self.previewArtifactPath
          : previewArtifactPath // ignore: cast_nullable_to_non_nullable
              as String?,
      previewReusePayload: freezed == previewReusePayload
          ? _self.previewReusePayload
          : previewReusePayload // ignore: cast_nullable_to_non_nullable
              as ProjectContextPreviewReusePayload?,
      compileFingerprint: freezed == compileFingerprint
          ? _self.compileFingerprint
          : compileFingerprint // ignore: cast_nullable_to_non_nullable
              as String?,
      idempotencyKey: freezed == idempotencyKey
          ? _self.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of ProjectContextMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectContextPreviewReusePayloadCopyWith<$Res>? get previewReusePayload {
    if (_self.previewReusePayload == null) {
      return null;
    }

    return $ProjectContextPreviewReusePayloadCopyWith<$Res>(
        _self.previewReusePayload!, (value) {
      return _then(_self.copyWith(previewReusePayload: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ProjectContextMetadata].
extension ProjectContextMetadataPatterns on ProjectContextMetadata {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ProjectContextMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectContextMetadata() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ProjectContextMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextMetadata():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ProjectContextMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextMetadata() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String? selectedFile,
            String? trigger,
            String? buildTarget,
            String? priority,
            String? branch,
            List<String> requiredFiles,
            bool teamModeEnabled,
            List<ProjectContextTeamRole> teamRoles,
            String? teamGoal,
            String? previewContextFingerprint,
            String? previewCompileFingerprint,
            String? previewCompileOutputSha256,
            bool previewReuseRequested,
            ProjectContextPreviewReuseStrategy previewReuseStrategy,
            String? previewServerVersionToken,
            String? previewArtifactPath,
            ProjectContextPreviewReusePayload? previewReusePayload,
            String? compileFingerprint,
            String? idempotencyKey)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectContextMetadata() when $default != null:
        return $default(
            _that.selectedFile,
            _that.trigger,
            _that.buildTarget,
            _that.priority,
            _that.branch,
            _that.requiredFiles,
            _that.teamModeEnabled,
            _that.teamRoles,
            _that.teamGoal,
            _that.previewContextFingerprint,
            _that.previewCompileFingerprint,
            _that.previewCompileOutputSha256,
            _that.previewReuseRequested,
            _that.previewReuseStrategy,
            _that.previewServerVersionToken,
            _that.previewArtifactPath,
            _that.previewReusePayload,
            _that.compileFingerprint,
            _that.idempotencyKey);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String? selectedFile,
            String? trigger,
            String? buildTarget,
            String? priority,
            String? branch,
            List<String> requiredFiles,
            bool teamModeEnabled,
            List<ProjectContextTeamRole> teamRoles,
            String? teamGoal,
            String? previewContextFingerprint,
            String? previewCompileFingerprint,
            String? previewCompileOutputSha256,
            bool previewReuseRequested,
            ProjectContextPreviewReuseStrategy previewReuseStrategy,
            String? previewServerVersionToken,
            String? previewArtifactPath,
            ProjectContextPreviewReusePayload? previewReusePayload,
            String? compileFingerprint,
            String? idempotencyKey)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextMetadata():
        return $default(
            _that.selectedFile,
            _that.trigger,
            _that.buildTarget,
            _that.priority,
            _that.branch,
            _that.requiredFiles,
            _that.teamModeEnabled,
            _that.teamRoles,
            _that.teamGoal,
            _that.previewContextFingerprint,
            _that.previewCompileFingerprint,
            _that.previewCompileOutputSha256,
            _that.previewReuseRequested,
            _that.previewReuseStrategy,
            _that.previewServerVersionToken,
            _that.previewArtifactPath,
            _that.previewReusePayload,
            _that.compileFingerprint,
            _that.idempotencyKey);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String? selectedFile,
            String? trigger,
            String? buildTarget,
            String? priority,
            String? branch,
            List<String> requiredFiles,
            bool teamModeEnabled,
            List<ProjectContextTeamRole> teamRoles,
            String? teamGoal,
            String? previewContextFingerprint,
            String? previewCompileFingerprint,
            String? previewCompileOutputSha256,
            bool previewReuseRequested,
            ProjectContextPreviewReuseStrategy previewReuseStrategy,
            String? previewServerVersionToken,
            String? previewArtifactPath,
            ProjectContextPreviewReusePayload? previewReusePayload,
            String? compileFingerprint,
            String? idempotencyKey)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContextMetadata() when $default != null:
        return $default(
            _that.selectedFile,
            _that.trigger,
            _that.buildTarget,
            _that.priority,
            _that.branch,
            _that.requiredFiles,
            _that.teamModeEnabled,
            _that.teamRoles,
            _that.teamGoal,
            _that.previewContextFingerprint,
            _that.previewCompileFingerprint,
            _that.previewCompileOutputSha256,
            _that.previewReuseRequested,
            _that.previewReuseStrategy,
            _that.previewServerVersionToken,
            _that.previewArtifactPath,
            _that.previewReusePayload,
            _that.compileFingerprint,
            _that.idempotencyKey);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectContextMetadata extends ProjectContextMetadata {
  const _ProjectContextMetadata(
      {this.selectedFile,
      this.trigger,
      this.buildTarget,
      this.priority,
      this.branch,
      final List<String> requiredFiles = const <String>[],
      this.teamModeEnabled = false,
      final List<ProjectContextTeamRole> teamRoles =
          const <ProjectContextTeamRole>[],
      this.teamGoal,
      this.previewContextFingerprint,
      this.previewCompileFingerprint,
      this.previewCompileOutputSha256,
      this.previewReuseRequested = false,
      this.previewReuseStrategy = ProjectContextPreviewReuseStrategy.none,
      this.previewServerVersionToken,
      this.previewArtifactPath,
      this.previewReusePayload,
      this.compileFingerprint,
      this.idempotencyKey})
      : _requiredFiles = requiredFiles,
        _teamRoles = teamRoles,
        super._();

  @override
  final String? selectedFile;
  @override
  final String? trigger;
  @override
  final String? buildTarget;
  @override
  final String? priority;
  @override
  final String? branch;
  final List<String> _requiredFiles;
  @override
  @JsonKey()
  List<String> get requiredFiles {
    if (_requiredFiles is EqualUnmodifiableListView) return _requiredFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredFiles);
  }

  @override
  @JsonKey()
  final bool teamModeEnabled;
  final List<ProjectContextTeamRole> _teamRoles;
  @override
  @JsonKey()
  List<ProjectContextTeamRole> get teamRoles {
    if (_teamRoles is EqualUnmodifiableListView) return _teamRoles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_teamRoles);
  }

  @override
  final String? teamGoal;
  @override
  final String? previewContextFingerprint;
  @override
  final String? previewCompileFingerprint;
  @override
  final String? previewCompileOutputSha256;
  @override
  @JsonKey()
  final bool previewReuseRequested;
  @override
  @JsonKey()
  final ProjectContextPreviewReuseStrategy previewReuseStrategy;
  @override
  final String? previewServerVersionToken;
  @override
  final String? previewArtifactPath;
  @override
  final ProjectContextPreviewReusePayload? previewReusePayload;
  @override
  final String? compileFingerprint;
  @override
  final String? idempotencyKey;

  /// Create a copy of ProjectContextMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectContextMetadataCopyWith<_ProjectContextMetadata> get copyWith =>
      __$ProjectContextMetadataCopyWithImpl<_ProjectContextMetadata>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectContextMetadata &&
            (identical(other.selectedFile, selectedFile) ||
                other.selectedFile == selectedFile) &&
            (identical(other.trigger, trigger) || other.trigger == trigger) &&
            (identical(other.buildTarget, buildTarget) ||
                other.buildTarget == buildTarget) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.branch, branch) || other.branch == branch) &&
            const DeepCollectionEquality()
                .equals(other._requiredFiles, _requiredFiles) &&
            (identical(other.teamModeEnabled, teamModeEnabled) ||
                other.teamModeEnabled == teamModeEnabled) &&
            const DeepCollectionEquality()
                .equals(other._teamRoles, _teamRoles) &&
            (identical(other.teamGoal, teamGoal) ||
                other.teamGoal == teamGoal) &&
            (identical(other.previewContextFingerprint,
                    previewContextFingerprint) ||
                other.previewContextFingerprint == previewContextFingerprint) &&
            (identical(other.previewCompileFingerprint,
                    previewCompileFingerprint) ||
                other.previewCompileFingerprint == previewCompileFingerprint) &&
            (identical(other.previewCompileOutputSha256,
                    previewCompileOutputSha256) ||
                other.previewCompileOutputSha256 ==
                    previewCompileOutputSha256) &&
            (identical(other.previewReuseRequested, previewReuseRequested) ||
                other.previewReuseRequested == previewReuseRequested) &&
            (identical(other.previewReuseStrategy, previewReuseStrategy) ||
                other.previewReuseStrategy == previewReuseStrategy) &&
            (identical(other.previewServerVersionToken,
                    previewServerVersionToken) ||
                other.previewServerVersionToken == previewServerVersionToken) &&
            (identical(other.previewArtifactPath, previewArtifactPath) ||
                other.previewArtifactPath == previewArtifactPath) &&
            (identical(other.previewReusePayload, previewReusePayload) ||
                other.previewReusePayload == previewReusePayload) &&
            (identical(other.compileFingerprint, compileFingerprint) ||
                other.compileFingerprint == compileFingerprint) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        selectedFile,
        trigger,
        buildTarget,
        priority,
        branch,
        const DeepCollectionEquality().hash(_requiredFiles),
        teamModeEnabled,
        const DeepCollectionEquality().hash(_teamRoles),
        teamGoal,
        previewContextFingerprint,
        previewCompileFingerprint,
        previewCompileOutputSha256,
        previewReuseRequested,
        previewReuseStrategy,
        previewServerVersionToken,
        previewArtifactPath,
        previewReusePayload,
        compileFingerprint,
        idempotencyKey
      ]);

  @override
  String toString() {
    return 'ProjectContextMetadata(selectedFile: $selectedFile, trigger: $trigger, buildTarget: $buildTarget, priority: $priority, branch: $branch, requiredFiles: $requiredFiles, teamModeEnabled: $teamModeEnabled, teamRoles: $teamRoles, teamGoal: $teamGoal, previewContextFingerprint: $previewContextFingerprint, previewCompileFingerprint: $previewCompileFingerprint, previewCompileOutputSha256: $previewCompileOutputSha256, previewReuseRequested: $previewReuseRequested, previewReuseStrategy: $previewReuseStrategy, previewServerVersionToken: $previewServerVersionToken, previewArtifactPath: $previewArtifactPath, previewReusePayload: $previewReusePayload, compileFingerprint: $compileFingerprint, idempotencyKey: $idempotencyKey)';
  }
}

/// @nodoc
abstract mixin class _$ProjectContextMetadataCopyWith<$Res>
    implements $ProjectContextMetadataCopyWith<$Res> {
  factory _$ProjectContextMetadataCopyWith(_ProjectContextMetadata value,
          $Res Function(_ProjectContextMetadata) _then) =
      __$ProjectContextMetadataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? selectedFile,
      String? trigger,
      String? buildTarget,
      String? priority,
      String? branch,
      List<String> requiredFiles,
      bool teamModeEnabled,
      List<ProjectContextTeamRole> teamRoles,
      String? teamGoal,
      String? previewContextFingerprint,
      String? previewCompileFingerprint,
      String? previewCompileOutputSha256,
      bool previewReuseRequested,
      ProjectContextPreviewReuseStrategy previewReuseStrategy,
      String? previewServerVersionToken,
      String? previewArtifactPath,
      ProjectContextPreviewReusePayload? previewReusePayload,
      String? compileFingerprint,
      String? idempotencyKey});

  @override
  $ProjectContextPreviewReusePayloadCopyWith<$Res>? get previewReusePayload;
}

/// @nodoc
class __$ProjectContextMetadataCopyWithImpl<$Res>
    implements _$ProjectContextMetadataCopyWith<$Res> {
  __$ProjectContextMetadataCopyWithImpl(this._self, this._then);

  final _ProjectContextMetadata _self;
  final $Res Function(_ProjectContextMetadata) _then;

  /// Create a copy of ProjectContextMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? selectedFile = freezed,
    Object? trigger = freezed,
    Object? buildTarget = freezed,
    Object? priority = freezed,
    Object? branch = freezed,
    Object? requiredFiles = null,
    Object? teamModeEnabled = null,
    Object? teamRoles = null,
    Object? teamGoal = freezed,
    Object? previewContextFingerprint = freezed,
    Object? previewCompileFingerprint = freezed,
    Object? previewCompileOutputSha256 = freezed,
    Object? previewReuseRequested = null,
    Object? previewReuseStrategy = null,
    Object? previewServerVersionToken = freezed,
    Object? previewArtifactPath = freezed,
    Object? previewReusePayload = freezed,
    Object? compileFingerprint = freezed,
    Object? idempotencyKey = freezed,
  }) {
    return _then(_ProjectContextMetadata(
      selectedFile: freezed == selectedFile
          ? _self.selectedFile
          : selectedFile // ignore: cast_nullable_to_non_nullable
              as String?,
      trigger: freezed == trigger
          ? _self.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as String?,
      buildTarget: freezed == buildTarget
          ? _self.buildTarget
          : buildTarget // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      branch: freezed == branch
          ? _self.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredFiles: null == requiredFiles
          ? _self._requiredFiles
          : requiredFiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      teamModeEnabled: null == teamModeEnabled
          ? _self.teamModeEnabled
          : teamModeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      teamRoles: null == teamRoles
          ? _self._teamRoles
          : teamRoles // ignore: cast_nullable_to_non_nullable
              as List<ProjectContextTeamRole>,
      teamGoal: freezed == teamGoal
          ? _self.teamGoal
          : teamGoal // ignore: cast_nullable_to_non_nullable
              as String?,
      previewContextFingerprint: freezed == previewContextFingerprint
          ? _self.previewContextFingerprint
          : previewContextFingerprint // ignore: cast_nullable_to_non_nullable
              as String?,
      previewCompileFingerprint: freezed == previewCompileFingerprint
          ? _self.previewCompileFingerprint
          : previewCompileFingerprint // ignore: cast_nullable_to_non_nullable
              as String?,
      previewCompileOutputSha256: freezed == previewCompileOutputSha256
          ? _self.previewCompileOutputSha256
          : previewCompileOutputSha256 // ignore: cast_nullable_to_non_nullable
              as String?,
      previewReuseRequested: null == previewReuseRequested
          ? _self.previewReuseRequested
          : previewReuseRequested // ignore: cast_nullable_to_non_nullable
              as bool,
      previewReuseStrategy: null == previewReuseStrategy
          ? _self.previewReuseStrategy
          : previewReuseStrategy // ignore: cast_nullable_to_non_nullable
              as ProjectContextPreviewReuseStrategy,
      previewServerVersionToken: freezed == previewServerVersionToken
          ? _self.previewServerVersionToken
          : previewServerVersionToken // ignore: cast_nullable_to_non_nullable
              as String?,
      previewArtifactPath: freezed == previewArtifactPath
          ? _self.previewArtifactPath
          : previewArtifactPath // ignore: cast_nullable_to_non_nullable
              as String?,
      previewReusePayload: freezed == previewReusePayload
          ? _self.previewReusePayload
          : previewReusePayload // ignore: cast_nullable_to_non_nullable
              as ProjectContextPreviewReusePayload?,
      compileFingerprint: freezed == compileFingerprint
          ? _self.compileFingerprint
          : compileFingerprint // ignore: cast_nullable_to_non_nullable
              as String?,
      idempotencyKey: freezed == idempotencyKey
          ? _self.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of ProjectContextMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectContextPreviewReusePayloadCopyWith<$Res>? get previewReusePayload {
    if (_self.previewReusePayload == null) {
      return null;
    }

    return $ProjectContextPreviewReusePayloadCopyWith<$Res>(
        _self.previewReusePayload!, (value) {
      return _then(_self.copyWith(previewReusePayload: value));
    });
  }
}

/// @nodoc
mixin _$ProjectContext {
  String get projectId;
  String get taskId;
  Map<String, String> get files;
  ProjectContextMetadata get metadata;

  /// Create a copy of ProjectContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectContextCopyWith<ProjectContext> get copyWith =>
      _$ProjectContextCopyWithImpl<ProjectContext>(
          this as ProjectContext, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectContext &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            const DeepCollectionEquality().equals(other.files, files) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @override
  int get hashCode => Object.hash(runtimeType, projectId, taskId,
      const DeepCollectionEquality().hash(files), metadata);

  @override
  String toString() {
    return 'ProjectContext(projectId: $projectId, taskId: $taskId, files: $files, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $ProjectContextCopyWith<$Res> {
  factory $ProjectContextCopyWith(
          ProjectContext value, $Res Function(ProjectContext) _then) =
      _$ProjectContextCopyWithImpl;
  @useResult
  $Res call(
      {String projectId,
      String taskId,
      Map<String, String> files,
      ProjectContextMetadata metadata});

  $ProjectContextMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$ProjectContextCopyWithImpl<$Res>
    implements $ProjectContextCopyWith<$Res> {
  _$ProjectContextCopyWithImpl(this._self, this._then);

  final ProjectContext _self;
  final $Res Function(ProjectContext) _then;

  /// Create a copy of ProjectContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectId = null,
    Object? taskId = null,
    Object? files = null,
    Object? metadata = null,
  }) {
    return _then(_self.copyWith(
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      files: null == files
          ? _self.files
          : files // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as ProjectContextMetadata,
    ));
  }

  /// Create a copy of ProjectContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectContextMetadataCopyWith<$Res> get metadata {
    return $ProjectContextMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ProjectContext].
extension ProjectContextPatterns on ProjectContext {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ProjectContext value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectContext() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ProjectContext value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContext():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ProjectContext value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContext() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String projectId, String taskId, Map<String, String> files,
            ProjectContextMetadata metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectContext() when $default != null:
        return $default(
            _that.projectId, _that.taskId, _that.files, _that.metadata);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String projectId, String taskId, Map<String, String> files,
            ProjectContextMetadata metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContext():
        return $default(
            _that.projectId, _that.taskId, _that.files, _that.metadata);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String projectId, String taskId,
            Map<String, String> files, ProjectContextMetadata metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectContext() when $default != null:
        return $default(
            _that.projectId, _that.taskId, _that.files, _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectContext extends ProjectContext {
  const _ProjectContext(
      {required this.projectId,
      required this.taskId,
      final Map<String, String> files = const <String, String>{},
      this.metadata = const ProjectContextMetadata()})
      : _files = files,
        super._();

  @override
  final String projectId;
  @override
  final String taskId;
  final Map<String, String> _files;
  @override
  @JsonKey()
  Map<String, String> get files {
    if (_files is EqualUnmodifiableMapView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_files);
  }

  @override
  @JsonKey()
  final ProjectContextMetadata metadata;

  /// Create a copy of ProjectContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectContextCopyWith<_ProjectContext> get copyWith =>
      __$ProjectContextCopyWithImpl<_ProjectContext>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectContext &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @override
  int get hashCode => Object.hash(runtimeType, projectId, taskId,
      const DeepCollectionEquality().hash(_files), metadata);

  @override
  String toString() {
    return 'ProjectContext(projectId: $projectId, taskId: $taskId, files: $files, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$ProjectContextCopyWith<$Res>
    implements $ProjectContextCopyWith<$Res> {
  factory _$ProjectContextCopyWith(
          _ProjectContext value, $Res Function(_ProjectContext) _then) =
      __$ProjectContextCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String projectId,
      String taskId,
      Map<String, String> files,
      ProjectContextMetadata metadata});

  @override
  $ProjectContextMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$ProjectContextCopyWithImpl<$Res>
    implements _$ProjectContextCopyWith<$Res> {
  __$ProjectContextCopyWithImpl(this._self, this._then);

  final _ProjectContext _self;
  final $Res Function(_ProjectContext) _then;

  /// Create a copy of ProjectContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? projectId = null,
    Object? taskId = null,
    Object? files = null,
    Object? metadata = null,
  }) {
    return _then(_ProjectContext(
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      files: null == files
          ? _self._files
          : files // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as ProjectContextMetadata,
    ));
  }

  /// Create a copy of ProjectContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectContextMetadataCopyWith<$Res> get metadata {
    return $ProjectContextMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

// dart format on
