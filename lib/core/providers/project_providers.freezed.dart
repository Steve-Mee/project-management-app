// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectFilterParams {
  String? get status;
  String? get searchQuery;
  DateTime? get startDate;
  DateTime? get endDate;
  String? get priority;
  String? get ownerId;
  List<String>? get tags;
  List<ProjectFilterConditions>? get extraConditions;

  /// Create a copy of ProjectFilterParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectFilterParamsCopyWith<ProjectFilterParams> get copyWith =>
      _$ProjectFilterParamsCopyWithImpl<ProjectFilterParams>(
          this as ProjectFilterParams, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectFilterParams &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality()
                .equals(other.extraConditions, extraConditions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      searchQuery,
      startDate,
      endDate,
      priority,
      ownerId,
      const DeepCollectionEquality().hash(tags),
      const DeepCollectionEquality().hash(extraConditions));

  @override
  String toString() {
    return 'ProjectFilterParams(status: $status, searchQuery: $searchQuery, startDate: $startDate, endDate: $endDate, priority: $priority, ownerId: $ownerId, tags: $tags, extraConditions: $extraConditions)';
  }
}

/// @nodoc
abstract mixin class $ProjectFilterParamsCopyWith<$Res> {
  factory $ProjectFilterParamsCopyWith(
          ProjectFilterParams value, $Res Function(ProjectFilterParams) _then) =
      _$ProjectFilterParamsCopyWithImpl;
  @useResult
  $Res call(
      {String? status,
      String? searchQuery,
      DateTime? startDate,
      DateTime? endDate,
      String? priority,
      String? ownerId,
      List<String>? tags,
      List<ProjectFilterConditions>? extraConditions});
}

/// @nodoc
class _$ProjectFilterParamsCopyWithImpl<$Res>
    implements $ProjectFilterParamsCopyWith<$Res> {
  _$ProjectFilterParamsCopyWithImpl(this._self, this._then);

  final ProjectFilterParams _self;
  final $Res Function(ProjectFilterParams) _then;

  /// Create a copy of ProjectFilterParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = freezed,
    Object? searchQuery = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? priority = freezed,
    Object? ownerId = freezed,
    Object? tags = freezed,
    Object? extraConditions = freezed,
  }) {
    return _then(_self.copyWith(
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: freezed == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: freezed == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      extraConditions: freezed == extraConditions
          ? _self.extraConditions
          : extraConditions // ignore: cast_nullable_to_non_nullable
              as List<ProjectFilterConditions>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectFilterParams].
extension ProjectFilterParamsPatterns on ProjectFilterParams {
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
    TResult Function(_ProjectFilterParams value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFilterParams() when $default != null:
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
    TResult Function(_ProjectFilterParams value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilterParams():
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
    TResult? Function(_ProjectFilterParams value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilterParams() when $default != null:
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
            String? status,
            String? searchQuery,
            DateTime? startDate,
            DateTime? endDate,
            String? priority,
            String? ownerId,
            List<String>? tags,
            List<ProjectFilterConditions>? extraConditions)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFilterParams() when $default != null:
        return $default(
            _that.status,
            _that.searchQuery,
            _that.startDate,
            _that.endDate,
            _that.priority,
            _that.ownerId,
            _that.tags,
            _that.extraConditions);
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
            String? status,
            String? searchQuery,
            DateTime? startDate,
            DateTime? endDate,
            String? priority,
            String? ownerId,
            List<String>? tags,
            List<ProjectFilterConditions>? extraConditions)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilterParams():
        return $default(
            _that.status,
            _that.searchQuery,
            _that.startDate,
            _that.endDate,
            _that.priority,
            _that.ownerId,
            _that.tags,
            _that.extraConditions);
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
            String? status,
            String? searchQuery,
            DateTime? startDate,
            DateTime? endDate,
            String? priority,
            String? ownerId,
            List<String>? tags,
            List<ProjectFilterConditions>? extraConditions)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilterParams() when $default != null:
        return $default(
            _that.status,
            _that.searchQuery,
            _that.startDate,
            _that.endDate,
            _that.priority,
            _that.ownerId,
            _that.tags,
            _that.extraConditions);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectFilterParams implements ProjectFilterParams {
  const _ProjectFilterParams(
      {this.status,
      this.searchQuery,
      this.startDate,
      this.endDate,
      this.priority,
      this.ownerId,
      final List<String>? tags,
      final List<ProjectFilterConditions>? extraConditions})
      : _tags = tags,
        _extraConditions = extraConditions;

  @override
  final String? status;
  @override
  final String? searchQuery;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final String? priority;
  @override
  final String? ownerId;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ProjectFilterConditions>? _extraConditions;
  @override
  List<ProjectFilterConditions>? get extraConditions {
    final value = _extraConditions;
    if (value == null) return null;
    if (_extraConditions is EqualUnmodifiableListView) return _extraConditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of ProjectFilterParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectFilterParamsCopyWith<_ProjectFilterParams> get copyWith =>
      __$ProjectFilterParamsCopyWithImpl<_ProjectFilterParams>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectFilterParams &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._extraConditions, _extraConditions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      searchQuery,
      startDate,
      endDate,
      priority,
      ownerId,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_extraConditions));

  @override
  String toString() {
    return 'ProjectFilterParams(status: $status, searchQuery: $searchQuery, startDate: $startDate, endDate: $endDate, priority: $priority, ownerId: $ownerId, tags: $tags, extraConditions: $extraConditions)';
  }
}

/// @nodoc
abstract mixin class _$ProjectFilterParamsCopyWith<$Res>
    implements $ProjectFilterParamsCopyWith<$Res> {
  factory _$ProjectFilterParamsCopyWith(_ProjectFilterParams value,
          $Res Function(_ProjectFilterParams) _then) =
      __$ProjectFilterParamsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? status,
      String? searchQuery,
      DateTime? startDate,
      DateTime? endDate,
      String? priority,
      String? ownerId,
      List<String>? tags,
      List<ProjectFilterConditions>? extraConditions});
}

/// @nodoc
class __$ProjectFilterParamsCopyWithImpl<$Res>
    implements _$ProjectFilterParamsCopyWith<$Res> {
  __$ProjectFilterParamsCopyWithImpl(this._self, this._then);

  final _ProjectFilterParams _self;
  final $Res Function(_ProjectFilterParams) _then;

  /// Create a copy of ProjectFilterParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = freezed,
    Object? searchQuery = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? priority = freezed,
    Object? ownerId = freezed,
    Object? tags = freezed,
    Object? extraConditions = freezed,
  }) {
    return _then(_ProjectFilterParams(
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: freezed == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: freezed == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      extraConditions: freezed == extraConditions
          ? _self._extraConditions
          : extraConditions // ignore: cast_nullable_to_non_nullable
              as List<ProjectFilterConditions>?,
    ));
  }
}

/// @nodoc
mixin _$FilteredPaginationParams {
  ProjectFilter get filter;
  int get page;
  int get limit;

  /// Create a copy of FilteredPaginationParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilteredPaginationParamsCopyWith<FilteredPaginationParams> get copyWith =>
      _$FilteredPaginationParamsCopyWithImpl<FilteredPaginationParams>(
          this as FilteredPaginationParams, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilteredPaginationParams &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filter, page, limit);

  @override
  String toString() {
    return 'FilteredPaginationParams(filter: $filter, page: $page, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class $FilteredPaginationParamsCopyWith<$Res> {
  factory $FilteredPaginationParamsCopyWith(FilteredPaginationParams value,
          $Res Function(FilteredPaginationParams) _then) =
      _$FilteredPaginationParamsCopyWithImpl;
  @useResult
  $Res call({ProjectFilter filter, int page, int limit});

  $ProjectFilterCopyWith<$Res> get filter;
}

/// @nodoc
class _$FilteredPaginationParamsCopyWithImpl<$Res>
    implements $FilteredPaginationParamsCopyWith<$Res> {
  _$FilteredPaginationParamsCopyWithImpl(this._self, this._then);

  final FilteredPaginationParams _self;
  final $Res Function(FilteredPaginationParams) _then;

  /// Create a copy of FilteredPaginationParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filter = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_self.copyWith(
      filter: null == filter
          ? _self.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as ProjectFilter,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  /// Create a copy of FilteredPaginationParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectFilterCopyWith<$Res> get filter {
    return $ProjectFilterCopyWith<$Res>(_self.filter, (value) {
      return _then(_self.copyWith(filter: value));
    });
  }
}

/// Adds pattern-matching-related methods to [FilteredPaginationParams].
extension FilteredPaginationParamsPatterns on FilteredPaginationParams {
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
    TResult Function(_FilteredPaginationParams value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilteredPaginationParams() when $default != null:
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
    TResult Function(_FilteredPaginationParams value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilteredPaginationParams():
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
    TResult? Function(_FilteredPaginationParams value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilteredPaginationParams() when $default != null:
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
    TResult Function(ProjectFilter filter, int page, int limit)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilteredPaginationParams() when $default != null:
        return $default(_that.filter, _that.page, _that.limit);
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
    TResult Function(ProjectFilter filter, int page, int limit) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilteredPaginationParams():
        return $default(_that.filter, _that.page, _that.limit);
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
    TResult? Function(ProjectFilter filter, int page, int limit)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilteredPaginationParams() when $default != null:
        return $default(_that.filter, _that.page, _that.limit);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FilteredPaginationParams implements FilteredPaginationParams {
  const _FilteredPaginationParams(
      {required this.filter, required this.page, required this.limit});

  @override
  final ProjectFilter filter;
  @override
  final int page;
  @override
  final int limit;

  /// Create a copy of FilteredPaginationParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FilteredPaginationParamsCopyWith<_FilteredPaginationParams> get copyWith =>
      __$FilteredPaginationParamsCopyWithImpl<_FilteredPaginationParams>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FilteredPaginationParams &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filter, page, limit);

  @override
  String toString() {
    return 'FilteredPaginationParams(filter: $filter, page: $page, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class _$FilteredPaginationParamsCopyWith<$Res>
    implements $FilteredPaginationParamsCopyWith<$Res> {
  factory _$FilteredPaginationParamsCopyWith(_FilteredPaginationParams value,
          $Res Function(_FilteredPaginationParams) _then) =
      __$FilteredPaginationParamsCopyWithImpl;
  @override
  @useResult
  $Res call({ProjectFilter filter, int page, int limit});

  @override
  $ProjectFilterCopyWith<$Res> get filter;
}

/// @nodoc
class __$FilteredPaginationParamsCopyWithImpl<$Res>
    implements _$FilteredPaginationParamsCopyWith<$Res> {
  __$FilteredPaginationParamsCopyWithImpl(this._self, this._then);

  final _FilteredPaginationParams _self;
  final $Res Function(_FilteredPaginationParams) _then;

  /// Create a copy of FilteredPaginationParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? filter = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_FilteredPaginationParams(
      filter: null == filter
          ? _self.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as ProjectFilter,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  /// Create a copy of FilteredPaginationParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectFilterCopyWith<$Res> get filter {
    return $ProjectFilterCopyWith<$Res>(_self.filter, (value) {
      return _then(_self.copyWith(filter: value));
    });
  }
}

/// @nodoc
mixin _$ProjectFilter {
  String? get status;
  String? get ownerId;
  String? get searchQuery;
  String? get priority;
  DateTime? get startDate;
  DateTime? get endDate;
  DateTime? get dueDateStart;
  DateTime? get dueDateEnd;
  List<String>? get tags;
  List<String>? get requiredTags;
  List<ProjectFilterConditions>? get extraConditions;
  String? get sortBy;
  bool get sortAscending;
  String? get viewName;
  bool get isSaved;
  String get viewMode;
  bool get addToDashboard;

  /// Create a copy of ProjectFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectFilterCopyWith<ProjectFilter> get copyWith =>
      _$ProjectFilterCopyWithImpl<ProjectFilter>(
          this as ProjectFilter, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectFilter &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.dueDateStart, dueDateStart) ||
                other.dueDateStart == dueDateStart) &&
            (identical(other.dueDateEnd, dueDateEnd) ||
                other.dueDateEnd == dueDateEnd) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality()
                .equals(other.requiredTags, requiredTags) &&
            const DeepCollectionEquality()
                .equals(other.extraConditions, extraConditions) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortAscending, sortAscending) ||
                other.sortAscending == sortAscending) &&
            (identical(other.viewName, viewName) ||
                other.viewName == viewName) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
            (identical(other.viewMode, viewMode) ||
                other.viewMode == viewMode) &&
            (identical(other.addToDashboard, addToDashboard) ||
                other.addToDashboard == addToDashboard));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      ownerId,
      searchQuery,
      priority,
      startDate,
      endDate,
      dueDateStart,
      dueDateEnd,
      const DeepCollectionEquality().hash(tags),
      const DeepCollectionEquality().hash(requiredTags),
      const DeepCollectionEquality().hash(extraConditions),
      sortBy,
      sortAscending,
      viewName,
      isSaved,
      viewMode,
      addToDashboard);

  @override
  String toString() {
    return 'ProjectFilter(status: $status, ownerId: $ownerId, searchQuery: $searchQuery, priority: $priority, startDate: $startDate, endDate: $endDate, dueDateStart: $dueDateStart, dueDateEnd: $dueDateEnd, tags: $tags, requiredTags: $requiredTags, extraConditions: $extraConditions, sortBy: $sortBy, sortAscending: $sortAscending, viewName: $viewName, isSaved: $isSaved, viewMode: $viewMode, addToDashboard: $addToDashboard)';
  }
}

/// @nodoc
abstract mixin class $ProjectFilterCopyWith<$Res> {
  factory $ProjectFilterCopyWith(
          ProjectFilter value, $Res Function(ProjectFilter) _then) =
      _$ProjectFilterCopyWithImpl;
  @useResult
  $Res call(
      {String? status,
      String? ownerId,
      String? searchQuery,
      String? priority,
      DateTime? startDate,
      DateTime? endDate,
      DateTime? dueDateStart,
      DateTime? dueDateEnd,
      List<String>? tags,
      List<String>? requiredTags,
      List<ProjectFilterConditions>? extraConditions,
      String? sortBy,
      bool sortAscending,
      String? viewName,
      bool isSaved,
      String viewMode,
      bool addToDashboard});
}

/// @nodoc
class _$ProjectFilterCopyWithImpl<$Res>
    implements $ProjectFilterCopyWith<$Res> {
  _$ProjectFilterCopyWithImpl(this._self, this._then);

  final ProjectFilter _self;
  final $Res Function(ProjectFilter) _then;

  /// Create a copy of ProjectFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = freezed,
    Object? ownerId = freezed,
    Object? searchQuery = freezed,
    Object? priority = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? dueDateStart = freezed,
    Object? dueDateEnd = freezed,
    Object? tags = freezed,
    Object? requiredTags = freezed,
    Object? extraConditions = freezed,
    Object? sortBy = freezed,
    Object? sortAscending = null,
    Object? viewName = freezed,
    Object? isSaved = null,
    Object? viewMode = null,
    Object? addToDashboard = null,
  }) {
    return _then(_self.copyWith(
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: freezed == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: freezed == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDateStart: freezed == dueDateStart
          ? _self.dueDateStart
          : dueDateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDateEnd: freezed == dueDateEnd
          ? _self.dueDateEnd
          : dueDateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tags: freezed == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      requiredTags: freezed == requiredTags
          ? _self.requiredTags
          : requiredTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      extraConditions: freezed == extraConditions
          ? _self.extraConditions
          : extraConditions // ignore: cast_nullable_to_non_nullable
              as List<ProjectFilterConditions>?,
      sortBy: freezed == sortBy
          ? _self.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String?,
      sortAscending: null == sortAscending
          ? _self.sortAscending
          : sortAscending // ignore: cast_nullable_to_non_nullable
              as bool,
      viewName: freezed == viewName
          ? _self.viewName
          : viewName // ignore: cast_nullable_to_non_nullable
              as String?,
      isSaved: null == isSaved
          ? _self.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
      viewMode: null == viewMode
          ? _self.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as String,
      addToDashboard: null == addToDashboard
          ? _self.addToDashboard
          : addToDashboard // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectFilter].
extension ProjectFilterPatterns on ProjectFilter {
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
    TResult Function(_ProjectFilter value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter() when $default != null:
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
    TResult Function(_ProjectFilter value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter():
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
    TResult? Function(_ProjectFilter value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter() when $default != null:
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
            String? status,
            String? ownerId,
            String? searchQuery,
            String? priority,
            DateTime? startDate,
            DateTime? endDate,
            DateTime? dueDateStart,
            DateTime? dueDateEnd,
            List<String>? tags,
            List<String>? requiredTags,
            List<ProjectFilterConditions>? extraConditions,
            String? sortBy,
            bool sortAscending,
            String? viewName,
            bool isSaved,
            String viewMode,
            bool addToDashboard)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter() when $default != null:
        return $default(
            _that.status,
            _that.ownerId,
            _that.searchQuery,
            _that.priority,
            _that.startDate,
            _that.endDate,
            _that.dueDateStart,
            _that.dueDateEnd,
            _that.tags,
            _that.requiredTags,
            _that.extraConditions,
            _that.sortBy,
            _that.sortAscending,
            _that.viewName,
            _that.isSaved,
            _that.viewMode,
            _that.addToDashboard);
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
            String? status,
            String? ownerId,
            String? searchQuery,
            String? priority,
            DateTime? startDate,
            DateTime? endDate,
            DateTime? dueDateStart,
            DateTime? dueDateEnd,
            List<String>? tags,
            List<String>? requiredTags,
            List<ProjectFilterConditions>? extraConditions,
            String? sortBy,
            bool sortAscending,
            String? viewName,
            bool isSaved,
            String viewMode,
            bool addToDashboard)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter():
        return $default(
            _that.status,
            _that.ownerId,
            _that.searchQuery,
            _that.priority,
            _that.startDate,
            _that.endDate,
            _that.dueDateStart,
            _that.dueDateEnd,
            _that.tags,
            _that.requiredTags,
            _that.extraConditions,
            _that.sortBy,
            _that.sortAscending,
            _that.viewName,
            _that.isSaved,
            _that.viewMode,
            _that.addToDashboard);
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
            String? status,
            String? ownerId,
            String? searchQuery,
            String? priority,
            DateTime? startDate,
            DateTime? endDate,
            DateTime? dueDateStart,
            DateTime? dueDateEnd,
            List<String>? tags,
            List<String>? requiredTags,
            List<ProjectFilterConditions>? extraConditions,
            String? sortBy,
            bool sortAscending,
            String? viewName,
            bool isSaved,
            String viewMode,
            bool addToDashboard)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter() when $default != null:
        return $default(
            _that.status,
            _that.ownerId,
            _that.searchQuery,
            _that.priority,
            _that.startDate,
            _that.endDate,
            _that.dueDateStart,
            _that.dueDateEnd,
            _that.tags,
            _that.requiredTags,
            _that.extraConditions,
            _that.sortBy,
            _that.sortAscending,
            _that.viewName,
            _that.isSaved,
            _that.viewMode,
            _that.addToDashboard);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectFilter extends ProjectFilter {
  const _ProjectFilter(
      {this.status,
      this.ownerId,
      this.searchQuery,
      this.priority,
      this.startDate,
      this.endDate,
      this.dueDateStart,
      this.dueDateEnd,
      final List<String>? tags,
      final List<String>? requiredTags,
      final List<ProjectFilterConditions>? extraConditions,
      this.sortBy,
      this.sortAscending = true,
      this.viewName,
      this.isSaved = false,
      this.viewMode = 'list',
      this.addToDashboard = false})
      : _tags = tags,
        _requiredTags = requiredTags,
        _extraConditions = extraConditions,
        super._();

  @override
  final String? status;
  @override
  final String? ownerId;
  @override
  final String? searchQuery;
  @override
  final String? priority;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final DateTime? dueDateStart;
  @override
  final DateTime? dueDateEnd;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _requiredTags;
  @override
  List<String>? get requiredTags {
    final value = _requiredTags;
    if (value == null) return null;
    if (_requiredTags is EqualUnmodifiableListView) return _requiredTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ProjectFilterConditions>? _extraConditions;
  @override
  List<ProjectFilterConditions>? get extraConditions {
    final value = _extraConditions;
    if (value == null) return null;
    if (_extraConditions is EqualUnmodifiableListView) return _extraConditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? sortBy;
  @override
  @JsonKey()
  final bool sortAscending;
  @override
  final String? viewName;
  @override
  @JsonKey()
  final bool isSaved;
  @override
  @JsonKey()
  final String viewMode;
  @override
  @JsonKey()
  final bool addToDashboard;

  /// Create a copy of ProjectFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectFilterCopyWith<_ProjectFilter> get copyWith =>
      __$ProjectFilterCopyWithImpl<_ProjectFilter>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectFilter &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.dueDateStart, dueDateStart) ||
                other.dueDateStart == dueDateStart) &&
            (identical(other.dueDateEnd, dueDateEnd) ||
                other.dueDateEnd == dueDateEnd) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._requiredTags, _requiredTags) &&
            const DeepCollectionEquality()
                .equals(other._extraConditions, _extraConditions) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortAscending, sortAscending) ||
                other.sortAscending == sortAscending) &&
            (identical(other.viewName, viewName) ||
                other.viewName == viewName) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
            (identical(other.viewMode, viewMode) ||
                other.viewMode == viewMode) &&
            (identical(other.addToDashboard, addToDashboard) ||
                other.addToDashboard == addToDashboard));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      ownerId,
      searchQuery,
      priority,
      startDate,
      endDate,
      dueDateStart,
      dueDateEnd,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_requiredTags),
      const DeepCollectionEquality().hash(_extraConditions),
      sortBy,
      sortAscending,
      viewName,
      isSaved,
      viewMode,
      addToDashboard);

  @override
  String toString() {
    return 'ProjectFilter(status: $status, ownerId: $ownerId, searchQuery: $searchQuery, priority: $priority, startDate: $startDate, endDate: $endDate, dueDateStart: $dueDateStart, dueDateEnd: $dueDateEnd, tags: $tags, requiredTags: $requiredTags, extraConditions: $extraConditions, sortBy: $sortBy, sortAscending: $sortAscending, viewName: $viewName, isSaved: $isSaved, viewMode: $viewMode, addToDashboard: $addToDashboard)';
  }
}

/// @nodoc
abstract mixin class _$ProjectFilterCopyWith<$Res>
    implements $ProjectFilterCopyWith<$Res> {
  factory _$ProjectFilterCopyWith(
          _ProjectFilter value, $Res Function(_ProjectFilter) _then) =
      __$ProjectFilterCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? status,
      String? ownerId,
      String? searchQuery,
      String? priority,
      DateTime? startDate,
      DateTime? endDate,
      DateTime? dueDateStart,
      DateTime? dueDateEnd,
      List<String>? tags,
      List<String>? requiredTags,
      List<ProjectFilterConditions>? extraConditions,
      String? sortBy,
      bool sortAscending,
      String? viewName,
      bool isSaved,
      String viewMode,
      bool addToDashboard});
}

/// @nodoc
class __$ProjectFilterCopyWithImpl<$Res>
    implements _$ProjectFilterCopyWith<$Res> {
  __$ProjectFilterCopyWithImpl(this._self, this._then);

  final _ProjectFilter _self;
  final $Res Function(_ProjectFilter) _then;

  /// Create a copy of ProjectFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = freezed,
    Object? ownerId = freezed,
    Object? searchQuery = freezed,
    Object? priority = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? dueDateStart = freezed,
    Object? dueDateEnd = freezed,
    Object? tags = freezed,
    Object? requiredTags = freezed,
    Object? extraConditions = freezed,
    Object? sortBy = freezed,
    Object? sortAscending = null,
    Object? viewName = freezed,
    Object? isSaved = null,
    Object? viewMode = null,
    Object? addToDashboard = null,
  }) {
    return _then(_ProjectFilter(
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: freezed == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: freezed == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDateStart: freezed == dueDateStart
          ? _self.dueDateStart
          : dueDateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueDateEnd: freezed == dueDateEnd
          ? _self.dueDateEnd
          : dueDateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tags: freezed == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      requiredTags: freezed == requiredTags
          ? _self._requiredTags
          : requiredTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      extraConditions: freezed == extraConditions
          ? _self._extraConditions
          : extraConditions // ignore: cast_nullable_to_non_nullable
              as List<ProjectFilterConditions>?,
      sortBy: freezed == sortBy
          ? _self.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String?,
      sortAscending: null == sortAscending
          ? _self.sortAscending
          : sortAscending // ignore: cast_nullable_to_non_nullable
              as bool,
      viewName: freezed == viewName
          ? _self.viewName
          : viewName // ignore: cast_nullable_to_non_nullable
              as String?,
      isSaved: null == isSaved
          ? _self.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
      viewMode: null == viewMode
          ? _self.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as String,
      addToDashboard: null == addToDashboard
          ? _self.addToDashboard
          : addToDashboard // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
