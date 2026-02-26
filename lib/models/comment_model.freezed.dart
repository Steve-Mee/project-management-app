// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentModel {
  @HiveField(0)
  String get id;
  @HiveField(1)
  String get userId;
  @HiveField(2)
  String? get projectId;
  @HiveField(3)
  String? get taskId;
  @HiveField(4)
  String get text;
  @HiveField(5)
  DateTime get createdAt;
  @HiveField(6)
  List<String> get mentionedUsers;
  @HiveField(7)
  bool get isEdited;
  @HiveField(8)
  DateTime? get editedAt;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CommentModelCopyWith<CommentModel> get copyWith =>
      _$CommentModelCopyWithImpl<CommentModel>(
          this as CommentModel, _$identity);

  /// Serializes this CommentModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CommentModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality()
                .equals(other.mentionedUsers, mentionedUsers) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      projectId,
      taskId,
      text,
      createdAt,
      const DeepCollectionEquality().hash(mentionedUsers),
      isEdited,
      editedAt);

  @override
  String toString() {
    return 'CommentModel(id: $id, userId: $userId, projectId: $projectId, taskId: $taskId, text: $text, createdAt: $createdAt, mentionedUsers: $mentionedUsers, isEdited: $isEdited, editedAt: $editedAt)';
  }
}

/// @nodoc
abstract mixin class $CommentModelCopyWith<$Res> {
  factory $CommentModelCopyWith(
          CommentModel value, $Res Function(CommentModel) _then) =
      _$CommentModelCopyWithImpl;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) String? projectId,
      @HiveField(3) String? taskId,
      @HiveField(4) String text,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) List<String> mentionedUsers,
      @HiveField(7) bool isEdited,
      @HiveField(8) DateTime? editedAt});
}

/// @nodoc
class _$CommentModelCopyWithImpl<$Res> implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._self, this._then);

  final CommentModel _self;
  final $Res Function(CommentModel) _then;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? projectId = freezed,
    Object? taskId = freezed,
    Object? text = null,
    Object? createdAt = null,
    Object? mentionedUsers = null,
    Object? isEdited = null,
    Object? editedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      taskId: freezed == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mentionedUsers: null == mentionedUsers
          ? _self.mentionedUsers
          : mentionedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isEdited: null == isEdited
          ? _self.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      editedAt: freezed == editedAt
          ? _self.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CommentModel].
extension CommentModelPatterns on CommentModel {
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
    TResult Function(_CommentModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CommentModel() when $default != null:
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
    TResult Function(_CommentModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommentModel():
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
    TResult? Function(_CommentModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommentModel() when $default != null:
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
            @HiveField(1) String userId,
            @HiveField(2) String? projectId,
            @HiveField(3) String? taskId,
            @HiveField(4) String text,
            @HiveField(5) DateTime createdAt,
            @HiveField(6) List<String> mentionedUsers,
            @HiveField(7) bool isEdited,
            @HiveField(8) DateTime? editedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CommentModel() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.projectId,
            _that.taskId,
            _that.text,
            _that.createdAt,
            _that.mentionedUsers,
            _that.isEdited,
            _that.editedAt);
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
            @HiveField(1) String userId,
            @HiveField(2) String? projectId,
            @HiveField(3) String? taskId,
            @HiveField(4) String text,
            @HiveField(5) DateTime createdAt,
            @HiveField(6) List<String> mentionedUsers,
            @HiveField(7) bool isEdited,
            @HiveField(8) DateTime? editedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommentModel():
        return $default(
            _that.id,
            _that.userId,
            _that.projectId,
            _that.taskId,
            _that.text,
            _that.createdAt,
            _that.mentionedUsers,
            _that.isEdited,
            _that.editedAt);
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
            @HiveField(1) String userId,
            @HiveField(2) String? projectId,
            @HiveField(3) String? taskId,
            @HiveField(4) String text,
            @HiveField(5) DateTime createdAt,
            @HiveField(6) List<String> mentionedUsers,
            @HiveField(7) bool isEdited,
            @HiveField(8) DateTime? editedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CommentModel() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.projectId,
            _that.taskId,
            _that.text,
            _that.createdAt,
            _that.mentionedUsers,
            _that.isEdited,
            _that.editedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _CommentModel extends CommentModel {
  const _CommentModel(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.userId,
      @HiveField(2) this.projectId,
      @HiveField(3) this.taskId,
      @HiveField(4) required this.text,
      @HiveField(5) required this.createdAt,
      @HiveField(6) final List<String> mentionedUsers = const <String>[],
      @HiveField(7) this.isEdited = false,
      @HiveField(8) this.editedAt})
      : _mentionedUsers = mentionedUsers,
        super._();
  factory _CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String userId;
  @override
  @HiveField(2)
  final String? projectId;
  @override
  @HiveField(3)
  final String? taskId;
  @override
  @HiveField(4)
  final String text;
  @override
  @HiveField(5)
  final DateTime createdAt;
  final List<String> _mentionedUsers;
  @override
  @JsonKey()
  @HiveField(6)
  List<String> get mentionedUsers {
    if (_mentionedUsers is EqualUnmodifiableListView) return _mentionedUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mentionedUsers);
  }

  @override
  @JsonKey()
  @HiveField(7)
  final bool isEdited;
  @override
  @HiveField(8)
  final DateTime? editedAt;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CommentModelCopyWith<_CommentModel> get copyWith =>
      __$CommentModelCopyWithImpl<_CommentModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CommentModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CommentModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality()
                .equals(other._mentionedUsers, _mentionedUsers) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      projectId,
      taskId,
      text,
      createdAt,
      const DeepCollectionEquality().hash(_mentionedUsers),
      isEdited,
      editedAt);

  @override
  String toString() {
    return 'CommentModel(id: $id, userId: $userId, projectId: $projectId, taskId: $taskId, text: $text, createdAt: $createdAt, mentionedUsers: $mentionedUsers, isEdited: $isEdited, editedAt: $editedAt)';
  }
}

/// @nodoc
abstract mixin class _$CommentModelCopyWith<$Res>
    implements $CommentModelCopyWith<$Res> {
  factory _$CommentModelCopyWith(
          _CommentModel value, $Res Function(_CommentModel) _then) =
      __$CommentModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) String? projectId,
      @HiveField(3) String? taskId,
      @HiveField(4) String text,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) List<String> mentionedUsers,
      @HiveField(7) bool isEdited,
      @HiveField(8) DateTime? editedAt});
}

/// @nodoc
class __$CommentModelCopyWithImpl<$Res>
    implements _$CommentModelCopyWith<$Res> {
  __$CommentModelCopyWithImpl(this._self, this._then);

  final _CommentModel _self;
  final $Res Function(_CommentModel) _then;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? projectId = freezed,
    Object? taskId = freezed,
    Object? text = null,
    Object? createdAt = null,
    Object? mentionedUsers = null,
    Object? isEdited = null,
    Object? editedAt = freezed,
  }) {
    return _then(_CommentModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      taskId: freezed == taskId
          ? _self.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mentionedUsers: null == mentionedUsers
          ? _self._mentionedUsers
          : mentionedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isEdited: null == isEdited
          ? _self.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      editedAt: freezed == editedAt
          ? _self.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
