// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_transfer_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectTransferResult {
  String get projectsPath;
  String get tasksPath;

  /// Create a copy of ProjectTransferResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectTransferResultCopyWith<ProjectTransferResult> get copyWith =>
      _$ProjectTransferResultCopyWithImpl<ProjectTransferResult>(
          this as ProjectTransferResult, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectTransferResult &&
            (identical(other.projectsPath, projectsPath) ||
                other.projectsPath == projectsPath) &&
            (identical(other.tasksPath, tasksPath) ||
                other.tasksPath == tasksPath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, projectsPath, tasksPath);

  @override
  String toString() {
    return 'ProjectTransferResult(projectsPath: $projectsPath, tasksPath: $tasksPath)';
  }
}

/// @nodoc
abstract mixin class $ProjectTransferResultCopyWith<$Res> {
  factory $ProjectTransferResultCopyWith(ProjectTransferResult value,
          $Res Function(ProjectTransferResult) _then) =
      _$ProjectTransferResultCopyWithImpl;
  @useResult
  $Res call({String projectsPath, String tasksPath});
}

/// @nodoc
class _$ProjectTransferResultCopyWithImpl<$Res>
    implements $ProjectTransferResultCopyWith<$Res> {
  _$ProjectTransferResultCopyWithImpl(this._self, this._then);

  final ProjectTransferResult _self;
  final $Res Function(ProjectTransferResult) _then;

  /// Create a copy of ProjectTransferResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectsPath = null,
    Object? tasksPath = null,
  }) {
    return _then(_self.copyWith(
      projectsPath: null == projectsPath
          ? _self.projectsPath
          : projectsPath // ignore: cast_nullable_to_non_nullable
              as String,
      tasksPath: null == tasksPath
          ? _self.tasksPath
          : tasksPath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectTransferResult].
extension ProjectTransferResultPatterns on ProjectTransferResult {
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
    TResult Function(_ProjectTransferResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectTransferResult() when $default != null:
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
    TResult Function(_ProjectTransferResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectTransferResult():
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
    TResult? Function(_ProjectTransferResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectTransferResult() when $default != null:
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
    TResult Function(String projectsPath, String tasksPath)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectTransferResult() when $default != null:
        return $default(_that.projectsPath, _that.tasksPath);
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
    TResult Function(String projectsPath, String tasksPath) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectTransferResult():
        return $default(_that.projectsPath, _that.tasksPath);
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
    TResult? Function(String projectsPath, String tasksPath)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectTransferResult() when $default != null:
        return $default(_that.projectsPath, _that.tasksPath);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectTransferResult implements ProjectTransferResult {
  const _ProjectTransferResult(
      {required this.projectsPath, required this.tasksPath});

  @override
  final String projectsPath;
  @override
  final String tasksPath;

  /// Create a copy of ProjectTransferResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectTransferResultCopyWith<_ProjectTransferResult> get copyWith =>
      __$ProjectTransferResultCopyWithImpl<_ProjectTransferResult>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectTransferResult &&
            (identical(other.projectsPath, projectsPath) ||
                other.projectsPath == projectsPath) &&
            (identical(other.tasksPath, tasksPath) ||
                other.tasksPath == tasksPath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, projectsPath, tasksPath);

  @override
  String toString() {
    return 'ProjectTransferResult(projectsPath: $projectsPath, tasksPath: $tasksPath)';
  }
}

/// @nodoc
abstract mixin class _$ProjectTransferResultCopyWith<$Res>
    implements $ProjectTransferResultCopyWith<$Res> {
  factory _$ProjectTransferResultCopyWith(_ProjectTransferResult value,
          $Res Function(_ProjectTransferResult) _then) =
      __$ProjectTransferResultCopyWithImpl;
  @override
  @useResult
  $Res call({String projectsPath, String tasksPath});
}

/// @nodoc
class __$ProjectTransferResultCopyWithImpl<$Res>
    implements _$ProjectTransferResultCopyWith<$Res> {
  __$ProjectTransferResultCopyWithImpl(this._self, this._then);

  final _ProjectTransferResult _self;
  final $Res Function(_ProjectTransferResult) _then;

  /// Create a copy of ProjectTransferResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? projectsPath = null,
    Object? tasksPath = null,
  }) {
    return _then(_ProjectTransferResult(
      projectsPath: null == projectsPath
          ? _self.projectsPath
          : projectsPath // ignore: cast_nullable_to_non_nullable
              as String,
      tasksPath: null == tasksPath
          ? _self.tasksPath
          : tasksPath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
