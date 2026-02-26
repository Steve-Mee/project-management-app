// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'role_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoleDefinition {
  String get id;
  String get name;
  List<String> get permissions;

  /// Create a copy of RoleDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoleDefinitionCopyWith<RoleDefinition> get copyWith =>
      _$RoleDefinitionCopyWithImpl<RoleDefinition>(
          this as RoleDefinition, _$identity);

  /// Serializes this RoleDefinition to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoleDefinition &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other.permissions, permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, const DeepCollectionEquality().hash(permissions));

  @override
  String toString() {
    return 'RoleDefinition(id: $id, name: $name, permissions: $permissions)';
  }
}

/// @nodoc
abstract mixin class $RoleDefinitionCopyWith<$Res> {
  factory $RoleDefinitionCopyWith(
          RoleDefinition value, $Res Function(RoleDefinition) _then) =
      _$RoleDefinitionCopyWithImpl;
  @useResult
  $Res call({String id, String name, List<String> permissions});
}

/// @nodoc
class _$RoleDefinitionCopyWithImpl<$Res>
    implements $RoleDefinitionCopyWith<$Res> {
  _$RoleDefinitionCopyWithImpl(this._self, this._then);

  final RoleDefinition _self;
  final $Res Function(RoleDefinition) _then;

  /// Create a copy of RoleDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? permissions = null,
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
      permissions: null == permissions
          ? _self.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RoleDefinition].
extension RoleDefinitionPatterns on RoleDefinition {
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
    TResult Function(_RoleDefinition value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoleDefinition() when $default != null:
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
    TResult Function(_RoleDefinition value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoleDefinition():
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
    TResult? Function(_RoleDefinition value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoleDefinition() when $default != null:
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
    TResult Function(String id, String name, List<String> permissions)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoleDefinition() when $default != null:
        return $default(_that.id, _that.name, _that.permissions);
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
    TResult Function(String id, String name, List<String> permissions) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoleDefinition():
        return $default(_that.id, _that.name, _that.permissions);
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
    TResult? Function(String id, String name, List<String> permissions)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoleDefinition() when $default != null:
        return $default(_that.id, _that.name, _that.permissions);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoleDefinition extends RoleDefinition {
  const _RoleDefinition(
      {this.id = '',
      this.name = '',
      final List<String> permissions = const <String>[]})
      : _permissions = permissions,
        super._();
  factory _RoleDefinition.fromJson(Map<String, dynamic> json) =>
      _$RoleDefinitionFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String name;
  final List<String> _permissions;
  @override
  @JsonKey()
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  /// Create a copy of RoleDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoleDefinitionCopyWith<_RoleDefinition> get copyWith =>
      __$RoleDefinitionCopyWithImpl<_RoleDefinition>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RoleDefinitionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoleDefinition &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, const DeepCollectionEquality().hash(_permissions));

  @override
  String toString() {
    return 'RoleDefinition(id: $id, name: $name, permissions: $permissions)';
  }
}

/// @nodoc
abstract mixin class _$RoleDefinitionCopyWith<$Res>
    implements $RoleDefinitionCopyWith<$Res> {
  factory _$RoleDefinitionCopyWith(
          _RoleDefinition value, $Res Function(_RoleDefinition) _then) =
      __$RoleDefinitionCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, List<String> permissions});
}

/// @nodoc
class __$RoleDefinitionCopyWithImpl<$Res>
    implements _$RoleDefinitionCopyWith<$Res> {
  __$RoleDefinitionCopyWithImpl(this._self, this._then);

  final _RoleDefinition _self;
  final $Res Function(_RoleDefinition) _then;

  /// Create a copy of RoleDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? permissions = null,
  }) {
    return _then(_RoleDefinition(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: null == permissions
          ? _self._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
mixin _$GroupDefinition {
  String get id;
  String get name;
  String get roleId;
  List<String> get members;

  /// Create a copy of GroupDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupDefinitionCopyWith<GroupDefinition> get copyWith =>
      _$GroupDefinitionCopyWithImpl<GroupDefinition>(
          this as GroupDefinition, _$identity);

  /// Serializes this GroupDefinition to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupDefinition &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            const DeepCollectionEquality().equals(other.members, members));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, roleId,
      const DeepCollectionEquality().hash(members));

  @override
  String toString() {
    return 'GroupDefinition(id: $id, name: $name, roleId: $roleId, members: $members)';
  }
}

/// @nodoc
abstract mixin class $GroupDefinitionCopyWith<$Res> {
  factory $GroupDefinitionCopyWith(
          GroupDefinition value, $Res Function(GroupDefinition) _then) =
      _$GroupDefinitionCopyWithImpl;
  @useResult
  $Res call({String id, String name, String roleId, List<String> members});
}

/// @nodoc
class _$GroupDefinitionCopyWithImpl<$Res>
    implements $GroupDefinitionCopyWith<$Res> {
  _$GroupDefinitionCopyWithImpl(this._self, this._then);

  final GroupDefinition _self;
  final $Res Function(GroupDefinition) _then;

  /// Create a copy of GroupDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? roleId = null,
    Object? members = null,
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
      roleId: null == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _self.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [GroupDefinition].
extension GroupDefinitionPatterns on GroupDefinition {
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
    TResult Function(_GroupDefinition value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupDefinition() when $default != null:
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
    TResult Function(_GroupDefinition value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupDefinition():
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
    TResult? Function(_GroupDefinition value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupDefinition() when $default != null:
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
            String id, String name, String roleId, List<String> members)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupDefinition() when $default != null:
        return $default(_that.id, _that.name, _that.roleId, _that.members);
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
            String id, String name, String roleId, List<String> members)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupDefinition():
        return $default(_that.id, _that.name, _that.roleId, _that.members);
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
            String id, String name, String roleId, List<String> members)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupDefinition() when $default != null:
        return $default(_that.id, _that.name, _that.roleId, _that.members);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GroupDefinition extends GroupDefinition {
  const _GroupDefinition(
      {this.id = '',
      this.name = '',
      this.roleId = '',
      final List<String> members = const <String>[]})
      : _members = members,
        super._();
  factory _GroupDefinition.fromJson(Map<String, dynamic> json) =>
      _$GroupDefinitionFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String roleId;
  final List<String> _members;
  @override
  @JsonKey()
  List<String> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  /// Create a copy of GroupDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupDefinitionCopyWith<_GroupDefinition> get copyWith =>
      __$GroupDefinitionCopyWithImpl<_GroupDefinition>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupDefinitionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupDefinition &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, roleId,
      const DeepCollectionEquality().hash(_members));

  @override
  String toString() {
    return 'GroupDefinition(id: $id, name: $name, roleId: $roleId, members: $members)';
  }
}

/// @nodoc
abstract mixin class _$GroupDefinitionCopyWith<$Res>
    implements $GroupDefinitionCopyWith<$Res> {
  factory _$GroupDefinitionCopyWith(
          _GroupDefinition value, $Res Function(_GroupDefinition) _then) =
      __$GroupDefinitionCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, String roleId, List<String> members});
}

/// @nodoc
class __$GroupDefinitionCopyWithImpl<$Res>
    implements _$GroupDefinitionCopyWith<$Res> {
  __$GroupDefinitionCopyWithImpl(this._self, this._then);

  final _GroupDefinition _self;
  final $Res Function(_GroupDefinition) _then;

  /// Create a copy of GroupDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? roleId = null,
    Object? members = null,
  }) {
    return _then(_GroupDefinition(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      roleId: null == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _self._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
