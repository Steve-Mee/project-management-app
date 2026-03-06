// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_planning_helpers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiApiResult<T> {
  T get content;
  int get tokensUsed;
  Map<String, dynamic> get metadata;

  /// Create a copy of AiApiResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiApiResultCopyWith<T, AiApiResult<T>> get copyWith =>
      _$AiApiResultCopyWithImpl<T, AiApiResult<T>>(
          this as AiApiResult<T>, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiApiResult<T> &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.tokensUsed, tokensUsed) ||
                other.tokensUsed == tokensUsed) &&
            const DeepCollectionEquality().equals(other.metadata, metadata));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(content),
      tokensUsed,
      const DeepCollectionEquality().hash(metadata));

  @override
  String toString() {
    return 'AiApiResult<$T>(content: $content, tokensUsed: $tokensUsed, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $AiApiResultCopyWith<T, $Res> {
  factory $AiApiResultCopyWith(
          AiApiResult<T> value, $Res Function(AiApiResult<T>) _then) =
      _$AiApiResultCopyWithImpl;
  @useResult
  $Res call({T content, int tokensUsed, Map<String, dynamic> metadata});
}

/// @nodoc
class _$AiApiResultCopyWithImpl<T, $Res>
    implements $AiApiResultCopyWith<T, $Res> {
  _$AiApiResultCopyWithImpl(this._self, this._then);

  final AiApiResult<T> _self;
  final $Res Function(AiApiResult<T>) _then;

  /// Create a copy of AiApiResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = freezed,
    Object? tokensUsed = null,
    Object? metadata = null,
  }) {
    return _then(_self.copyWith(
      content: freezed == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as T,
      tokensUsed: null == tokensUsed
          ? _self.tokensUsed
          : tokensUsed // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [AiApiResult].
extension AiApiResultPatterns<T> on AiApiResult<T> {
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
    TResult Function(_AiApiResult<T> value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiApiResult() when $default != null:
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
    TResult Function(_AiApiResult<T> value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiApiResult():
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
    TResult? Function(_AiApiResult<T> value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiApiResult() when $default != null:
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
    TResult Function(T content, int tokensUsed, Map<String, dynamic> metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiApiResult() when $default != null:
        return $default(_that.content, _that.tokensUsed, _that.metadata);
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
    TResult Function(T content, int tokensUsed, Map<String, dynamic> metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiApiResult():
        return $default(_that.content, _that.tokensUsed, _that.metadata);
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
    TResult? Function(T content, int tokensUsed, Map<String, dynamic> metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiApiResult() when $default != null:
        return $default(_that.content, _that.tokensUsed, _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AiApiResult<T> implements AiApiResult<T> {
  const _AiApiResult(
      {required this.content,
      required this.tokensUsed,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata;

  @override
  final T content;
  @override
  final int tokensUsed;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Create a copy of AiApiResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiApiResultCopyWith<T, _AiApiResult<T>> get copyWith =>
      __$AiApiResultCopyWithImpl<T, _AiApiResult<T>>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiApiResult<T> &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.tokensUsed, tokensUsed) ||
                other.tokensUsed == tokensUsed) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(content),
      tokensUsed,
      const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'AiApiResult<$T>(content: $content, tokensUsed: $tokensUsed, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$AiApiResultCopyWith<T, $Res>
    implements $AiApiResultCopyWith<T, $Res> {
  factory _$AiApiResultCopyWith(
          _AiApiResult<T> value, $Res Function(_AiApiResult<T>) _then) =
      __$AiApiResultCopyWithImpl;
  @override
  @useResult
  $Res call({T content, int tokensUsed, Map<String, dynamic> metadata});
}

/// @nodoc
class __$AiApiResultCopyWithImpl<T, $Res>
    implements _$AiApiResultCopyWith<T, $Res> {
  __$AiApiResultCopyWithImpl(this._self, this._then);

  final _AiApiResult<T> _self;
  final $Res Function(_AiApiResult<T>) _then;

  /// Create a copy of AiApiResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? content = freezed,
    Object? tokensUsed = null,
    Object? metadata = null,
  }) {
    return _then(_AiApiResult<T>(
      content: freezed == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as T,
      tokensUsed: null == tokensUsed
          ? _self.tokensUsed
          : tokensUsed // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

// dart format on
