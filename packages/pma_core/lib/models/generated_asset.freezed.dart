// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generated_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GeneratedAsset {
  @HiveField(0)
  String get id;
  @HiveField(1)
  @JsonKey(name: 'project_id')
  String get projectId;
  @HiveField(2)
  @JsonKey(name: 'task_id')
  String? get taskId;
  @HiveField(3)
  String get prompt;
  @HiveField(4)
  @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
  Map<String, dynamic> get metadata;
  @HiveField(5)
  @JsonKey(name: 'file_url')
  String get fileUrl;
  @HiveField(6)
  @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
  GeneratedAssetFormat get format;
  @HiveField(7)
  int get version;
  @HiveField(8)
  @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
  DateTime get createdAt;
  @HiveField(9)
  @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
  DateTime? get updatedAt;
  @HiveField(10)
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  GeneratedAssetStatus get status;

  /// Create a copy of GeneratedAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GeneratedAssetCopyWith<GeneratedAsset> get copyWith =>
      _$GeneratedAssetCopyWithImpl<GeneratedAsset>(
          this as GeneratedAsset, _$identity);

  /// Serializes this GeneratedAsset to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GeneratedAsset &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            const DeepCollectionEquality().equals(other.metadata, metadata) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      projectId,
      taskId,
      prompt,
      const DeepCollectionEquality().hash(metadata),
      fileUrl,
      format,
      version,
      createdAt,
      updatedAt,
      status);

  @override
  String toString() {
    return 'GeneratedAsset(id: $id, projectId: $projectId, taskId: $taskId, prompt: $prompt, metadata: $metadata, fileUrl: $fileUrl, format: $format, version: $version, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
  }
}

/// @nodoc
abstract mixin class $GeneratedAssetCopyWith<$Res> {
  factory $GeneratedAssetCopyWith(
          GeneratedAsset value, $Res Function(GeneratedAsset) _then) =
      _$GeneratedAssetCopyWithImpl;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) @JsonKey(name: 'project_id') String projectId,
      @HiveField(2) @JsonKey(name: 'task_id') String? taskId,
      @HiveField(3) String prompt,
      @HiveField(4)
      @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
      Map<String, dynamic> metadata,
      @HiveField(5) @JsonKey(name: 'file_url') String fileUrl,
      @HiveField(6)
      @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
      GeneratedAssetFormat format,
      @HiveField(7) int version,
      @HiveField(8)
      @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
      DateTime createdAt,
      @HiveField(9)
      @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
      DateTime? updatedAt,
      @HiveField(10)
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      GeneratedAssetStatus status});
}

/// @nodoc
class _$GeneratedAssetCopyWithImpl<$Res>
    implements $GeneratedAssetCopyWith<$Res> {
  _$GeneratedAssetCopyWithImpl(this._self, this._then);

  final GeneratedAsset _self;
  final $Res Function(GeneratedAsset) _then;

  /// Create a copy of GeneratedAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? taskId = freezed,
    Object? prompt = null,
    Object? metadata = null,
    Object? fileUrl = null,
    Object? format = null,
    Object? version = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: freezed == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      fileUrl: null == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _self.format
          : format // ignore: cast_nullable_to_non_nullable
              as GeneratedAssetFormat,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as GeneratedAssetStatus,
    ));
  }
}

/// Adds pattern-matching-related methods to [GeneratedAsset].
extension GeneratedAssetPatterns on GeneratedAsset {
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
    TResult Function(_GeneratedAsset value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GeneratedAsset() when $default != null:
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
    TResult Function(_GeneratedAsset value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GeneratedAsset():
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
    TResult? Function(_GeneratedAsset value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GeneratedAsset() when $default != null:
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
            @HiveField(0) String id,
            @HiveField(1) @JsonKey(name: 'project_id') String projectId,
            @HiveField(2) @JsonKey(name: 'task_id') String? taskId,
            @HiveField(3) String prompt,
            @HiveField(4)
            @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
            Map<String, dynamic> metadata,
            @HiveField(5) @JsonKey(name: 'file_url') String fileUrl,
            @HiveField(6)
            @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
            GeneratedAssetFormat format,
            @HiveField(7) int version,
            @HiveField(8)
            @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
            DateTime createdAt,
            @HiveField(9)
            @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
            DateTime? updatedAt,
            @HiveField(10)
            @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
            GeneratedAssetStatus status)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GeneratedAsset() when $default != null:
        return $default(
            _that.id,
            _that.projectId,
            _that.taskId,
            _that.prompt,
            _that.metadata,
            _that.fileUrl,
            _that.format,
            _that.version,
            _that.createdAt,
            _that.updatedAt,
            _that.status);
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
            @HiveField(0) String id,
            @HiveField(1) @JsonKey(name: 'project_id') String projectId,
            @HiveField(2) @JsonKey(name: 'task_id') String? taskId,
            @HiveField(3) String prompt,
            @HiveField(4)
            @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
            Map<String, dynamic> metadata,
            @HiveField(5) @JsonKey(name: 'file_url') String fileUrl,
            @HiveField(6)
            @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
            GeneratedAssetFormat format,
            @HiveField(7) int version,
            @HiveField(8)
            @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
            DateTime createdAt,
            @HiveField(9)
            @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
            DateTime? updatedAt,
            @HiveField(10)
            @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
            GeneratedAssetStatus status)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GeneratedAsset():
        return $default(
            _that.id,
            _that.projectId,
            _that.taskId,
            _that.prompt,
            _that.metadata,
            _that.fileUrl,
            _that.format,
            _that.version,
            _that.createdAt,
            _that.updatedAt,
            _that.status);
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
            @HiveField(0) String id,
            @HiveField(1) @JsonKey(name: 'project_id') String projectId,
            @HiveField(2) @JsonKey(name: 'task_id') String? taskId,
            @HiveField(3) String prompt,
            @HiveField(4)
            @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
            Map<String, dynamic> metadata,
            @HiveField(5) @JsonKey(name: 'file_url') String fileUrl,
            @HiveField(6)
            @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
            GeneratedAssetFormat format,
            @HiveField(7) int version,
            @HiveField(8)
            @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
            DateTime createdAt,
            @HiveField(9)
            @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
            DateTime? updatedAt,
            @HiveField(10)
            @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
            GeneratedAssetStatus status)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GeneratedAsset() when $default != null:
        return $default(
            _that.id,
            _that.projectId,
            _that.taskId,
            _that.prompt,
            _that.metadata,
            _that.fileUrl,
            _that.format,
            _that.version,
            _that.createdAt,
            _that.updatedAt,
            _that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GeneratedAsset extends GeneratedAsset {
  const _GeneratedAsset(
      {@HiveField(0) this.id = '',
      @HiveField(1) @JsonKey(name: 'project_id') this.projectId = '',
      @HiveField(2) @JsonKey(name: 'task_id') this.taskId,
      @HiveField(3) this.prompt = '',
      @HiveField(4)
      @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
      final Map<String, dynamic> metadata = const <String, dynamic>{},
      @HiveField(5) @JsonKey(name: 'file_url') this.fileUrl = '',
      @HiveField(6)
      @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
      this.format = GeneratedAssetFormat.glb,
      @HiveField(7) this.version = 1,
      @HiveField(8)
      @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
      required this.createdAt,
      @HiveField(9)
      @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
      this.updatedAt,
      @HiveField(10)
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      this.status = GeneratedAssetStatus.pending})
      : _metadata = metadata,
        super._();
  factory _GeneratedAsset.fromJson(Map<String, dynamic> json) =>
      _$GeneratedAssetFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  @HiveField(2)
  @JsonKey(name: 'task_id')
  final String? taskId;
  @override
  @JsonKey()
  @HiveField(3)
  final String prompt;
  final Map<String, dynamic> _metadata;
  @override
  @HiveField(4)
  @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  @HiveField(5)
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @override
  @HiveField(6)
  @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
  final GeneratedAssetFormat format;
  @override
  @JsonKey()
  @HiveField(7)
  final int version;
  @override
  @HiveField(8)
  @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
  final DateTime createdAt;
  @override
  @HiveField(9)
  @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
  final DateTime? updatedAt;
  @override
  @HiveField(10)
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final GeneratedAssetStatus status;

  /// Create a copy of GeneratedAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GeneratedAssetCopyWith<_GeneratedAsset> get copyWith =>
      __$GeneratedAssetCopyWithImpl<_GeneratedAsset>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GeneratedAssetToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GeneratedAsset &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      projectId,
      taskId,
      prompt,
      const DeepCollectionEquality().hash(_metadata),
      fileUrl,
      format,
      version,
      createdAt,
      updatedAt,
      status);

  @override
  String toString() {
    return 'GeneratedAsset(id: $id, projectId: $projectId, taskId: $taskId, prompt: $prompt, metadata: $metadata, fileUrl: $fileUrl, format: $format, version: $version, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$GeneratedAssetCopyWith<$Res>
    implements $GeneratedAssetCopyWith<$Res> {
  factory _$GeneratedAssetCopyWith(
          _GeneratedAsset value, $Res Function(_GeneratedAsset) _then) =
      __$GeneratedAssetCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) @JsonKey(name: 'project_id') String projectId,
      @HiveField(2) @JsonKey(name: 'task_id') String? taskId,
      @HiveField(3) String prompt,
      @HiveField(4)
      @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
      Map<String, dynamic> metadata,
      @HiveField(5) @JsonKey(name: 'file_url') String fileUrl,
      @HiveField(6)
      @JsonKey(fromJson: _formatFromJson, toJson: _formatToJson)
      GeneratedAssetFormat format,
      @HiveField(7) int version,
      @HiveField(8)
      @JsonKey(name: 'created_at', fromJson: _requiredDateTimeFromJson)
      DateTime createdAt,
      @HiveField(9)
      @JsonKey(name: 'updated_at', fromJson: _optionalDateTimeFromJson)
      DateTime? updatedAt,
      @HiveField(10)
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      GeneratedAssetStatus status});
}

/// @nodoc
class __$GeneratedAssetCopyWithImpl<$Res>
    implements _$GeneratedAssetCopyWith<$Res> {
  __$GeneratedAssetCopyWithImpl(this._self, this._then);

  final _GeneratedAsset _self;
  final $Res Function(_GeneratedAsset) _then;

  /// Create a copy of GeneratedAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? taskId = freezed,
    Object? prompt = null,
    Object? metadata = null,
    Object? fileUrl = null,
    Object? format = null,
    Object? version = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? status = null,
  }) {
    return _then(_GeneratedAsset(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: freezed == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      fileUrl: null == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _self.format
          : format // ignore: cast_nullable_to_non_nullable
              as GeneratedAssetFormat,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as GeneratedAssetStatus,
    ));
  }
}

// dart format on
