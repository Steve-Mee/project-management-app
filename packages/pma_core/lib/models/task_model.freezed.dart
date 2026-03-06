// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {
  @HiveField(0)
  String get id;
  @HiveField(1)
  String get projectId;
  @HiveField(2)
  String get title;
  @HiveField(3)
  String get description;
  @HiveField(4)
  @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
  TaskStatus get status;
  @HiveField(5)
  String get assignee;
  @HiveField(6)
  @JsonKey(fromJson: _createdAtFromJson)
  DateTime get createdAt;
  @HiveField(7)
  @JsonKey(fromJson: _dueDateFromJson)
  DateTime? get dueDate;
  @HiveField(8)
  double get priority;
  @HiveField(9)
  @JsonKey(
      readValue: _readAttachments,
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson)
  List<String> get attachments;
  @HiveField(10)
  List<String> get subTaskIds;
  @HiveField(11)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get userId;
  @HiveField(12)
  List<CommentModel> get comments;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TaskCopyWith<Task> get copyWith =>
      _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Task &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignee, assignee) ||
                other.assignee == assignee) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            const DeepCollectionEquality()
                .equals(other.attachments, attachments) &&
            const DeepCollectionEquality()
                .equals(other.subTaskIds, subTaskIds) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other.comments, comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      projectId,
      title,
      description,
      status,
      assignee,
      createdAt,
      dueDate,
      priority,
      const DeepCollectionEquality().hash(attachments),
      const DeepCollectionEquality().hash(subTaskIds),
      userId,
      const DeepCollectionEquality().hash(comments));

  @override
  String toString() {
    return 'Task(id: $id, projectId: $projectId, title: $title, description: $description, status: $status, assignee: $assignee, createdAt: $createdAt, dueDate: $dueDate, priority: $priority, attachments: $attachments, subTaskIds: $subTaskIds, userId: $userId, comments: $comments)';
  }
}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) =
      _$TaskCopyWithImpl;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String projectId,
      @HiveField(2) String title,
      @HiveField(3) String description,
      @HiveField(4)
      @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
      TaskStatus status,
      @HiveField(5) String assignee,
      @HiveField(6) @JsonKey(fromJson: _createdAtFromJson) DateTime createdAt,
      @HiveField(7) @JsonKey(fromJson: _dueDateFromJson) DateTime? dueDate,
      @HiveField(8) double priority,
      @HiveField(9)
      @JsonKey(
          readValue: _readAttachments,
          fromJson: _attachmentsFromJson,
          toJson: _attachmentsToJson)
      List<String> attachments,
      @HiveField(10) List<String> subTaskIds,
      @HiveField(11)
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? userId,
      @HiveField(12) List<CommentModel> comments});
}

/// @nodoc
class _$TaskCopyWithImpl<$Res> implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? description = null,
    Object? status = null,
    Object? assignee = null,
    Object? createdAt = null,
    Object? dueDate = freezed,
    Object? priority = null,
    Object? attachments = null,
    Object? subTaskIds = null,
    Object? userId = freezed,
    Object? comments = null,
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
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      assignee: null == assignee
          ? _self.assignee
          : assignee // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dueDate: freezed == dueDate
          ? _self.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as double,
      attachments: null == attachments
          ? _self.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subTaskIds: null == subTaskIds
          ? _self.subTaskIds
          : subTaskIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      comments: null == comments
          ? _self.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
    ));
  }
}

/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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
    TResult Function(_Task value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
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
    TResult Function(_Task value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task():
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
    TResult? Function(_Task value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
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
            @HiveField(1) String projectId,
            @HiveField(2) String title,
            @HiveField(3) String description,
            @HiveField(4)
            @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
            TaskStatus status,
            @HiveField(5) String assignee,
            @HiveField(6)
            @JsonKey(fromJson: _createdAtFromJson)
            DateTime createdAt,
            @HiveField(7)
            @JsonKey(fromJson: _dueDateFromJson)
            DateTime? dueDate,
            @HiveField(8) double priority,
            @HiveField(9)
            @JsonKey(
                readValue: _readAttachments,
                fromJson: _attachmentsFromJson,
                toJson: _attachmentsToJson)
            List<String> attachments,
            @HiveField(10) List<String> subTaskIds,
            @HiveField(11)
            @JsonKey(includeFromJson: false, includeToJson: false)
            String? userId,
            @HiveField(12) List<CommentModel> comments)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
        return $default(
            _that.id,
            _that.projectId,
            _that.title,
            _that.description,
            _that.status,
            _that.assignee,
            _that.createdAt,
            _that.dueDate,
            _that.priority,
            _that.attachments,
            _that.subTaskIds,
            _that.userId,
            _that.comments);
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
            @HiveField(1) String projectId,
            @HiveField(2) String title,
            @HiveField(3) String description,
            @HiveField(4)
            @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
            TaskStatus status,
            @HiveField(5) String assignee,
            @HiveField(6)
            @JsonKey(fromJson: _createdAtFromJson)
            DateTime createdAt,
            @HiveField(7)
            @JsonKey(fromJson: _dueDateFromJson)
            DateTime? dueDate,
            @HiveField(8) double priority,
            @HiveField(9)
            @JsonKey(
                readValue: _readAttachments,
                fromJson: _attachmentsFromJson,
                toJson: _attachmentsToJson)
            List<String> attachments,
            @HiveField(10) List<String> subTaskIds,
            @HiveField(11)
            @JsonKey(includeFromJson: false, includeToJson: false)
            String? userId,
            @HiveField(12) List<CommentModel> comments)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task():
        return $default(
            _that.id,
            _that.projectId,
            _that.title,
            _that.description,
            _that.status,
            _that.assignee,
            _that.createdAt,
            _that.dueDate,
            _that.priority,
            _that.attachments,
            _that.subTaskIds,
            _that.userId,
            _that.comments);
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
            @HiveField(1) String projectId,
            @HiveField(2) String title,
            @HiveField(3) String description,
            @HiveField(4)
            @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
            TaskStatus status,
            @HiveField(5) String assignee,
            @HiveField(6)
            @JsonKey(fromJson: _createdAtFromJson)
            DateTime createdAt,
            @HiveField(7)
            @JsonKey(fromJson: _dueDateFromJson)
            DateTime? dueDate,
            @HiveField(8) double priority,
            @HiveField(9)
            @JsonKey(
                readValue: _readAttachments,
                fromJson: _attachmentsFromJson,
                toJson: _attachmentsToJson)
            List<String> attachments,
            @HiveField(10) List<String> subTaskIds,
            @HiveField(11)
            @JsonKey(includeFromJson: false, includeToJson: false)
            String? userId,
            @HiveField(12) List<CommentModel> comments)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Task() when $default != null:
        return $default(
            _that.id,
            _that.projectId,
            _that.title,
            _that.description,
            _that.status,
            _that.assignee,
            _that.createdAt,
            _that.dueDate,
            _that.priority,
            _that.attachments,
            _that.subTaskIds,
            _that.userId,
            _that.comments);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Task extends Task {
  const _Task(
      {@HiveField(0) this.id = '',
      @HiveField(1) this.projectId = '',
      @HiveField(2) this.title = '',
      @HiveField(3) this.description = '',
      @HiveField(4)
      @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
      this.status = TaskStatus.todo,
      @HiveField(5) this.assignee = '',
      @HiveField(6)
      @JsonKey(fromJson: _createdAtFromJson)
      required this.createdAt,
      @HiveField(7) @JsonKey(fromJson: _dueDateFromJson) this.dueDate,
      @HiveField(8) this.priority = 0.5,
      @HiveField(9)
      @JsonKey(
          readValue: _readAttachments,
          fromJson: _attachmentsFromJson,
          toJson: _attachmentsToJson)
      final List<String> attachments = const <String>[],
      @HiveField(10) final List<String> subTaskIds = const <String>[],
      @HiveField(11)
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.userId,
      @HiveField(12)
      final List<CommentModel> comments = const <CommentModel>[]})
      : _attachments = attachments,
        _subTaskIds = subTaskIds,
        _comments = comments,
        super._();
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final String id;
  @override
  @JsonKey()
  @HiveField(1)
  final String projectId;
  @override
  @JsonKey()
  @HiveField(2)
  final String title;
  @override
  @JsonKey()
  @HiveField(3)
  final String description;
  @override
  @HiveField(4)
  @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
  final TaskStatus status;
  @override
  @JsonKey()
  @HiveField(5)
  final String assignee;
  @override
  @HiveField(6)
  @JsonKey(fromJson: _createdAtFromJson)
  final DateTime createdAt;
  @override
  @HiveField(7)
  @JsonKey(fromJson: _dueDateFromJson)
  final DateTime? dueDate;
  @override
  @JsonKey()
  @HiveField(8)
  final double priority;
  final List<String> _attachments;
  @override
  @HiveField(9)
  @JsonKey(
      readValue: _readAttachments,
      fromJson: _attachmentsFromJson,
      toJson: _attachmentsToJson)
  List<String> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  final List<String> _subTaskIds;
  @override
  @JsonKey()
  @HiveField(10)
  List<String> get subTaskIds {
    if (_subTaskIds is EqualUnmodifiableListView) return _subTaskIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subTaskIds);
  }

  @override
  @HiveField(11)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? userId;
  final List<CommentModel> _comments;
  @override
  @JsonKey()
  @HiveField(12)
  List<CommentModel> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TaskCopyWith<_Task> get copyWith =>
      __$TaskCopyWithImpl<_Task>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TaskToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Task &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignee, assignee) ||
                other.assignee == assignee) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            const DeepCollectionEquality()
                .equals(other._subTaskIds, _subTaskIds) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._comments, _comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      projectId,
      title,
      description,
      status,
      assignee,
      createdAt,
      dueDate,
      priority,
      const DeepCollectionEquality().hash(_attachments),
      const DeepCollectionEquality().hash(_subTaskIds),
      userId,
      const DeepCollectionEquality().hash(_comments));

  @override
  String toString() {
    return 'Task(id: $id, projectId: $projectId, title: $title, description: $description, status: $status, assignee: $assignee, createdAt: $createdAt, dueDate: $dueDate, priority: $priority, attachments: $attachments, subTaskIds: $subTaskIds, userId: $userId, comments: $comments)';
  }
}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) =
      __$TaskCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String projectId,
      @HiveField(2) String title,
      @HiveField(3) String description,
      @HiveField(4)
      @JsonKey(fromJson: _taskStatusFromJson, toJson: _taskStatusToJson)
      TaskStatus status,
      @HiveField(5) String assignee,
      @HiveField(6) @JsonKey(fromJson: _createdAtFromJson) DateTime createdAt,
      @HiveField(7) @JsonKey(fromJson: _dueDateFromJson) DateTime? dueDate,
      @HiveField(8) double priority,
      @HiveField(9)
      @JsonKey(
          readValue: _readAttachments,
          fromJson: _attachmentsFromJson,
          toJson: _attachmentsToJson)
      List<String> attachments,
      @HiveField(10) List<String> subTaskIds,
      @HiveField(11)
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? userId,
      @HiveField(12) List<CommentModel> comments});
}

/// @nodoc
class __$TaskCopyWithImpl<$Res> implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? description = null,
    Object? status = null,
    Object? assignee = null,
    Object? createdAt = null,
    Object? dueDate = freezed,
    Object? priority = null,
    Object? attachments = null,
    Object? subTaskIds = null,
    Object? userId = freezed,
    Object? comments = null,
  }) {
    return _then(_Task(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      assignee: null == assignee
          ? _self.assignee
          : assignee // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dueDate: freezed == dueDate
          ? _self.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as double,
      attachments: null == attachments
          ? _self._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subTaskIds: null == subTaskIds
          ? _self._subTaskIds
          : subTaskIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      comments: null == comments
          ? _self._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
    ));
  }
}

// dart format on
