// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'requirements.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Requirement {
  String get id;
  String get title;
  @JsonKey(
      fromJson: _requirementStatusFromJson, toJson: _requirementStatusToJson)
  RequirementStatus get status;
  @JsonKey(
      fromJson: _requirementPriorityFromJson,
      toJson: _requirementPriorityToJson)
  RequirementPriority get priority;

  /// Create a copy of Requirement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RequirementCopyWith<Requirement> get copyWith =>
      _$RequirementCopyWithImpl<Requirement>(this as Requirement, _$identity);

  /// Serializes this Requirement to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Requirement &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, status, priority);

  @override
  String toString() {
    return 'Requirement(id: $id, title: $title, status: $status, priority: $priority)';
  }
}

/// @nodoc
abstract mixin class $RequirementCopyWith<$Res> {
  factory $RequirementCopyWith(
          Requirement value, $Res Function(Requirement) _then) =
      _$RequirementCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(
          fromJson: _requirementStatusFromJson,
          toJson: _requirementStatusToJson)
      RequirementStatus status,
      @JsonKey(
          fromJson: _requirementPriorityFromJson,
          toJson: _requirementPriorityToJson)
      RequirementPriority priority});
}

/// @nodoc
class _$RequirementCopyWithImpl<$Res> implements $RequirementCopyWith<$Res> {
  _$RequirementCopyWithImpl(this._self, this._then);

  final Requirement _self;
  final $Res Function(Requirement) _then;

  /// Create a copy of Requirement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? status = null,
    Object? priority = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as RequirementStatus,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as RequirementPriority,
    ));
  }
}

/// Adds pattern-matching-related methods to [Requirement].
extension RequirementPatterns on Requirement {
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
    TResult Function(_Requirement value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Requirement() when $default != null:
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
    TResult Function(_Requirement value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Requirement():
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
    TResult? Function(_Requirement value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Requirement() when $default != null:
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
            String id,
            String title,
            @JsonKey(
                fromJson: _requirementStatusFromJson,
                toJson: _requirementStatusToJson)
            RequirementStatus status,
            @JsonKey(
                fromJson: _requirementPriorityFromJson,
                toJson: _requirementPriorityToJson)
            RequirementPriority priority)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Requirement() when $default != null:
        return $default(_that.id, _that.title, _that.status, _that.priority);
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
            String id,
            String title,
            @JsonKey(
                fromJson: _requirementStatusFromJson,
                toJson: _requirementStatusToJson)
            RequirementStatus status,
            @JsonKey(
                fromJson: _requirementPriorityFromJson,
                toJson: _requirementPriorityToJson)
            RequirementPriority priority)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Requirement():
        return $default(_that.id, _that.title, _that.status, _that.priority);
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
            String id,
            String title,
            @JsonKey(
                fromJson: _requirementStatusFromJson,
                toJson: _requirementStatusToJson)
            RequirementStatus status,
            @JsonKey(
                fromJson: _requirementPriorityFromJson,
                toJson: _requirementPriorityToJson)
            RequirementPriority priority)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Requirement() when $default != null:
        return $default(_that.id, _that.title, _that.status, _that.priority);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Requirement implements Requirement {
  const _Requirement(
      {required this.id,
      required this.title,
      @JsonKey(
          fromJson: _requirementStatusFromJson,
          toJson: _requirementStatusToJson)
      this.status = RequirementStatus.pending,
      @JsonKey(
          fromJson: _requirementPriorityFromJson,
          toJson: _requirementPriorityToJson)
      this.priority = RequirementPriority.medium});
  factory _Requirement.fromJson(Map<String, dynamic> json) =>
      _$RequirementFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(
      fromJson: _requirementStatusFromJson, toJson: _requirementStatusToJson)
  final RequirementStatus status;
  @override
  @JsonKey(
      fromJson: _requirementPriorityFromJson,
      toJson: _requirementPriorityToJson)
  final RequirementPriority priority;

  /// Create a copy of Requirement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RequirementCopyWith<_Requirement> get copyWith =>
      __$RequirementCopyWithImpl<_Requirement>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RequirementToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Requirement &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, status, priority);

  @override
  String toString() {
    return 'Requirement(id: $id, title: $title, status: $status, priority: $priority)';
  }
}

/// @nodoc
abstract mixin class _$RequirementCopyWith<$Res>
    implements $RequirementCopyWith<$Res> {
  factory _$RequirementCopyWith(
          _Requirement value, $Res Function(_Requirement) _then) =
      __$RequirementCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(
          fromJson: _requirementStatusFromJson,
          toJson: _requirementStatusToJson)
      RequirementStatus status,
      @JsonKey(
          fromJson: _requirementPriorityFromJson,
          toJson: _requirementPriorityToJson)
      RequirementPriority priority});
}

/// @nodoc
class __$RequirementCopyWithImpl<$Res> implements _$RequirementCopyWith<$Res> {
  __$RequirementCopyWithImpl(this._self, this._then);

  final _Requirement _self;
  final $Res Function(_Requirement) _then;

  /// Create a copy of Requirement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? status = null,
    Object? priority = null,
  }) {
    return _then(_Requirement(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as RequirementStatus,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as RequirementPriority,
    ));
  }
}

// dart format on
