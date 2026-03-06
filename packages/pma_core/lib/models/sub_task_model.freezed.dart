// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sub_task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubTask {
  @HiveField(0)
  String get id;
  @HiveField(1)
  String get taskId;
  @HiveField(2)
  String get title;
  @HiveField(3)
  String get description;
  @HiveField(4)
  bool get isCompleted;
  @HiveField(5)
  String? get assignedTo;
  @HiveField(6)
  DateTime get createdAt;

  /// Create a copy of SubTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SubTaskCopyWith<SubTask> get copyWith =>
      _$SubTaskCopyWithImpl<SubTask>(this as SubTask, _$identity);

  /// Serializes this SubTask to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SubTask &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, taskId, title, description,
      isCompleted, assignedTo, createdAt);

  @override
  String toString() {
    return 'SubTask(id: $id, taskId: $taskId, title: $title, description: $description, isCompleted: $isCompleted, assignedTo: $assignedTo, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $SubTaskCopyWith<$Res> {
  factory $SubTaskCopyWith(SubTask value, $Res Function(SubTask) _then) =
      _$SubTaskCopyWithImpl;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String taskId,
      @HiveField(2) String title,
      @HiveField(3) String description,
      @HiveField(4) bool isCompleted,
      @HiveField(5) String? assignedTo,
      @HiveField(6) DateTime createdAt});
}

/// @nodoc
class _$SubTaskCopyWithImpl<$Res> implements $SubTaskCopyWith<$Res> {
  _$SubTaskCopyWithImpl(this._self, this._then);

  final SubTask _self;
  final $Res Function(SubTask) _then;

  /// Create a copy of SubTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? title = null,
    Object? description = null,
    Object? isCompleted = null,
    Object? assignedTo = freezed,
    Object? createdAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      assignedTo: freezed == assignedTo
          ? _self.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [SubTask].
extension SubTaskPatterns on SubTask {
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
    TResult Function(_SubTask value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubTask() when $default != null:
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
    TResult Function(_SubTask value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubTask():
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
    TResult? Function(_SubTask value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubTask() when $default != null:
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
            @HiveField(1) String taskId,
            @HiveField(2) String title,
            @HiveField(3) String description,
            @HiveField(4) bool isCompleted,
            @HiveField(5) String? assignedTo,
            @HiveField(6) DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubTask() when $default != null:
        return $default(_that.id, _that.taskId, _that.title, _that.description,
            _that.isCompleted, _that.assignedTo, _that.createdAt);
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
            @HiveField(1) String taskId,
            @HiveField(2) String title,
            @HiveField(3) String description,
            @HiveField(4) bool isCompleted,
            @HiveField(5) String? assignedTo,
            @HiveField(6) DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubTask():
        return $default(_that.id, _that.taskId, _that.title, _that.description,
            _that.isCompleted, _that.assignedTo, _that.createdAt);
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
            @HiveField(1) String taskId,
            @HiveField(2) String title,
            @HiveField(3) String description,
            @HiveField(4) bool isCompleted,
            @HiveField(5) String? assignedTo,
            @HiveField(6) DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubTask() when $default != null:
        return $default(_that.id, _that.taskId, _that.title, _that.description,
            _that.isCompleted, _that.assignedTo, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SubTask implements SubTask {
  const _SubTask(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.taskId,
      @HiveField(2) required this.title,
      @HiveField(3) required this.description,
      @HiveField(4) this.isCompleted = false,
      @HiveField(5) this.assignedTo,
      @HiveField(6) required this.createdAt});
  factory _SubTask.fromJson(Map<String, dynamic> json) =>
      _$SubTaskFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String taskId;
  @override
  @HiveField(2)
  final String title;
  @override
  @HiveField(3)
  final String description;
  @override
  @JsonKey()
  @HiveField(4)
  final bool isCompleted;
  @override
  @HiveField(5)
  final String? assignedTo;
  @override
  @HiveField(6)
  final DateTime createdAt;

  /// Create a copy of SubTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SubTaskCopyWith<_SubTask> get copyWith =>
      __$SubTaskCopyWithImpl<_SubTask>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SubTaskToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SubTask &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, taskId, title, description,
      isCompleted, assignedTo, createdAt);

  @override
  String toString() {
    return 'SubTask(id: $id, taskId: $taskId, title: $title, description: $description, isCompleted: $isCompleted, assignedTo: $assignedTo, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$SubTaskCopyWith<$Res> implements $SubTaskCopyWith<$Res> {
  factory _$SubTaskCopyWith(_SubTask value, $Res Function(_SubTask) _then) =
      __$SubTaskCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String taskId,
      @HiveField(2) String title,
      @HiveField(3) String description,
      @HiveField(4) bool isCompleted,
      @HiveField(5) String? assignedTo,
      @HiveField(6) DateTime createdAt});
}

/// @nodoc
class __$SubTaskCopyWithImpl<$Res> implements _$SubTaskCopyWith<$Res> {
  __$SubTaskCopyWithImpl(this._self, this._then);

  final _SubTask _self;
  final $Res Function(_SubTask) _then;

  /// Create a copy of SubTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? title = null,
    Object? description = null,
    Object? isCompleted = null,
    Object? assignedTo = freezed,
    Object? createdAt = null,
  }) {
    return _then(_SubTask(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      assignedTo: freezed == assignedTo
          ? _self.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
