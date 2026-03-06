// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectMeta {
  String get projectId;
  UrgencyLevel get urgency;
  int get trackedSeconds;

  /// Create a copy of ProjectMeta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectMetaCopyWith<ProjectMeta> get copyWith =>
      _$ProjectMetaCopyWithImpl<ProjectMeta>(this as ProjectMeta, _$identity);

  /// Serializes this ProjectMeta to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectMeta &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.trackedSeconds, trackedSeconds) ||
                other.trackedSeconds == trackedSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, projectId, urgency, trackedSeconds);

  @override
  String toString() {
    return 'ProjectMeta(projectId: $projectId, urgency: $urgency, trackedSeconds: $trackedSeconds)';
  }
}

/// @nodoc
abstract mixin class $ProjectMetaCopyWith<$Res> {
  factory $ProjectMetaCopyWith(
          ProjectMeta value, $Res Function(ProjectMeta) _then) =
      _$ProjectMetaCopyWithImpl;
  @useResult
  $Res call({String projectId, UrgencyLevel urgency, int trackedSeconds});
}

/// @nodoc
class _$ProjectMetaCopyWithImpl<$Res> implements $ProjectMetaCopyWith<$Res> {
  _$ProjectMetaCopyWithImpl(this._self, this._then);

  final ProjectMeta _self;
  final $Res Function(ProjectMeta) _then;

  /// Create a copy of ProjectMeta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectId = null,
    Object? urgency = null,
    Object? trackedSeconds = null,
  }) {
    return _then(_self.copyWith(
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      urgency: null == urgency
          ? _self.urgency
          : urgency // ignore: cast_nullable_to_non_nullable
              as UrgencyLevel,
      trackedSeconds: null == trackedSeconds
          ? _self.trackedSeconds
          : trackedSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectMeta].
extension ProjectMetaPatterns on ProjectMeta {
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
    TResult Function(_ProjectMeta value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectMeta() when $default != null:
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
    TResult Function(_ProjectMeta value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectMeta():
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
    TResult? Function(_ProjectMeta value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectMeta() when $default != null:
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
            String projectId, UrgencyLevel urgency, int trackedSeconds)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectMeta() when $default != null:
        return $default(_that.projectId, _that.urgency, _that.trackedSeconds);
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
    TResult Function(String projectId, UrgencyLevel urgency, int trackedSeconds)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectMeta():
        return $default(_that.projectId, _that.urgency, _that.trackedSeconds);
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
            String projectId, UrgencyLevel urgency, int trackedSeconds)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectMeta() when $default != null:
        return $default(_that.projectId, _that.urgency, _that.trackedSeconds);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProjectMeta extends ProjectMeta {
  const _ProjectMeta(
      {required this.projectId,
      required this.urgency,
      required this.trackedSeconds})
      : super._();
  factory _ProjectMeta.fromJson(Map<String, dynamic> json) =>
      _$ProjectMetaFromJson(json);

  @override
  final String projectId;
  @override
  final UrgencyLevel urgency;
  @override
  final int trackedSeconds;

  /// Create a copy of ProjectMeta
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectMetaCopyWith<_ProjectMeta> get copyWith =>
      __$ProjectMetaCopyWithImpl<_ProjectMeta>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectMetaToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectMeta &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.trackedSeconds, trackedSeconds) ||
                other.trackedSeconds == trackedSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, projectId, urgency, trackedSeconds);

  @override
  String toString() {
    return 'ProjectMeta(projectId: $projectId, urgency: $urgency, trackedSeconds: $trackedSeconds)';
  }
}

/// @nodoc
abstract mixin class _$ProjectMetaCopyWith<$Res>
    implements $ProjectMetaCopyWith<$Res> {
  factory _$ProjectMetaCopyWith(
          _ProjectMeta value, $Res Function(_ProjectMeta) _then) =
      __$ProjectMetaCopyWithImpl;
  @override
  @useResult
  $Res call({String projectId, UrgencyLevel urgency, int trackedSeconds});
}

/// @nodoc
class __$ProjectMetaCopyWithImpl<$Res> implements _$ProjectMetaCopyWith<$Res> {
  __$ProjectMetaCopyWithImpl(this._self, this._then);

  final _ProjectMeta _self;
  final $Res Function(_ProjectMeta) _then;

  /// Create a copy of ProjectMeta
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? projectId = null,
    Object? urgency = null,
    Object? trackedSeconds = null,
  }) {
    return _then(_ProjectMeta(
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      urgency: null == urgency
          ? _self.urgency
          : urgency // ignore: cast_nullable_to_non_nullable
              as UrgencyLevel,
      trackedSeconds: null == trackedSeconds
          ? _self.trackedSeconds
          : trackedSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
