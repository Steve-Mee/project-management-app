// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_viewers_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActiveViewer {
  String get userId;
  String? get displayName;
  String? get avatarUrl;
  DateTime get lastSeen;
  Map<String, dynamic>? get currentFilter;

  /// Create a copy of ActiveViewer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ActiveViewerCopyWith<ActiveViewer> get copyWith =>
      _$ActiveViewerCopyWithImpl<ActiveViewer>(
          this as ActiveViewer, _$identity);

  /// Serializes this ActiveViewer to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ActiveViewer &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            const DeepCollectionEquality()
                .equals(other.currentFilter, currentFilter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, displayName, avatarUrl,
      lastSeen, const DeepCollectionEquality().hash(currentFilter));

  @override
  String toString() {
    return 'ActiveViewer(userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, lastSeen: $lastSeen, currentFilter: $currentFilter)';
  }
}

/// @nodoc
abstract mixin class $ActiveViewerCopyWith<$Res> {
  factory $ActiveViewerCopyWith(
          ActiveViewer value, $Res Function(ActiveViewer) _then) =
      _$ActiveViewerCopyWithImpl;
  @useResult
  $Res call(
      {String userId,
      String? displayName,
      String? avatarUrl,
      DateTime lastSeen,
      Map<String, dynamic>? currentFilter});
}

/// @nodoc
class _$ActiveViewerCopyWithImpl<$Res> implements $ActiveViewerCopyWith<$Res> {
  _$ActiveViewerCopyWithImpl(this._self, this._then);

  final ActiveViewer _self;
  final $Res Function(ActiveViewer) _then;

  /// Create a copy of ActiveViewer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? lastSeen = null,
    Object? currentFilter = freezed,
  }) {
    return _then(_self.copyWith(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _self.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSeen: null == lastSeen
          ? _self.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentFilter: freezed == currentFilter
          ? _self.currentFilter
          : currentFilter // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ActiveViewer].
extension ActiveViewerPatterns on ActiveViewer {
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
    TResult Function(_ActiveViewer value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ActiveViewer() when $default != null:
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
    TResult Function(_ActiveViewer value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveViewer():
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
    TResult? Function(_ActiveViewer value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveViewer() when $default != null:
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
    TResult Function(String userId, String? displayName, String? avatarUrl,
            DateTime lastSeen, Map<String, dynamic>? currentFilter)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ActiveViewer() when $default != null:
        return $default(_that.userId, _that.displayName, _that.avatarUrl,
            _that.lastSeen, _that.currentFilter);
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
    TResult Function(String userId, String? displayName, String? avatarUrl,
            DateTime lastSeen, Map<String, dynamic>? currentFilter)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveViewer():
        return $default(_that.userId, _that.displayName, _that.avatarUrl,
            _that.lastSeen, _that.currentFilter);
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
    TResult? Function(String userId, String? displayName, String? avatarUrl,
            DateTime lastSeen, Map<String, dynamic>? currentFilter)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActiveViewer() when $default != null:
        return $default(_that.userId, _that.displayName, _that.avatarUrl,
            _that.lastSeen, _that.currentFilter);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ActiveViewer implements ActiveViewer {
  const _ActiveViewer(
      {required this.userId,
      this.displayName,
      this.avatarUrl,
      required this.lastSeen,
      final Map<String, dynamic>? currentFilter})
      : _currentFilter = currentFilter;
  factory _ActiveViewer.fromJson(Map<String, dynamic> json) =>
      _$ActiveViewerFromJson(json);

  @override
  final String userId;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;
  @override
  final DateTime lastSeen;
  final Map<String, dynamic>? _currentFilter;
  @override
  Map<String, dynamic>? get currentFilter {
    final value = _currentFilter;
    if (value == null) return null;
    if (_currentFilter is EqualUnmodifiableMapView) return _currentFilter;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of ActiveViewer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ActiveViewerCopyWith<_ActiveViewer> get copyWith =>
      __$ActiveViewerCopyWithImpl<_ActiveViewer>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ActiveViewerToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ActiveViewer &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            const DeepCollectionEquality()
                .equals(other._currentFilter, _currentFilter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, displayName, avatarUrl,
      lastSeen, const DeepCollectionEquality().hash(_currentFilter));

  @override
  String toString() {
    return 'ActiveViewer(userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, lastSeen: $lastSeen, currentFilter: $currentFilter)';
  }
}

/// @nodoc
abstract mixin class _$ActiveViewerCopyWith<$Res>
    implements $ActiveViewerCopyWith<$Res> {
  factory _$ActiveViewerCopyWith(
          _ActiveViewer value, $Res Function(_ActiveViewer) _then) =
      __$ActiveViewerCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String userId,
      String? displayName,
      String? avatarUrl,
      DateTime lastSeen,
      Map<String, dynamic>? currentFilter});
}

/// @nodoc
class __$ActiveViewerCopyWithImpl<$Res>
    implements _$ActiveViewerCopyWith<$Res> {
  __$ActiveViewerCopyWithImpl(this._self, this._then);

  final _ActiveViewer _self;
  final $Res Function(_ActiveViewer) _then;

  /// Create a copy of ActiveViewer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? lastSeen = null,
    Object? currentFilter = freezed,
  }) {
    return _then(_ActiveViewer(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _self.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSeen: null == lastSeen
          ? _self.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentFilter: freezed == currentFilter
          ? _self._currentFilter
          : currentFilter // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

// dart format on
