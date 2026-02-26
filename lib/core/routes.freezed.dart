// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NavigationItem {
  String get label;
  IconData get icon;
  String get routeName;
  String? get routePath;

  /// Create a copy of NavigationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NavigationItemCopyWith<NavigationItem> get copyWith =>
      _$NavigationItemCopyWithImpl<NavigationItem>(
          this as NavigationItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NavigationItem &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.routeName, routeName) ||
                other.routeName == routeName) &&
            (identical(other.routePath, routePath) ||
                other.routePath == routePath));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, label, icon, routeName, routePath);

  @override
  String toString() {
    return 'NavigationItem(label: $label, icon: $icon, routeName: $routeName, routePath: $routePath)';
  }
}

/// @nodoc
abstract mixin class $NavigationItemCopyWith<$Res> {
  factory $NavigationItemCopyWith(
          NavigationItem value, $Res Function(NavigationItem) _then) =
      _$NavigationItemCopyWithImpl;
  @useResult
  $Res call({String label, IconData icon, String routeName, String? routePath});
}

/// @nodoc
class _$NavigationItemCopyWithImpl<$Res>
    implements $NavigationItemCopyWith<$Res> {
  _$NavigationItemCopyWithImpl(this._self, this._then);

  final NavigationItem _self;
  final $Res Function(NavigationItem) _then;

  /// Create a copy of NavigationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? icon = null,
    Object? routeName = null,
    Object? routePath = freezed,
  }) {
    return _then(_self.copyWith(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as IconData,
      routeName: null == routeName
          ? _self.routeName
          : routeName // ignore: cast_nullable_to_non_nullable
              as String,
      routePath: freezed == routePath
          ? _self.routePath
          : routePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [NavigationItem].
extension NavigationItemPatterns on NavigationItem {
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
    TResult Function(_NavigationItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NavigationItem() when $default != null:
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
    TResult Function(_NavigationItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NavigationItem():
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
    TResult? Function(_NavigationItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NavigationItem() when $default != null:
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
            String label, IconData icon, String routeName, String? routePath)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NavigationItem() when $default != null:
        return $default(
            _that.label, _that.icon, _that.routeName, _that.routePath);
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
            String label, IconData icon, String routeName, String? routePath)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NavigationItem():
        return $default(
            _that.label, _that.icon, _that.routeName, _that.routePath);
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
            String label, IconData icon, String routeName, String? routePath)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NavigationItem() when $default != null:
        return $default(
            _that.label, _that.icon, _that.routeName, _that.routePath);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _NavigationItem implements NavigationItem {
  const _NavigationItem(
      {required this.label,
      required this.icon,
      required this.routeName,
      this.routePath});

  @override
  final String label;
  @override
  final IconData icon;
  @override
  final String routeName;
  @override
  final String? routePath;

  /// Create a copy of NavigationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NavigationItemCopyWith<_NavigationItem> get copyWith =>
      __$NavigationItemCopyWithImpl<_NavigationItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NavigationItem &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.routeName, routeName) ||
                other.routeName == routeName) &&
            (identical(other.routePath, routePath) ||
                other.routePath == routePath));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, label, icon, routeName, routePath);

  @override
  String toString() {
    return 'NavigationItem(label: $label, icon: $icon, routeName: $routeName, routePath: $routePath)';
  }
}

/// @nodoc
abstract mixin class _$NavigationItemCopyWith<$Res>
    implements $NavigationItemCopyWith<$Res> {
  factory _$NavigationItemCopyWith(
          _NavigationItem value, $Res Function(_NavigationItem) _then) =
      __$NavigationItemCopyWithImpl;
  @override
  @useResult
  $Res call({String label, IconData icon, String routeName, String? routePath});
}

/// @nodoc
class __$NavigationItemCopyWithImpl<$Res>
    implements _$NavigationItemCopyWith<$Res> {
  __$NavigationItemCopyWithImpl(this._self, this._then);

  final _NavigationItem _self;
  final $Res Function(_NavigationItem) _then;

  /// Create a copy of NavigationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? label = null,
    Object? icon = null,
    Object? routeName = null,
    Object? routePath = freezed,
  }) {
    return _then(_NavigationItem(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as IconData,
      routeName: null == routeName
          ? _self.routeName
          : routeName // ignore: cast_nullable_to_non_nullable
              as String,
      routePath: freezed == routePath
          ? _self.routePath
          : routePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
