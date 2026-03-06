// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectInvitation {
  String get id;
  String get email;
  @JsonKey(name: 'project_id')
  String get projectId;
  String get role;
  @JsonKey(name: 'invited_by')
  String get invitedBy;
  String get status;
  String? get token;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of ProjectInvitation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectInvitationCopyWith<ProjectInvitation> get copyWith =>
      _$ProjectInvitationCopyWithImpl<ProjectInvitation>(
          this as ProjectInvitation, _$identity);

  /// Serializes this ProjectInvitation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectInvitation &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.invitedBy, invitedBy) ||
                other.invitedBy == invitedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, projectId, role,
      invitedBy, status, token, createdAt, updatedAt);

  @override
  String toString() {
    return 'ProjectInvitation(id: $id, email: $email, projectId: $projectId, role: $role, invitedBy: $invitedBy, status: $status, token: $token, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ProjectInvitationCopyWith<$Res> {
  factory $ProjectInvitationCopyWith(
          ProjectInvitation value, $Res Function(ProjectInvitation) _then) =
      _$ProjectInvitationCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'project_id') String projectId,
      String role,
      @JsonKey(name: 'invited_by') String invitedBy,
      String status,
      String? token,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ProjectInvitationCopyWithImpl<$Res>
    implements $ProjectInvitationCopyWith<$Res> {
  _$ProjectInvitationCopyWithImpl(this._self, this._then);

  final ProjectInvitation _self;
  final $Res Function(ProjectInvitation) _then;

  /// Create a copy of ProjectInvitation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? projectId = null,
    Object? role = null,
    Object? invitedBy = null,
    Object? status = null,
    Object? token = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      invitedBy: null == invitedBy
          ? _self.invitedBy
          : invitedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      token: freezed == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectInvitation].
extension ProjectInvitationPatterns on ProjectInvitation {
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
    TResult Function(_ProjectInvitation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectInvitation() when $default != null:
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
    TResult Function(_ProjectInvitation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectInvitation():
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
    TResult? Function(_ProjectInvitation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectInvitation() when $default != null:
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
            String email,
            @JsonKey(name: 'project_id') String projectId,
            String role,
            @JsonKey(name: 'invited_by') String invitedBy,
            String status,
            String? token,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectInvitation() when $default != null:
        return $default(
            _that.id,
            _that.email,
            _that.projectId,
            _that.role,
            _that.invitedBy,
            _that.status,
            _that.token,
            _that.createdAt,
            _that.updatedAt);
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
            String email,
            @JsonKey(name: 'project_id') String projectId,
            String role,
            @JsonKey(name: 'invited_by') String invitedBy,
            String status,
            String? token,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectInvitation():
        return $default(
            _that.id,
            _that.email,
            _that.projectId,
            _that.role,
            _that.invitedBy,
            _that.status,
            _that.token,
            _that.createdAt,
            _that.updatedAt);
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
            String email,
            @JsonKey(name: 'project_id') String projectId,
            String role,
            @JsonKey(name: 'invited_by') String invitedBy,
            String status,
            String? token,
            @JsonKey(name: 'created_at') DateTime createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectInvitation() when $default != null:
        return $default(
            _that.id,
            _that.email,
            _that.projectId,
            _that.role,
            _that.invitedBy,
            _that.status,
            _that.token,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProjectInvitation extends ProjectInvitation {
  const _ProjectInvitation(
      {required this.id,
      required this.email,
      @JsonKey(name: 'project_id') required this.projectId,
      required this.role,
      @JsonKey(name: 'invited_by') required this.invitedBy,
      required this.status,
      this.token,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : super._();
  factory _ProjectInvitation.fromJson(Map<String, dynamic> json) =>
      _$ProjectInvitationFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  final String role;
  @override
  @JsonKey(name: 'invited_by')
  final String invitedBy;
  @override
  final String status;
  @override
  final String? token;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of ProjectInvitation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectInvitationCopyWith<_ProjectInvitation> get copyWith =>
      __$ProjectInvitationCopyWithImpl<_ProjectInvitation>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectInvitationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectInvitation &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.invitedBy, invitedBy) ||
                other.invitedBy == invitedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, projectId, role,
      invitedBy, status, token, createdAt, updatedAt);

  @override
  String toString() {
    return 'ProjectInvitation(id: $id, email: $email, projectId: $projectId, role: $role, invitedBy: $invitedBy, status: $status, token: $token, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ProjectInvitationCopyWith<$Res>
    implements $ProjectInvitationCopyWith<$Res> {
  factory _$ProjectInvitationCopyWith(
          _ProjectInvitation value, $Res Function(_ProjectInvitation) _then) =
      __$ProjectInvitationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'project_id') String projectId,
      String role,
      @JsonKey(name: 'invited_by') String invitedBy,
      String status,
      String? token,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$ProjectInvitationCopyWithImpl<$Res>
    implements _$ProjectInvitationCopyWith<$Res> {
  __$ProjectInvitationCopyWithImpl(this._self, this._then);

  final _ProjectInvitation _self;
  final $Res Function(_ProjectInvitation) _then;

  /// Create a copy of ProjectInvitation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? projectId = null,
    Object? role = null,
    Object? invitedBy = null,
    Object? status = null,
    Object? token = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_ProjectInvitation(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      invitedBy: null == invitedBy
          ? _self.invitedBy
          : invitedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      token: freezed == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
