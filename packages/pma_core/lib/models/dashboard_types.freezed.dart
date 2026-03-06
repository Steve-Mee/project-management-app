// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SharedDashboard {
  String get id;
  String get ownerId;
  String get title;
  List<DashboardItem> get items;
  @JsonKey(
      fromJson: _sharedDashboardPermissionsFromJson,
      toJson: _sharedDashboardPermissionsToJson)
  Map<String, String> get permissions;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of SharedDashboard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SharedDashboardCopyWith<SharedDashboard> get copyWith =>
      _$SharedDashboardCopyWithImpl<SharedDashboard>(
          this as SharedDashboard, _$identity);

  /// Serializes this SharedDashboard to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SharedDashboard &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other.items, items) &&
            const DeepCollectionEquality()
                .equals(other.permissions, permissions) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerId,
      title,
      const DeepCollectionEquality().hash(items),
      const DeepCollectionEquality().hash(permissions),
      updatedAt);

  @override
  String toString() {
    return 'SharedDashboard(id: $id, ownerId: $ownerId, title: $title, items: $items, permissions: $permissions, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $SharedDashboardCopyWith<$Res> {
  factory $SharedDashboardCopyWith(
          SharedDashboard value, $Res Function(SharedDashboard) _then) =
      _$SharedDashboardCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String title,
      List<DashboardItem> items,
      @JsonKey(
          fromJson: _sharedDashboardPermissionsFromJson,
          toJson: _sharedDashboardPermissionsToJson)
      Map<String, String> permissions,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$SharedDashboardCopyWithImpl<$Res>
    implements $SharedDashboardCopyWith<$Res> {
  _$SharedDashboardCopyWithImpl(this._self, this._then);

  final SharedDashboard _self;
  final $Res Function(SharedDashboard) _then;

  /// Create a copy of SharedDashboard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? items = null,
    Object? permissions = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DashboardItem>,
      permissions: null == permissions
          ? _self.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [SharedDashboard].
extension SharedDashboardPatterns on SharedDashboard {
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
    TResult Function(_SharedDashboard value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SharedDashboard() when $default != null:
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
    TResult Function(_SharedDashboard value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedDashboard():
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
    TResult? Function(_SharedDashboard value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedDashboard() when $default != null:
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
            String ownerId,
            String title,
            List<DashboardItem> items,
            @JsonKey(
                fromJson: _sharedDashboardPermissionsFromJson,
                toJson: _sharedDashboardPermissionsToJson)
            Map<String, String> permissions,
            @JsonKey(name: 'updated_at') DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SharedDashboard() when $default != null:
        return $default(_that.id, _that.ownerId, _that.title, _that.items,
            _that.permissions, _that.updatedAt);
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
            String ownerId,
            String title,
            List<DashboardItem> items,
            @JsonKey(
                fromJson: _sharedDashboardPermissionsFromJson,
                toJson: _sharedDashboardPermissionsToJson)
            Map<String, String> permissions,
            @JsonKey(name: 'updated_at') DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedDashboard():
        return $default(_that.id, _that.ownerId, _that.title, _that.items,
            _that.permissions, _that.updatedAt);
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
            String ownerId,
            String title,
            List<DashboardItem> items,
            @JsonKey(
                fromJson: _sharedDashboardPermissionsFromJson,
                toJson: _sharedDashboardPermissionsToJson)
            Map<String, String> permissions,
            @JsonKey(name: 'updated_at') DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SharedDashboard() when $default != null:
        return $default(_that.id, _that.ownerId, _that.title, _that.items,
            _that.permissions, _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SharedDashboard implements SharedDashboard {
  const _SharedDashboard(
      {required this.id,
      required this.ownerId,
      required this.title,
      required final List<DashboardItem> items,
      @JsonKey(
          fromJson: _sharedDashboardPermissionsFromJson,
          toJson: _sharedDashboardPermissionsToJson)
      required final Map<String, String> permissions,
      @JsonKey(name: 'updated_at') required this.updatedAt})
      : _items = items,
        _permissions = permissions;
  factory _SharedDashboard.fromJson(Map<String, dynamic> json) =>
      _$SharedDashboardFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String title;
  final List<DashboardItem> _items;
  @override
  List<DashboardItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final Map<String, String> _permissions;
  @override
  @JsonKey(
      fromJson: _sharedDashboardPermissionsFromJson,
      toJson: _sharedDashboardPermissionsToJson)
  Map<String, String> get permissions {
    if (_permissions is EqualUnmodifiableMapView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_permissions);
  }

  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// Create a copy of SharedDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SharedDashboardCopyWith<_SharedDashboard> get copyWith =>
      __$SharedDashboardCopyWithImpl<_SharedDashboard>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SharedDashboardToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SharedDashboard &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerId,
      title,
      const DeepCollectionEquality().hash(_items),
      const DeepCollectionEquality().hash(_permissions),
      updatedAt);

  @override
  String toString() {
    return 'SharedDashboard(id: $id, ownerId: $ownerId, title: $title, items: $items, permissions: $permissions, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$SharedDashboardCopyWith<$Res>
    implements $SharedDashboardCopyWith<$Res> {
  factory _$SharedDashboardCopyWith(
          _SharedDashboard value, $Res Function(_SharedDashboard) _then) =
      __$SharedDashboardCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String title,
      List<DashboardItem> items,
      @JsonKey(
          fromJson: _sharedDashboardPermissionsFromJson,
          toJson: _sharedDashboardPermissionsToJson)
      Map<String, String> permissions,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$SharedDashboardCopyWithImpl<$Res>
    implements _$SharedDashboardCopyWith<$Res> {
  __$SharedDashboardCopyWithImpl(this._self, this._then);

  final _SharedDashboard _self;
  final $Res Function(_SharedDashboard) _then;

  /// Create a copy of SharedDashboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? items = null,
    Object? permissions = null,
    Object? updatedAt = null,
  }) {
    return _then(_SharedDashboard(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _self.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DashboardItem>,
      permissions: null == permissions
          ? _self._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
