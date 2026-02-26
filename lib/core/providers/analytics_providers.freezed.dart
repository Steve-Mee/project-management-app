// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiUsage {
  int get tokensUsed;
  int get monthlyLimit;

  /// Create a copy of AiUsage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiUsageCopyWith<AiUsage> get copyWith =>
      _$AiUsageCopyWithImpl<AiUsage>(this as AiUsage, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiUsage &&
            (identical(other.tokensUsed, tokensUsed) ||
                other.tokensUsed == tokensUsed) &&
            (identical(other.monthlyLimit, monthlyLimit) ||
                other.monthlyLimit == monthlyLimit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tokensUsed, monthlyLimit);

  @override
  String toString() {
    return 'AiUsage(tokensUsed: $tokensUsed, monthlyLimit: $monthlyLimit)';
  }
}

/// @nodoc
abstract mixin class $AiUsageCopyWith<$Res> {
  factory $AiUsageCopyWith(AiUsage value, $Res Function(AiUsage) _then) =
      _$AiUsageCopyWithImpl;
  @useResult
  $Res call({int tokensUsed, int monthlyLimit});
}

/// @nodoc
class _$AiUsageCopyWithImpl<$Res> implements $AiUsageCopyWith<$Res> {
  _$AiUsageCopyWithImpl(this._self, this._then);

  final AiUsage _self;
  final $Res Function(AiUsage) _then;

  /// Create a copy of AiUsage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tokensUsed = null,
    Object? monthlyLimit = null,
  }) {
    return _then(_self.copyWith(
      tokensUsed: null == tokensUsed
          ? _self.tokensUsed
          : tokensUsed // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyLimit: null == monthlyLimit
          ? _self.monthlyLimit
          : monthlyLimit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [AiUsage].
extension AiUsagePatterns on AiUsage {
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
    TResult Function(_AiUsage value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiUsage() when $default != null:
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
    TResult Function(_AiUsage value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsage():
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
    TResult? Function(_AiUsage value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsage() when $default != null:
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
    TResult Function(int tokensUsed, int monthlyLimit)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiUsage() when $default != null:
        return $default(_that.tokensUsed, _that.monthlyLimit);
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
    TResult Function(int tokensUsed, int monthlyLimit) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsage():
        return $default(_that.tokensUsed, _that.monthlyLimit);
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
    TResult? Function(int tokensUsed, int monthlyLimit)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsage() when $default != null:
        return $default(_that.tokensUsed, _that.monthlyLimit);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AiUsage extends AiUsage {
  const _AiUsage({this.tokensUsed = 0, this.monthlyLimit = 100000}) : super._();

  @override
  @JsonKey()
  final int tokensUsed;
  @override
  @JsonKey()
  final int monthlyLimit;

  /// Create a copy of AiUsage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiUsageCopyWith<_AiUsage> get copyWith =>
      __$AiUsageCopyWithImpl<_AiUsage>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiUsage &&
            (identical(other.tokensUsed, tokensUsed) ||
                other.tokensUsed == tokensUsed) &&
            (identical(other.monthlyLimit, monthlyLimit) ||
                other.monthlyLimit == monthlyLimit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tokensUsed, monthlyLimit);

  @override
  String toString() {
    return 'AiUsage(tokensUsed: $tokensUsed, monthlyLimit: $monthlyLimit)';
  }
}

/// @nodoc
abstract mixin class _$AiUsageCopyWith<$Res> implements $AiUsageCopyWith<$Res> {
  factory _$AiUsageCopyWith(_AiUsage value, $Res Function(_AiUsage) _then) =
      __$AiUsageCopyWithImpl;
  @override
  @useResult
  $Res call({int tokensUsed, int monthlyLimit});
}

/// @nodoc
class __$AiUsageCopyWithImpl<$Res> implements _$AiUsageCopyWith<$Res> {
  __$AiUsageCopyWithImpl(this._self, this._then);

  final _AiUsage _self;
  final $Res Function(_AiUsage) _then;

  /// Create a copy of AiUsage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tokensUsed = null,
    Object? monthlyLimit = null,
  }) {
    return _then(_AiUsage(
      tokensUsed: null == tokensUsed
          ? _self.tokensUsed
          : tokensUsed // ignore: cast_nullable_to_non_nullable
              as int,
      monthlyLimit: null == monthlyLimit
          ? _self.monthlyLimit
          : monthlyLimit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
