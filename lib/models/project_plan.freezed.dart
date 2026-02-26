// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanTask {
  String get description;
  String get status;
  String? get assignedUserId;
  String? get assignedUserName;

  /// Create a copy of PlanTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlanTaskCopyWith<PlanTask> get copyWith =>
      _$PlanTaskCopyWithImpl<PlanTask>(this as PlanTask, _$identity);

  /// Serializes this PlanTask to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlanTask &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignedUserId, assignedUserId) ||
                other.assignedUserId == assignedUserId) &&
            (identical(other.assignedUserName, assignedUserName) ||
                other.assignedUserName == assignedUserName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, description, status, assignedUserId, assignedUserName);

  @override
  String toString() {
    return 'PlanTask(description: $description, status: $status, assignedUserId: $assignedUserId, assignedUserName: $assignedUserName)';
  }
}

/// @nodoc
abstract mixin class $PlanTaskCopyWith<$Res> {
  factory $PlanTaskCopyWith(PlanTask value, $Res Function(PlanTask) _then) =
      _$PlanTaskCopyWithImpl;
  @useResult
  $Res call(
      {String description,
      String status,
      String? assignedUserId,
      String? assignedUserName});
}

/// @nodoc
class _$PlanTaskCopyWithImpl<$Res> implements $PlanTaskCopyWith<$Res> {
  _$PlanTaskCopyWithImpl(this._self, this._then);

  final PlanTask _self;
  final $Res Function(PlanTask) _then;

  /// Create a copy of PlanTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? status = null,
    Object? assignedUserId = freezed,
    Object? assignedUserName = freezed,
  }) {
    return _then(_self.copyWith(
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      assignedUserId: freezed == assignedUserId
          ? _self.assignedUserId
          : assignedUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedUserName: freezed == assignedUserName
          ? _self.assignedUserName
          : assignedUserName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlanTask].
extension PlanTaskPatterns on PlanTask {
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
    TResult Function(_PlanTask value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanTask() when $default != null:
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
    TResult Function(_PlanTask value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanTask():
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
    TResult? Function(_PlanTask value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanTask() when $default != null:
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
    TResult Function(String description, String status, String? assignedUserId,
            String? assignedUserName)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanTask() when $default != null:
        return $default(_that.description, _that.status, _that.assignedUserId,
            _that.assignedUserName);
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
    TResult Function(String description, String status, String? assignedUserId,
            String? assignedUserName)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanTask():
        return $default(_that.description, _that.status, _that.assignedUserId,
            _that.assignedUserName);
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
    TResult? Function(String description, String status, String? assignedUserId,
            String? assignedUserName)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanTask() when $default != null:
        return $default(_that.description, _that.status, _that.assignedUserId,
            _that.assignedUserName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlanTask implements PlanTask {
  const _PlanTask(
      {required this.description,
      this.status = 'pending',
      this.assignedUserId,
      this.assignedUserName});
  factory _PlanTask.fromJson(Map<String, dynamic> json) =>
      _$PlanTaskFromJson(json);

  @override
  final String description;
  @override
  @JsonKey()
  final String status;
  @override
  final String? assignedUserId;
  @override
  final String? assignedUserName;

  /// Create a copy of PlanTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlanTaskCopyWith<_PlanTask> get copyWith =>
      __$PlanTaskCopyWithImpl<_PlanTask>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlanTaskToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlanTask &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignedUserId, assignedUserId) ||
                other.assignedUserId == assignedUserId) &&
            (identical(other.assignedUserName, assignedUserName) ||
                other.assignedUserName == assignedUserName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, description, status, assignedUserId, assignedUserName);

  @override
  String toString() {
    return 'PlanTask(description: $description, status: $status, assignedUserId: $assignedUserId, assignedUserName: $assignedUserName)';
  }
}

/// @nodoc
abstract mixin class _$PlanTaskCopyWith<$Res>
    implements $PlanTaskCopyWith<$Res> {
  factory _$PlanTaskCopyWith(_PlanTask value, $Res Function(_PlanTask) _then) =
      __$PlanTaskCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String description,
      String status,
      String? assignedUserId,
      String? assignedUserName});
}

/// @nodoc
class __$PlanTaskCopyWithImpl<$Res> implements _$PlanTaskCopyWith<$Res> {
  __$PlanTaskCopyWithImpl(this._self, this._then);

  final _PlanTask _self;
  final $Res Function(_PlanTask) _then;

  /// Create a copy of PlanTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? description = null,
    Object? status = null,
    Object? assignedUserId = freezed,
    Object? assignedUserName = freezed,
  }) {
    return _then(_PlanTask(
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      assignedUserId: freezed == assignedUserId
          ? _self.assignedUserId
          : assignedUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedUserName: freezed == assignedUserName
          ? _self.assignedUserName
          : assignedUserName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PlanChapter {
  String get title;
  String get overview;
  List<PlanTask> get tasks;

  /// Create a copy of PlanChapter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlanChapterCopyWith<PlanChapter> get copyWith =>
      _$PlanChapterCopyWithImpl<PlanChapter>(this as PlanChapter, _$identity);

  /// Serializes this PlanChapter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlanChapter &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            const DeepCollectionEquality().equals(other.tasks, tasks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, title, overview, const DeepCollectionEquality().hash(tasks));

  @override
  String toString() {
    return 'PlanChapter(title: $title, overview: $overview, tasks: $tasks)';
  }
}

/// @nodoc
abstract mixin class $PlanChapterCopyWith<$Res> {
  factory $PlanChapterCopyWith(
          PlanChapter value, $Res Function(PlanChapter) _then) =
      _$PlanChapterCopyWithImpl;
  @useResult
  $Res call({String title, String overview, List<PlanTask> tasks});
}

/// @nodoc
class _$PlanChapterCopyWithImpl<$Res> implements $PlanChapterCopyWith<$Res> {
  _$PlanChapterCopyWithImpl(this._self, this._then);

  final PlanChapter _self;
  final $Res Function(PlanChapter) _then;

  /// Create a copy of PlanChapter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? overview = null,
    Object? tasks = null,
  }) {
    return _then(_self.copyWith(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      overview: null == overview
          ? _self.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String,
      tasks: null == tasks
          ? _self.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<PlanTask>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlanChapter].
extension PlanChapterPatterns on PlanChapter {
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
    TResult Function(_PlanChapter value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanChapter() when $default != null:
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
    TResult Function(_PlanChapter value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanChapter():
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
    TResult? Function(_PlanChapter value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanChapter() when $default != null:
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
    TResult Function(String title, String overview, List<PlanTask> tasks)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanChapter() when $default != null:
        return $default(_that.title, _that.overview, _that.tasks);
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
    TResult Function(String title, String overview, List<PlanTask> tasks)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanChapter():
        return $default(_that.title, _that.overview, _that.tasks);
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
    TResult? Function(String title, String overview, List<PlanTask> tasks)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanChapter() when $default != null:
        return $default(_that.title, _that.overview, _that.tasks);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlanChapter implements PlanChapter {
  const _PlanChapter(
      {required this.title,
      required this.overview,
      final List<PlanTask> tasks = const <PlanTask>[]})
      : _tasks = tasks;
  factory _PlanChapter.fromJson(Map<String, dynamic> json) =>
      _$PlanChapterFromJson(json);

  @override
  final String title;
  @override
  final String overview;
  final List<PlanTask> _tasks;
  @override
  @JsonKey()
  List<PlanTask> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  /// Create a copy of PlanChapter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlanChapterCopyWith<_PlanChapter> get copyWith =>
      __$PlanChapterCopyWithImpl<_PlanChapter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlanChapterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlanChapter &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, overview,
      const DeepCollectionEquality().hash(_tasks));

  @override
  String toString() {
    return 'PlanChapter(title: $title, overview: $overview, tasks: $tasks)';
  }
}

/// @nodoc
abstract mixin class _$PlanChapterCopyWith<$Res>
    implements $PlanChapterCopyWith<$Res> {
  factory _$PlanChapterCopyWith(
          _PlanChapter value, $Res Function(_PlanChapter) _then) =
      __$PlanChapterCopyWithImpl;
  @override
  @useResult
  $Res call({String title, String overview, List<PlanTask> tasks});
}

/// @nodoc
class __$PlanChapterCopyWithImpl<$Res> implements _$PlanChapterCopyWith<$Res> {
  __$PlanChapterCopyWithImpl(this._self, this._then);

  final _PlanChapter _self;
  final $Res Function(_PlanChapter) _then;

  /// Create a copy of PlanChapter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = null,
    Object? overview = null,
    Object? tasks = null,
  }) {
    return _then(_PlanChapter(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      overview: null == overview
          ? _self.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String,
      tasks: null == tasks
          ? _self._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<PlanTask>,
    ));
  }
}

/// @nodoc
mixin _$ProjectPlan {
  String get overview;
  List<PlanChapter> get chapters;

  /// Create a copy of ProjectPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectPlanCopyWith<ProjectPlan> get copyWith =>
      _$ProjectPlanCopyWithImpl<ProjectPlan>(this as ProjectPlan, _$identity);

  /// Serializes this ProjectPlan to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectPlan &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            const DeepCollectionEquality().equals(other.chapters, chapters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, overview, const DeepCollectionEquality().hash(chapters));

  @override
  String toString() {
    return 'ProjectPlan(overview: $overview, chapters: $chapters)';
  }
}

/// @nodoc
abstract mixin class $ProjectPlanCopyWith<$Res> {
  factory $ProjectPlanCopyWith(
          ProjectPlan value, $Res Function(ProjectPlan) _then) =
      _$ProjectPlanCopyWithImpl;
  @useResult
  $Res call({String overview, List<PlanChapter> chapters});
}

/// @nodoc
class _$ProjectPlanCopyWithImpl<$Res> implements $ProjectPlanCopyWith<$Res> {
  _$ProjectPlanCopyWithImpl(this._self, this._then);

  final ProjectPlan _self;
  final $Res Function(ProjectPlan) _then;

  /// Create a copy of ProjectPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overview = null,
    Object? chapters = null,
  }) {
    return _then(_self.copyWith(
      overview: null == overview
          ? _self.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String,
      chapters: null == chapters
          ? _self.chapters
          : chapters // ignore: cast_nullable_to_non_nullable
              as List<PlanChapter>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectPlan].
extension ProjectPlanPatterns on ProjectPlan {
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
    TResult Function(_ProjectPlan value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectPlan() when $default != null:
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
    TResult Function(_ProjectPlan value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectPlan():
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
    TResult? Function(_ProjectPlan value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectPlan() when $default != null:
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
    TResult Function(String overview, List<PlanChapter> chapters)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectPlan() when $default != null:
        return $default(_that.overview, _that.chapters);
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
    TResult Function(String overview, List<PlanChapter> chapters) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectPlan():
        return $default(_that.overview, _that.chapters);
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
    TResult? Function(String overview, List<PlanChapter> chapters)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectPlan() when $default != null:
        return $default(_that.overview, _that.chapters);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProjectPlan implements ProjectPlan {
  const _ProjectPlan(
      {required this.overview,
      final List<PlanChapter> chapters = const <PlanChapter>[]})
      : _chapters = chapters;
  factory _ProjectPlan.fromJson(Map<String, dynamic> json) =>
      _$ProjectPlanFromJson(json);

  @override
  final String overview;
  final List<PlanChapter> _chapters;
  @override
  @JsonKey()
  List<PlanChapter> get chapters {
    if (_chapters is EqualUnmodifiableListView) return _chapters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chapters);
  }

  /// Create a copy of ProjectPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectPlanCopyWith<_ProjectPlan> get copyWith =>
      __$ProjectPlanCopyWithImpl<_ProjectPlan>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectPlanToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectPlan &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            const DeepCollectionEquality().equals(other._chapters, _chapters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, overview, const DeepCollectionEquality().hash(_chapters));

  @override
  String toString() {
    return 'ProjectPlan(overview: $overview, chapters: $chapters)';
  }
}

/// @nodoc
abstract mixin class _$ProjectPlanCopyWith<$Res>
    implements $ProjectPlanCopyWith<$Res> {
  factory _$ProjectPlanCopyWith(
          _ProjectPlan value, $Res Function(_ProjectPlan) _then) =
      __$ProjectPlanCopyWithImpl;
  @override
  @useResult
  $Res call({String overview, List<PlanChapter> chapters});
}

/// @nodoc
class __$ProjectPlanCopyWithImpl<$Res> implements _$ProjectPlanCopyWith<$Res> {
  __$ProjectPlanCopyWithImpl(this._self, this._then);

  final _ProjectPlan _self;
  final $Res Function(_ProjectPlan) _then;

  /// Create a copy of ProjectPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? overview = null,
    Object? chapters = null,
  }) {
    return _then(_ProjectPlan(
      overview: null == overview
          ? _self.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String,
      chapters: null == chapters
          ? _self._chapters
          : chapters // ignore: cast_nullable_to_non_nullable
              as List<PlanChapter>,
    ));
  }
}

// dart format on
