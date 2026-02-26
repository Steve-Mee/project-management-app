// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectModel {
  @HiveField(0)
  @JsonKey(fromJson: _parseId)
  String get id;
  @HiveField(1)
  String get name;
  @HiveField(2)
  double get progress;
  @HiveField(3)
  String? get directoryPath;
  @HiveField(4)
  List<String> get tasks;
  @HiveField(5)
  String get status;
  @HiveField(6)
  String? get description;
  @HiveField(9)
  String? get category;
  @HiveField(10)
  String? get aiAssistant;
  @HiveField(11)
  String? get planJson;
  @HiveField(12)
  @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
  HelpLevel get helpLevel;
  @HiveField(13)
  @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
  Complexity get complexity;

  /// Change history for auditing and compliance
  /// Each entry contains: {'change': description, 'user': anonymous_id, 'time': timestamp}
  /// COMPLIANCE: History logs changes anonymously per worldwide privacy laws.
  /// Only aggregate change data is retained; no personal data is stored.
  @HiveField(14)
  @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
  List<Map<String, dynamic>> get history;
  @HiveField(7)
  List<String> get sharedUsers;
  @HiveField(8)
  List<String> get sharedGroups;
  @HiveField(15)
  String? get priority;
  @HiveField(16)
  DateTime? get startDate;
  @HiveField(17)
  DateTime? get dueDate;
  @HiveField(18)
  List<String> get tags;
  @HiveField(19)
  Map<String, dynamic>? get customFields;
  @HiveField(20)
  List<CommentModel> get comments;

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectModelCopyWith<ProjectModel> get copyWith =>
      _$ProjectModelCopyWithImpl<ProjectModel>(
          this as ProjectModel, _$identity);

  /// Serializes this ProjectModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.directoryPath, directoryPath) ||
                other.directoryPath == directoryPath) &&
            const DeepCollectionEquality().equals(other.tasks, tasks) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.aiAssistant, aiAssistant) ||
                other.aiAssistant == aiAssistant) &&
            (identical(other.planJson, planJson) ||
                other.planJson == planJson) &&
            (identical(other.helpLevel, helpLevel) ||
                other.helpLevel == helpLevel) &&
            (identical(other.complexity, complexity) ||
                other.complexity == complexity) &&
            const DeepCollectionEquality().equals(other.history, history) &&
            const DeepCollectionEquality()
                .equals(other.sharedUsers, sharedUsers) &&
            const DeepCollectionEquality()
                .equals(other.sharedGroups, sharedGroups) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality()
                .equals(other.customFields, customFields) &&
            const DeepCollectionEquality().equals(other.comments, comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        progress,
        directoryPath,
        const DeepCollectionEquality().hash(tasks),
        status,
        description,
        category,
        aiAssistant,
        planJson,
        helpLevel,
        complexity,
        const DeepCollectionEquality().hash(history),
        const DeepCollectionEquality().hash(sharedUsers),
        const DeepCollectionEquality().hash(sharedGroups),
        priority,
        startDate,
        dueDate,
        const DeepCollectionEquality().hash(tags),
        const DeepCollectionEquality().hash(customFields),
        const DeepCollectionEquality().hash(comments)
      ]);

  @override
  String toString() {
    return 'ProjectModel(id: $id, name: $name, progress: $progress, directoryPath: $directoryPath, tasks: $tasks, status: $status, description: $description, category: $category, aiAssistant: $aiAssistant, planJson: $planJson, helpLevel: $helpLevel, complexity: $complexity, history: $history, sharedUsers: $sharedUsers, sharedGroups: $sharedGroups, priority: $priority, startDate: $startDate, dueDate: $dueDate, tags: $tags, customFields: $customFields, comments: $comments)';
  }
}

/// @nodoc
abstract mixin class $ProjectModelCopyWith<$Res> {
  factory $ProjectModelCopyWith(
          ProjectModel value, $Res Function(ProjectModel) _then) =
      _$ProjectModelCopyWithImpl;
  @useResult
  $Res call(
      {@HiveField(0) @JsonKey(fromJson: _parseId) String id,
      @HiveField(1) String name,
      @HiveField(2) double progress,
      @HiveField(3) String? directoryPath,
      @HiveField(4) List<String> tasks,
      @HiveField(5) String status,
      @HiveField(6) String? description,
      @HiveField(9) String? category,
      @HiveField(10) String? aiAssistant,
      @HiveField(11) String? planJson,
      @HiveField(12)
      @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
      HelpLevel helpLevel,
      @HiveField(13)
      @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
      Complexity complexity,
      @HiveField(14)
      @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
      List<Map<String, dynamic>> history,
      @HiveField(7) List<String> sharedUsers,
      @HiveField(8) List<String> sharedGroups,
      @HiveField(15) String? priority,
      @HiveField(16) DateTime? startDate,
      @HiveField(17) DateTime? dueDate,
      @HiveField(18) List<String> tags,
      @HiveField(19) Map<String, dynamic>? customFields,
      @HiveField(20) List<CommentModel> comments});
}

/// @nodoc
class _$ProjectModelCopyWithImpl<$Res> implements $ProjectModelCopyWith<$Res> {
  _$ProjectModelCopyWithImpl(this._self, this._then);

  final ProjectModel _self;
  final $Res Function(ProjectModel) _then;

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? progress = null,
    Object? directoryPath = freezed,
    Object? tasks = null,
    Object? status = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? aiAssistant = freezed,
    Object? planJson = freezed,
    Object? helpLevel = null,
    Object? complexity = null,
    Object? history = null,
    Object? sharedUsers = null,
    Object? sharedGroups = null,
    Object? priority = freezed,
    Object? startDate = freezed,
    Object? dueDate = freezed,
    Object? tags = null,
    Object? customFields = freezed,
    Object? comments = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      directoryPath: freezed == directoryPath
          ? _self.directoryPath
          : directoryPath // ignore: cast_nullable_to_non_nullable
              as String?,
      tasks: null == tasks
          ? _self.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      aiAssistant: freezed == aiAssistant
          ? _self.aiAssistant
          : aiAssistant // ignore: cast_nullable_to_non_nullable
              as String?,
      planJson: freezed == planJson
          ? _self.planJson
          : planJson // ignore: cast_nullable_to_non_nullable
              as String?,
      helpLevel: null == helpLevel
          ? _self.helpLevel
          : helpLevel // ignore: cast_nullable_to_non_nullable
              as HelpLevel,
      complexity: null == complexity
          ? _self.complexity
          : complexity // ignore: cast_nullable_to_non_nullable
              as Complexity,
      history: null == history
          ? _self.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      sharedUsers: null == sharedUsers
          ? _self.sharedUsers
          : sharedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sharedGroups: null == sharedGroups
          ? _self.sharedGroups
          : sharedGroups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDate: freezed == dueDate
          ? _self.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customFields: freezed == customFields
          ? _self.customFields
          : customFields // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      comments: null == comments
          ? _self.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectModel].
extension ProjectModelPatterns on ProjectModel {
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
    TResult Function(_ProjectModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectModel() when $default != null:
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
    TResult Function(_ProjectModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectModel():
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
    TResult? Function(_ProjectModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectModel() when $default != null:
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
            @HiveField(0) @JsonKey(fromJson: _parseId) String id,
            @HiveField(1) String name,
            @HiveField(2) double progress,
            @HiveField(3) String? directoryPath,
            @HiveField(4) List<String> tasks,
            @HiveField(5) String status,
            @HiveField(6) String? description,
            @HiveField(9) String? category,
            @HiveField(10) String? aiAssistant,
            @HiveField(11) String? planJson,
            @HiveField(12)
            @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
            HelpLevel helpLevel,
            @HiveField(13)
            @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
            Complexity complexity,
            @HiveField(14)
            @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
            List<Map<String, dynamic>> history,
            @HiveField(7) List<String> sharedUsers,
            @HiveField(8) List<String> sharedGroups,
            @HiveField(15) String? priority,
            @HiveField(16) DateTime? startDate,
            @HiveField(17) DateTime? dueDate,
            @HiveField(18) List<String> tags,
            @HiveField(19) Map<String, dynamic>? customFields,
            @HiveField(20) List<CommentModel> comments)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectModel() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.progress,
            _that.directoryPath,
            _that.tasks,
            _that.status,
            _that.description,
            _that.category,
            _that.aiAssistant,
            _that.planJson,
            _that.helpLevel,
            _that.complexity,
            _that.history,
            _that.sharedUsers,
            _that.sharedGroups,
            _that.priority,
            _that.startDate,
            _that.dueDate,
            _that.tags,
            _that.customFields,
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
            @HiveField(0) @JsonKey(fromJson: _parseId) String id,
            @HiveField(1) String name,
            @HiveField(2) double progress,
            @HiveField(3) String? directoryPath,
            @HiveField(4) List<String> tasks,
            @HiveField(5) String status,
            @HiveField(6) String? description,
            @HiveField(9) String? category,
            @HiveField(10) String? aiAssistant,
            @HiveField(11) String? planJson,
            @HiveField(12)
            @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
            HelpLevel helpLevel,
            @HiveField(13)
            @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
            Complexity complexity,
            @HiveField(14)
            @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
            List<Map<String, dynamic>> history,
            @HiveField(7) List<String> sharedUsers,
            @HiveField(8) List<String> sharedGroups,
            @HiveField(15) String? priority,
            @HiveField(16) DateTime? startDate,
            @HiveField(17) DateTime? dueDate,
            @HiveField(18) List<String> tags,
            @HiveField(19) Map<String, dynamic>? customFields,
            @HiveField(20) List<CommentModel> comments)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectModel():
        return $default(
            _that.id,
            _that.name,
            _that.progress,
            _that.directoryPath,
            _that.tasks,
            _that.status,
            _that.description,
            _that.category,
            _that.aiAssistant,
            _that.planJson,
            _that.helpLevel,
            _that.complexity,
            _that.history,
            _that.sharedUsers,
            _that.sharedGroups,
            _that.priority,
            _that.startDate,
            _that.dueDate,
            _that.tags,
            _that.customFields,
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
            @HiveField(0) @JsonKey(fromJson: _parseId) String id,
            @HiveField(1) String name,
            @HiveField(2) double progress,
            @HiveField(3) String? directoryPath,
            @HiveField(4) List<String> tasks,
            @HiveField(5) String status,
            @HiveField(6) String? description,
            @HiveField(9) String? category,
            @HiveField(10) String? aiAssistant,
            @HiveField(11) String? planJson,
            @HiveField(12)
            @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
            HelpLevel helpLevel,
            @HiveField(13)
            @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
            Complexity complexity,
            @HiveField(14)
            @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
            List<Map<String, dynamic>> history,
            @HiveField(7) List<String> sharedUsers,
            @HiveField(8) List<String> sharedGroups,
            @HiveField(15) String? priority,
            @HiveField(16) DateTime? startDate,
            @HiveField(17) DateTime? dueDate,
            @HiveField(18) List<String> tags,
            @HiveField(19) Map<String, dynamic>? customFields,
            @HiveField(20) List<CommentModel> comments)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectModel() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.progress,
            _that.directoryPath,
            _that.tasks,
            _that.status,
            _that.description,
            _that.category,
            _that.aiAssistant,
            _that.planJson,
            _that.helpLevel,
            _that.complexity,
            _that.history,
            _that.sharedUsers,
            _that.sharedGroups,
            _that.priority,
            _that.startDate,
            _that.dueDate,
            _that.tags,
            _that.customFields,
            _that.comments);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProjectModel extends ProjectModel {
  const _ProjectModel(
      {@HiveField(0) @JsonKey(fromJson: _parseId) required this.id,
      @HiveField(1) required this.name,
      @HiveField(2) required this.progress,
      @HiveField(3) this.directoryPath,
      @HiveField(4) final List<String> tasks = const <String>[],
      @HiveField(5) this.status = 'In Progress',
      @HiveField(6) this.description,
      @HiveField(9) this.category,
      @HiveField(10) this.aiAssistant,
      @HiveField(11) this.planJson,
      @HiveField(12)
      @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
      this.helpLevel = HelpLevel.basis,
      @HiveField(13)
      @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
      this.complexity = Complexity.simpel,
      @HiveField(14)
      @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
      final List<Map<String, dynamic>> history = const <Map<String, dynamic>>[],
      @HiveField(7) final List<String> sharedUsers = const <String>[],
      @HiveField(8) final List<String> sharedGroups = const <String>[],
      @HiveField(15) this.priority,
      @HiveField(16) this.startDate,
      @HiveField(17) this.dueDate,
      @HiveField(18) final List<String> tags = const <String>[],
      @HiveField(19) final Map<String, dynamic>? customFields,
      @HiveField(20)
      final List<CommentModel> comments = const <CommentModel>[]})
      : _tasks = tasks,
        _history = history,
        _sharedUsers = sharedUsers,
        _sharedGroups = sharedGroups,
        _tags = tags,
        _customFields = customFields,
        _comments = comments,
        super._();
  factory _ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);

  @override
  @HiveField(0)
  @JsonKey(fromJson: _parseId)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final double progress;
  @override
  @HiveField(3)
  final String? directoryPath;
  final List<String> _tasks;
  @override
  @JsonKey()
  @HiveField(4)
  List<String> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  @JsonKey()
  @HiveField(5)
  final String status;
  @override
  @HiveField(6)
  final String? description;
  @override
  @HiveField(9)
  final String? category;
  @override
  @HiveField(10)
  final String? aiAssistant;
  @override
  @HiveField(11)
  final String? planJson;
  @override
  @HiveField(12)
  @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
  final HelpLevel helpLevel;
  @override
  @HiveField(13)
  @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
  final Complexity complexity;

  /// Change history for auditing and compliance
  /// Each entry contains: {'change': description, 'user': anonymous_id, 'time': timestamp}
  /// COMPLIANCE: History logs changes anonymously per worldwide privacy laws.
  /// Only aggregate change data is retained; no personal data is stored.
  final List<Map<String, dynamic>> _history;

  /// Change history for auditing and compliance
  /// Each entry contains: {'change': description, 'user': anonymous_id, 'time': timestamp}
  /// COMPLIANCE: History logs changes anonymously per worldwide privacy laws.
  /// Only aggregate change data is retained; no personal data is stored.
  @override
  @HiveField(14)
  @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
  List<Map<String, dynamic>> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  final List<String> _sharedUsers;
  @override
  @JsonKey()
  @HiveField(7)
  List<String> get sharedUsers {
    if (_sharedUsers is EqualUnmodifiableListView) return _sharedUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sharedUsers);
  }

  final List<String> _sharedGroups;
  @override
  @JsonKey()
  @HiveField(8)
  List<String> get sharedGroups {
    if (_sharedGroups is EqualUnmodifiableListView) return _sharedGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sharedGroups);
  }

  @override
  @HiveField(15)
  final String? priority;
  @override
  @HiveField(16)
  final DateTime? startDate;
  @override
  @HiveField(17)
  final DateTime? dueDate;
  final List<String> _tags;
  @override
  @JsonKey()
  @HiveField(18)
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final Map<String, dynamic>? _customFields;
  @override
  @HiveField(19)
  Map<String, dynamic>? get customFields {
    final value = _customFields;
    if (value == null) return null;
    if (_customFields is EqualUnmodifiableMapView) return _customFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<CommentModel> _comments;
  @override
  @JsonKey()
  @HiveField(20)
  List<CommentModel> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectModelCopyWith<_ProjectModel> get copyWith =>
      __$ProjectModelCopyWithImpl<_ProjectModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.directoryPath, directoryPath) ||
                other.directoryPath == directoryPath) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.aiAssistant, aiAssistant) ||
                other.aiAssistant == aiAssistant) &&
            (identical(other.planJson, planJson) ||
                other.planJson == planJson) &&
            (identical(other.helpLevel, helpLevel) ||
                other.helpLevel == helpLevel) &&
            (identical(other.complexity, complexity) ||
                other.complexity == complexity) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            const DeepCollectionEquality()
                .equals(other._sharedUsers, _sharedUsers) &&
            const DeepCollectionEquality()
                .equals(other._sharedGroups, _sharedGroups) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._customFields, _customFields) &&
            const DeepCollectionEquality().equals(other._comments, _comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        progress,
        directoryPath,
        const DeepCollectionEquality().hash(_tasks),
        status,
        description,
        category,
        aiAssistant,
        planJson,
        helpLevel,
        complexity,
        const DeepCollectionEquality().hash(_history),
        const DeepCollectionEquality().hash(_sharedUsers),
        const DeepCollectionEquality().hash(_sharedGroups),
        priority,
        startDate,
        dueDate,
        const DeepCollectionEquality().hash(_tags),
        const DeepCollectionEquality().hash(_customFields),
        const DeepCollectionEquality().hash(_comments)
      ]);

  @override
  String toString() {
    return 'ProjectModel(id: $id, name: $name, progress: $progress, directoryPath: $directoryPath, tasks: $tasks, status: $status, description: $description, category: $category, aiAssistant: $aiAssistant, planJson: $planJson, helpLevel: $helpLevel, complexity: $complexity, history: $history, sharedUsers: $sharedUsers, sharedGroups: $sharedGroups, priority: $priority, startDate: $startDate, dueDate: $dueDate, tags: $tags, customFields: $customFields, comments: $comments)';
  }
}

/// @nodoc
abstract mixin class _$ProjectModelCopyWith<$Res>
    implements $ProjectModelCopyWith<$Res> {
  factory _$ProjectModelCopyWith(
          _ProjectModel value, $Res Function(_ProjectModel) _then) =
      __$ProjectModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@HiveField(0) @JsonKey(fromJson: _parseId) String id,
      @HiveField(1) String name,
      @HiveField(2) double progress,
      @HiveField(3) String? directoryPath,
      @HiveField(4) List<String> tasks,
      @HiveField(5) String status,
      @HiveField(6) String? description,
      @HiveField(9) String? category,
      @HiveField(10) String? aiAssistant,
      @HiveField(11) String? planJson,
      @HiveField(12)
      @JsonKey(fromJson: _parseHelpLevel, toJson: _helpLevelToJson)
      HelpLevel helpLevel,
      @HiveField(13)
      @JsonKey(fromJson: _parseComplexity, toJson: _complexityToJson)
      Complexity complexity,
      @HiveField(14)
      @JsonKey(fromJson: _parseHistory, toJson: _historyToJson)
      List<Map<String, dynamic>> history,
      @HiveField(7) List<String> sharedUsers,
      @HiveField(8) List<String> sharedGroups,
      @HiveField(15) String? priority,
      @HiveField(16) DateTime? startDate,
      @HiveField(17) DateTime? dueDate,
      @HiveField(18) List<String> tags,
      @HiveField(19) Map<String, dynamic>? customFields,
      @HiveField(20) List<CommentModel> comments});
}

/// @nodoc
class __$ProjectModelCopyWithImpl<$Res>
    implements _$ProjectModelCopyWith<$Res> {
  __$ProjectModelCopyWithImpl(this._self, this._then);

  final _ProjectModel _self;
  final $Res Function(_ProjectModel) _then;

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? progress = null,
    Object? directoryPath = freezed,
    Object? tasks = null,
    Object? status = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? aiAssistant = freezed,
    Object? planJson = freezed,
    Object? helpLevel = null,
    Object? complexity = null,
    Object? history = null,
    Object? sharedUsers = null,
    Object? sharedGroups = null,
    Object? priority = freezed,
    Object? startDate = freezed,
    Object? dueDate = freezed,
    Object? tags = null,
    Object? customFields = freezed,
    Object? comments = null,
  }) {
    return _then(_ProjectModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      directoryPath: freezed == directoryPath
          ? _self.directoryPath
          : directoryPath // ignore: cast_nullable_to_non_nullable
              as String?,
      tasks: null == tasks
          ? _self._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      aiAssistant: freezed == aiAssistant
          ? _self.aiAssistant
          : aiAssistant // ignore: cast_nullable_to_non_nullable
              as String?,
      planJson: freezed == planJson
          ? _self.planJson
          : planJson // ignore: cast_nullable_to_non_nullable
              as String?,
      helpLevel: null == helpLevel
          ? _self.helpLevel
          : helpLevel // ignore: cast_nullable_to_non_nullable
              as HelpLevel,
      complexity: null == complexity
          ? _self.complexity
          : complexity // ignore: cast_nullable_to_non_nullable
              as Complexity,
      history: null == history
          ? _self._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      sharedUsers: null == sharedUsers
          ? _self._sharedUsers
          : sharedUsers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sharedGroups: null == sharedGroups
          ? _self._sharedGroups
          : sharedGroups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDate: freezed == dueDate
          ? _self.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customFields: freezed == customFields
          ? _self._customFields
          : customFields // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      comments: null == comments
          ? _self._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
    ));
  }
}

// dart format on
