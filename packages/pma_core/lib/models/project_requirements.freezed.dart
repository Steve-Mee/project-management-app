// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_requirements.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectRequirements {
  List<String> get software;
  List<String> get hardware;

  /// Create a copy of ProjectRequirements
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectRequirementsCopyWith<ProjectRequirements> get copyWith =>
      _$ProjectRequirementsCopyWithImpl<ProjectRequirements>(
          this as ProjectRequirements, _$identity);

  /// Serializes this ProjectRequirements to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectRequirements &&
            const DeepCollectionEquality().equals(other.software, software) &&
            const DeepCollectionEquality().equals(other.hardware, hardware));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(software),
      const DeepCollectionEquality().hash(hardware));

  @override
  String toString() {
    return 'ProjectRequirements(software: $software, hardware: $hardware)';
  }
}

/// @nodoc
abstract mixin class $ProjectRequirementsCopyWith<$Res> {
  factory $ProjectRequirementsCopyWith(
          ProjectRequirements value, $Res Function(ProjectRequirements) _then) =
      _$ProjectRequirementsCopyWithImpl;
  @useResult
  $Res call({List<String> software, List<String> hardware});
}

/// @nodoc
class _$ProjectRequirementsCopyWithImpl<$Res>
    implements $ProjectRequirementsCopyWith<$Res> {
  _$ProjectRequirementsCopyWithImpl(this._self, this._then);

  final ProjectRequirements _self;
  final $Res Function(ProjectRequirements) _then;

  /// Create a copy of ProjectRequirements
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? software = null,
    Object? hardware = null,
  }) {
    return _then(_self.copyWith(
      software: null == software
          ? _self.software
          : software // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hardware: null == hardware
          ? _self.hardware
          : hardware // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectRequirements].
extension ProjectRequirementsPatterns on ProjectRequirements {
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
    TResult Function(_ProjectRequirements value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectRequirements() when $default != null:
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
    TResult Function(_ProjectRequirements value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectRequirements():
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
    TResult? Function(_ProjectRequirements value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectRequirements() when $default != null:
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
    TResult Function(List<String> software, List<String> hardware)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectRequirements() when $default != null:
        return $default(_that.software, _that.hardware);
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
    TResult Function(List<String> software, List<String> hardware) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectRequirements():
        return $default(_that.software, _that.hardware);
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
    TResult? Function(List<String> software, List<String> hardware)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectRequirements() when $default != null:
        return $default(_that.software, _that.hardware);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProjectRequirements extends ProjectRequirements {
  const _ProjectRequirements(
      {final List<String> software = const <String>[],
      final List<String> hardware = const <String>[]})
      : _software = software,
        _hardware = hardware,
        super._();
  factory _ProjectRequirements.fromJson(Map<String, dynamic> json) =>
      _$ProjectRequirementsFromJson(json);

  final List<String> _software;
  @override
  @JsonKey()
  List<String> get software {
    if (_software is EqualUnmodifiableListView) return _software;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_software);
  }

  final List<String> _hardware;
  @override
  @JsonKey()
  List<String> get hardware {
    if (_hardware is EqualUnmodifiableListView) return _hardware;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hardware);
  }

  /// Create a copy of ProjectRequirements
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectRequirementsCopyWith<_ProjectRequirements> get copyWith =>
      __$ProjectRequirementsCopyWithImpl<_ProjectRequirements>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectRequirementsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectRequirements &&
            const DeepCollectionEquality().equals(other._software, _software) &&
            const DeepCollectionEquality().equals(other._hardware, _hardware));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_software),
      const DeepCollectionEquality().hash(_hardware));

  @override
  String toString() {
    return 'ProjectRequirements(software: $software, hardware: $hardware)';
  }
}

/// @nodoc
abstract mixin class _$ProjectRequirementsCopyWith<$Res>
    implements $ProjectRequirementsCopyWith<$Res> {
  factory _$ProjectRequirementsCopyWith(_ProjectRequirements value,
          $Res Function(_ProjectRequirements) _then) =
      __$ProjectRequirementsCopyWithImpl;
  @override
  @useResult
  $Res call({List<String> software, List<String> hardware});
}

/// @nodoc
class __$ProjectRequirementsCopyWithImpl<$Res>
    implements _$ProjectRequirementsCopyWith<$Res> {
  __$ProjectRequirementsCopyWithImpl(this._self, this._then);

  final _ProjectRequirements _self;
  final $Res Function(_ProjectRequirements) _then;

  /// Create a copy of ProjectRequirements
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? software = null,
    Object? hardware = null,
  }) {
    return _then(_ProjectRequirements(
      software: null == software
          ? _self._software
          : software // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hardware: null == hardware
          ? _self._hardware
          : hardware // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
