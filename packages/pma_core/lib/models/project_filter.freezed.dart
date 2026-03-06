// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectFilter {
  String? get status;
  DateTime? get startDate;
  DateTime? get endDate;
  String? get priority;
  List<String>? get tags;
  String? get searchQuery;

  /// Create a copy of ProjectFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectFilterCopyWith<ProjectFilter> get copyWith =>
      _$ProjectFilterCopyWithImpl<ProjectFilter>(
          this as ProjectFilter, _$identity);

  /// Serializes this ProjectFilter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectFilter &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, startDate, endDate,
      priority, const DeepCollectionEquality().hash(tags), searchQuery);

  @override
  String toString() {
    return 'ProjectFilter(status: $status, startDate: $startDate, endDate: $endDate, priority: $priority, tags: $tags, searchQuery: $searchQuery)';
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
      DateTime? startDate,
      DateTime? endDate,
      String? priority,
      List<String>? tags,
      String? searchQuery});
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
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? priority = freezed,
    Object? tags = freezed,
    Object? searchQuery = freezed,
  }) {
    return _then(_self.copyWith(
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
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
      tags: freezed == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      searchQuery: freezed == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
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
    TResult Function(String? status, DateTime? startDate, DateTime? endDate,
            String? priority, List<String>? tags, String? searchQuery)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter() when $default != null:
        return $default(_that.status, _that.startDate, _that.endDate,
            _that.priority, _that.tags, _that.searchQuery);
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
    TResult Function(String? status, DateTime? startDate, DateTime? endDate,
            String? priority, List<String>? tags, String? searchQuery)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter():
        return $default(_that.status, _that.startDate, _that.endDate,
            _that.priority, _that.tags, _that.searchQuery);
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
    TResult? Function(String? status, DateTime? startDate, DateTime? endDate,
            String? priority, List<String>? tags, String? searchQuery)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFilter() when $default != null:
        return $default(_that.status, _that.startDate, _that.endDate,
            _that.priority, _that.tags, _that.searchQuery);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProjectFilter extends ProjectFilter {
  const _ProjectFilter(
      {this.status,
      this.startDate,
      this.endDate,
      this.priority,
      final List<String>? tags,
      this.searchQuery})
      : _tags = tags,
        super._();
  factory _ProjectFilter.fromJson(Map<String, dynamic> json) =>
      _$ProjectFilterFromJson(json);

  @override
  final String? status;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final String? priority;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? searchQuery;

  /// Create a copy of ProjectFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectFilterCopyWith<_ProjectFilter> get copyWith =>
      __$ProjectFilterCopyWithImpl<_ProjectFilter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectFilterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectFilter &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, startDate, endDate,
      priority, const DeepCollectionEquality().hash(_tags), searchQuery);

  @override
  String toString() {
    return 'ProjectFilter(status: $status, startDate: $startDate, endDate: $endDate, priority: $priority, tags: $tags, searchQuery: $searchQuery)';
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
      DateTime? startDate,
      DateTime? endDate,
      String? priority,
      List<String>? tags,
      String? searchQuery});
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
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? priority = freezed,
    Object? tags = freezed,
    Object? searchQuery = freezed,
  }) {
    return _then(_ProjectFilter(
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
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
      tags: freezed == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      searchQuery: freezed == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
