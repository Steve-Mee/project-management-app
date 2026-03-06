// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_rate_limits_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiRateLimitsConfig {
  int get maxRequestsPerMinute;
  int get maxRequestsPerHour;
  int get maxRequestsPerDay;
  int get maxTokensPerRequest;
  int get maxTotalTokensPerDay;
  int get maxRequestsPerWindow;
  @JsonKey(
      name: 'timeWindowDurationSeconds',
      fromJson: _durationSecondsFromJson,
      toJson: _durationSecondsToJson)
  Duration get timeWindowDuration;
  @JsonKey(
      name: 'backoffBaseDelayMs',
      fromJson: _durationMsFromJson,
      toJson: _durationMsToJson)
  Duration get backoffBaseDelay;
  @JsonKey(
      name: 'backoffMaxDelaySeconds',
      fromJson: _durationSecondsFromJson,
      toJson: _durationSecondsToJson)
  Duration get backoffMaxDelay;
  int get maxRetryAttempts;
  bool get queueEnabled;
  @JsonKey(
      fromJson: _perOperationLimitsFromJson, toJson: _perOperationLimitsToJson)
  Map<String, int> get perOperationLimits;

  /// Create a copy of AiRateLimitsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiRateLimitsConfigCopyWith<AiRateLimitsConfig> get copyWith =>
      _$AiRateLimitsConfigCopyWithImpl<AiRateLimitsConfig>(
          this as AiRateLimitsConfig, _$identity);

  /// Serializes this AiRateLimitsConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiRateLimitsConfig &&
            (identical(other.maxRequestsPerMinute, maxRequestsPerMinute) ||
                other.maxRequestsPerMinute == maxRequestsPerMinute) &&
            (identical(other.maxRequestsPerHour, maxRequestsPerHour) ||
                other.maxRequestsPerHour == maxRequestsPerHour) &&
            (identical(other.maxRequestsPerDay, maxRequestsPerDay) ||
                other.maxRequestsPerDay == maxRequestsPerDay) &&
            (identical(other.maxTokensPerRequest, maxTokensPerRequest) ||
                other.maxTokensPerRequest == maxTokensPerRequest) &&
            (identical(other.maxTotalTokensPerDay, maxTotalTokensPerDay) ||
                other.maxTotalTokensPerDay == maxTotalTokensPerDay) &&
            (identical(other.maxRequestsPerWindow, maxRequestsPerWindow) ||
                other.maxRequestsPerWindow == maxRequestsPerWindow) &&
            (identical(other.timeWindowDuration, timeWindowDuration) ||
                other.timeWindowDuration == timeWindowDuration) &&
            (identical(other.backoffBaseDelay, backoffBaseDelay) ||
                other.backoffBaseDelay == backoffBaseDelay) &&
            (identical(other.backoffMaxDelay, backoffMaxDelay) ||
                other.backoffMaxDelay == backoffMaxDelay) &&
            (identical(other.maxRetryAttempts, maxRetryAttempts) ||
                other.maxRetryAttempts == maxRetryAttempts) &&
            (identical(other.queueEnabled, queueEnabled) ||
                other.queueEnabled == queueEnabled) &&
            const DeepCollectionEquality()
                .equals(other.perOperationLimits, perOperationLimits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      maxRequestsPerMinute,
      maxRequestsPerHour,
      maxRequestsPerDay,
      maxTokensPerRequest,
      maxTotalTokensPerDay,
      maxRequestsPerWindow,
      timeWindowDuration,
      backoffBaseDelay,
      backoffMaxDelay,
      maxRetryAttempts,
      queueEnabled,
      const DeepCollectionEquality().hash(perOperationLimits));

  @override
  String toString() {
    return 'AiRateLimitsConfig(maxRequestsPerMinute: $maxRequestsPerMinute, maxRequestsPerHour: $maxRequestsPerHour, maxRequestsPerDay: $maxRequestsPerDay, maxTokensPerRequest: $maxTokensPerRequest, maxTotalTokensPerDay: $maxTotalTokensPerDay, maxRequestsPerWindow: $maxRequestsPerWindow, timeWindowDuration: $timeWindowDuration, backoffBaseDelay: $backoffBaseDelay, backoffMaxDelay: $backoffMaxDelay, maxRetryAttempts: $maxRetryAttempts, queueEnabled: $queueEnabled, perOperationLimits: $perOperationLimits)';
  }
}

/// @nodoc
abstract mixin class $AiRateLimitsConfigCopyWith<$Res> {
  factory $AiRateLimitsConfigCopyWith(
          AiRateLimitsConfig value, $Res Function(AiRateLimitsConfig) _then) =
      _$AiRateLimitsConfigCopyWithImpl;
  @useResult
  $Res call(
      {int maxRequestsPerMinute,
      int maxRequestsPerHour,
      int maxRequestsPerDay,
      int maxTokensPerRequest,
      int maxTotalTokensPerDay,
      int maxRequestsPerWindow,
      @JsonKey(
          name: 'timeWindowDurationSeconds',
          fromJson: _durationSecondsFromJson,
          toJson: _durationSecondsToJson)
      Duration timeWindowDuration,
      @JsonKey(
          name: 'backoffBaseDelayMs',
          fromJson: _durationMsFromJson,
          toJson: _durationMsToJson)
      Duration backoffBaseDelay,
      @JsonKey(
          name: 'backoffMaxDelaySeconds',
          fromJson: _durationSecondsFromJson,
          toJson: _durationSecondsToJson)
      Duration backoffMaxDelay,
      int maxRetryAttempts,
      bool queueEnabled,
      @JsonKey(
          fromJson: _perOperationLimitsFromJson,
          toJson: _perOperationLimitsToJson)
      Map<String, int> perOperationLimits});
}

/// @nodoc
class _$AiRateLimitsConfigCopyWithImpl<$Res>
    implements $AiRateLimitsConfigCopyWith<$Res> {
  _$AiRateLimitsConfigCopyWithImpl(this._self, this._then);

  final AiRateLimitsConfig _self;
  final $Res Function(AiRateLimitsConfig) _then;

  /// Create a copy of AiRateLimitsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxRequestsPerMinute = null,
    Object? maxRequestsPerHour = null,
    Object? maxRequestsPerDay = null,
    Object? maxTokensPerRequest = null,
    Object? maxTotalTokensPerDay = null,
    Object? maxRequestsPerWindow = null,
    Object? timeWindowDuration = null,
    Object? backoffBaseDelay = null,
    Object? backoffMaxDelay = null,
    Object? maxRetryAttempts = null,
    Object? queueEnabled = null,
    Object? perOperationLimits = null,
  }) {
    return _then(_self.copyWith(
      maxRequestsPerMinute: null == maxRequestsPerMinute
          ? _self.maxRequestsPerMinute
          : maxRequestsPerMinute // ignore: cast_nullable_to_non_nullable
              as int,
      maxRequestsPerHour: null == maxRequestsPerHour
          ? _self.maxRequestsPerHour
          : maxRequestsPerHour // ignore: cast_nullable_to_non_nullable
              as int,
      maxRequestsPerDay: null == maxRequestsPerDay
          ? _self.maxRequestsPerDay
          : maxRequestsPerDay // ignore: cast_nullable_to_non_nullable
              as int,
      maxTokensPerRequest: null == maxTokensPerRequest
          ? _self.maxTokensPerRequest
          : maxTokensPerRequest // ignore: cast_nullable_to_non_nullable
              as int,
      maxTotalTokensPerDay: null == maxTotalTokensPerDay
          ? _self.maxTotalTokensPerDay
          : maxTotalTokensPerDay // ignore: cast_nullable_to_non_nullable
              as int,
      maxRequestsPerWindow: null == maxRequestsPerWindow
          ? _self.maxRequestsPerWindow
          : maxRequestsPerWindow // ignore: cast_nullable_to_non_nullable
              as int,
      timeWindowDuration: null == timeWindowDuration
          ? _self.timeWindowDuration
          : timeWindowDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      backoffBaseDelay: null == backoffBaseDelay
          ? _self.backoffBaseDelay
          : backoffBaseDelay // ignore: cast_nullable_to_non_nullable
              as Duration,
      backoffMaxDelay: null == backoffMaxDelay
          ? _self.backoffMaxDelay
          : backoffMaxDelay // ignore: cast_nullable_to_non_nullable
              as Duration,
      maxRetryAttempts: null == maxRetryAttempts
          ? _self.maxRetryAttempts
          : maxRetryAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      queueEnabled: null == queueEnabled
          ? _self.queueEnabled
          : queueEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      perOperationLimits: null == perOperationLimits
          ? _self.perOperationLimits
          : perOperationLimits // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// Adds pattern-matching-related methods to [AiRateLimitsConfig].
extension AiRateLimitsConfigPatterns on AiRateLimitsConfig {
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
    TResult Function(_AiRateLimitsConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiRateLimitsConfig() when $default != null:
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
    TResult Function(_AiRateLimitsConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRateLimitsConfig():
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
    TResult? Function(_AiRateLimitsConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRateLimitsConfig() when $default != null:
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
            int maxRequestsPerMinute,
            int maxRequestsPerHour,
            int maxRequestsPerDay,
            int maxTokensPerRequest,
            int maxTotalTokensPerDay,
            int maxRequestsPerWindow,
            @JsonKey(
                name: 'timeWindowDurationSeconds',
                fromJson: _durationSecondsFromJson,
                toJson: _durationSecondsToJson)
            Duration timeWindowDuration,
            @JsonKey(
                name: 'backoffBaseDelayMs',
                fromJson: _durationMsFromJson,
                toJson: _durationMsToJson)
            Duration backoffBaseDelay,
            @JsonKey(
                name: 'backoffMaxDelaySeconds',
                fromJson: _durationSecondsFromJson,
                toJson: _durationSecondsToJson)
            Duration backoffMaxDelay,
            int maxRetryAttempts,
            bool queueEnabled,
            @JsonKey(
                fromJson: _perOperationLimitsFromJson,
                toJson: _perOperationLimitsToJson)
            Map<String, int> perOperationLimits)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiRateLimitsConfig() when $default != null:
        return $default(
            _that.maxRequestsPerMinute,
            _that.maxRequestsPerHour,
            _that.maxRequestsPerDay,
            _that.maxTokensPerRequest,
            _that.maxTotalTokensPerDay,
            _that.maxRequestsPerWindow,
            _that.timeWindowDuration,
            _that.backoffBaseDelay,
            _that.backoffMaxDelay,
            _that.maxRetryAttempts,
            _that.queueEnabled,
            _that.perOperationLimits);
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
            int maxRequestsPerMinute,
            int maxRequestsPerHour,
            int maxRequestsPerDay,
            int maxTokensPerRequest,
            int maxTotalTokensPerDay,
            int maxRequestsPerWindow,
            @JsonKey(
                name: 'timeWindowDurationSeconds',
                fromJson: _durationSecondsFromJson,
                toJson: _durationSecondsToJson)
            Duration timeWindowDuration,
            @JsonKey(
                name: 'backoffBaseDelayMs',
                fromJson: _durationMsFromJson,
                toJson: _durationMsToJson)
            Duration backoffBaseDelay,
            @JsonKey(
                name: 'backoffMaxDelaySeconds',
                fromJson: _durationSecondsFromJson,
                toJson: _durationSecondsToJson)
            Duration backoffMaxDelay,
            int maxRetryAttempts,
            bool queueEnabled,
            @JsonKey(
                fromJson: _perOperationLimitsFromJson,
                toJson: _perOperationLimitsToJson)
            Map<String, int> perOperationLimits)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRateLimitsConfig():
        return $default(
            _that.maxRequestsPerMinute,
            _that.maxRequestsPerHour,
            _that.maxRequestsPerDay,
            _that.maxTokensPerRequest,
            _that.maxTotalTokensPerDay,
            _that.maxRequestsPerWindow,
            _that.timeWindowDuration,
            _that.backoffBaseDelay,
            _that.backoffMaxDelay,
            _that.maxRetryAttempts,
            _that.queueEnabled,
            _that.perOperationLimits);
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
            int maxRequestsPerMinute,
            int maxRequestsPerHour,
            int maxRequestsPerDay,
            int maxTokensPerRequest,
            int maxTotalTokensPerDay,
            int maxRequestsPerWindow,
            @JsonKey(
                name: 'timeWindowDurationSeconds',
                fromJson: _durationSecondsFromJson,
                toJson: _durationSecondsToJson)
            Duration timeWindowDuration,
            @JsonKey(
                name: 'backoffBaseDelayMs',
                fromJson: _durationMsFromJson,
                toJson: _durationMsToJson)
            Duration backoffBaseDelay,
            @JsonKey(
                name: 'backoffMaxDelaySeconds',
                fromJson: _durationSecondsFromJson,
                toJson: _durationSecondsToJson)
            Duration backoffMaxDelay,
            int maxRetryAttempts,
            bool queueEnabled,
            @JsonKey(
                fromJson: _perOperationLimitsFromJson,
                toJson: _perOperationLimitsToJson)
            Map<String, int> perOperationLimits)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRateLimitsConfig() when $default != null:
        return $default(
            _that.maxRequestsPerMinute,
            _that.maxRequestsPerHour,
            _that.maxRequestsPerDay,
            _that.maxTokensPerRequest,
            _that.maxTotalTokensPerDay,
            _that.maxRequestsPerWindow,
            _that.timeWindowDuration,
            _that.backoffBaseDelay,
            _that.backoffMaxDelay,
            _that.maxRetryAttempts,
            _that.queueEnabled,
            _that.perOperationLimits);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AiRateLimitsConfig implements AiRateLimitsConfig {
  const _AiRateLimitsConfig(
      {this.maxRequestsPerMinute = 10,
      this.maxRequestsPerHour = 100,
      this.maxRequestsPerDay = 500,
      this.maxTokensPerRequest = 4000,
      this.maxTotalTokensPerDay = 100000,
      this.maxRequestsPerWindow = 10,
      @JsonKey(
          name: 'timeWindowDurationSeconds',
          fromJson: _durationSecondsFromJson,
          toJson: _durationSecondsToJson)
      this.timeWindowDuration = const Duration(minutes: 1),
      @JsonKey(
          name: 'backoffBaseDelayMs',
          fromJson: _durationMsFromJson,
          toJson: _durationMsToJson)
      this.backoffBaseDelay = const Duration(milliseconds: 500),
      @JsonKey(
          name: 'backoffMaxDelaySeconds',
          fromJson: _durationSecondsFromJson,
          toJson: _durationSecondsToJson)
      this.backoffMaxDelay = const Duration(seconds: 30),
      this.maxRetryAttempts = 3,
      this.queueEnabled = true,
      @JsonKey(
          fromJson: _perOperationLimitsFromJson,
          toJson: _perOperationLimitsToJson)
      final Map<String, int> perOperationLimits = const <String, int>{
        'chat': 15,
        'generate_questions': 8,
        'generate_proposals': 6,
        'generate_plan': 4,
        'parse_filter': 10,
        'summarize': 5
      }})
      : _perOperationLimits = perOperationLimits;
  factory _AiRateLimitsConfig.fromJson(Map<String, dynamic> json) =>
      _$AiRateLimitsConfigFromJson(json);

  @override
  @JsonKey()
  final int maxRequestsPerMinute;
  @override
  @JsonKey()
  final int maxRequestsPerHour;
  @override
  @JsonKey()
  final int maxRequestsPerDay;
  @override
  @JsonKey()
  final int maxTokensPerRequest;
  @override
  @JsonKey()
  final int maxTotalTokensPerDay;
  @override
  @JsonKey()
  final int maxRequestsPerWindow;
  @override
  @JsonKey(
      name: 'timeWindowDurationSeconds',
      fromJson: _durationSecondsFromJson,
      toJson: _durationSecondsToJson)
  final Duration timeWindowDuration;
  @override
  @JsonKey(
      name: 'backoffBaseDelayMs',
      fromJson: _durationMsFromJson,
      toJson: _durationMsToJson)
  final Duration backoffBaseDelay;
  @override
  @JsonKey(
      name: 'backoffMaxDelaySeconds',
      fromJson: _durationSecondsFromJson,
      toJson: _durationSecondsToJson)
  final Duration backoffMaxDelay;
  @override
  @JsonKey()
  final int maxRetryAttempts;
  @override
  @JsonKey()
  final bool queueEnabled;
  final Map<String, int> _perOperationLimits;
  @override
  @JsonKey(
      fromJson: _perOperationLimitsFromJson, toJson: _perOperationLimitsToJson)
  Map<String, int> get perOperationLimits {
    if (_perOperationLimits is EqualUnmodifiableMapView)
      return _perOperationLimits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_perOperationLimits);
  }

  /// Create a copy of AiRateLimitsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiRateLimitsConfigCopyWith<_AiRateLimitsConfig> get copyWith =>
      __$AiRateLimitsConfigCopyWithImpl<_AiRateLimitsConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AiRateLimitsConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiRateLimitsConfig &&
            (identical(other.maxRequestsPerMinute, maxRequestsPerMinute) ||
                other.maxRequestsPerMinute == maxRequestsPerMinute) &&
            (identical(other.maxRequestsPerHour, maxRequestsPerHour) ||
                other.maxRequestsPerHour == maxRequestsPerHour) &&
            (identical(other.maxRequestsPerDay, maxRequestsPerDay) ||
                other.maxRequestsPerDay == maxRequestsPerDay) &&
            (identical(other.maxTokensPerRequest, maxTokensPerRequest) ||
                other.maxTokensPerRequest == maxTokensPerRequest) &&
            (identical(other.maxTotalTokensPerDay, maxTotalTokensPerDay) ||
                other.maxTotalTokensPerDay == maxTotalTokensPerDay) &&
            (identical(other.maxRequestsPerWindow, maxRequestsPerWindow) ||
                other.maxRequestsPerWindow == maxRequestsPerWindow) &&
            (identical(other.timeWindowDuration, timeWindowDuration) ||
                other.timeWindowDuration == timeWindowDuration) &&
            (identical(other.backoffBaseDelay, backoffBaseDelay) ||
                other.backoffBaseDelay == backoffBaseDelay) &&
            (identical(other.backoffMaxDelay, backoffMaxDelay) ||
                other.backoffMaxDelay == backoffMaxDelay) &&
            (identical(other.maxRetryAttempts, maxRetryAttempts) ||
                other.maxRetryAttempts == maxRetryAttempts) &&
            (identical(other.queueEnabled, queueEnabled) ||
                other.queueEnabled == queueEnabled) &&
            const DeepCollectionEquality()
                .equals(other._perOperationLimits, _perOperationLimits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      maxRequestsPerMinute,
      maxRequestsPerHour,
      maxRequestsPerDay,
      maxTokensPerRequest,
      maxTotalTokensPerDay,
      maxRequestsPerWindow,
      timeWindowDuration,
      backoffBaseDelay,
      backoffMaxDelay,
      maxRetryAttempts,
      queueEnabled,
      const DeepCollectionEquality().hash(_perOperationLimits));

  @override
  String toString() {
    return 'AiRateLimitsConfig(maxRequestsPerMinute: $maxRequestsPerMinute, maxRequestsPerHour: $maxRequestsPerHour, maxRequestsPerDay: $maxRequestsPerDay, maxTokensPerRequest: $maxTokensPerRequest, maxTotalTokensPerDay: $maxTotalTokensPerDay, maxRequestsPerWindow: $maxRequestsPerWindow, timeWindowDuration: $timeWindowDuration, backoffBaseDelay: $backoffBaseDelay, backoffMaxDelay: $backoffMaxDelay, maxRetryAttempts: $maxRetryAttempts, queueEnabled: $queueEnabled, perOperationLimits: $perOperationLimits)';
  }
}

/// @nodoc
abstract mixin class _$AiRateLimitsConfigCopyWith<$Res>
    implements $AiRateLimitsConfigCopyWith<$Res> {
  factory _$AiRateLimitsConfigCopyWith(
          _AiRateLimitsConfig value, $Res Function(_AiRateLimitsConfig) _then) =
      __$AiRateLimitsConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int maxRequestsPerMinute,
      int maxRequestsPerHour,
      int maxRequestsPerDay,
      int maxTokensPerRequest,
      int maxTotalTokensPerDay,
      int maxRequestsPerWindow,
      @JsonKey(
          name: 'timeWindowDurationSeconds',
          fromJson: _durationSecondsFromJson,
          toJson: _durationSecondsToJson)
      Duration timeWindowDuration,
      @JsonKey(
          name: 'backoffBaseDelayMs',
          fromJson: _durationMsFromJson,
          toJson: _durationMsToJson)
      Duration backoffBaseDelay,
      @JsonKey(
          name: 'backoffMaxDelaySeconds',
          fromJson: _durationSecondsFromJson,
          toJson: _durationSecondsToJson)
      Duration backoffMaxDelay,
      int maxRetryAttempts,
      bool queueEnabled,
      @JsonKey(
          fromJson: _perOperationLimitsFromJson,
          toJson: _perOperationLimitsToJson)
      Map<String, int> perOperationLimits});
}

/// @nodoc
class __$AiRateLimitsConfigCopyWithImpl<$Res>
    implements _$AiRateLimitsConfigCopyWith<$Res> {
  __$AiRateLimitsConfigCopyWithImpl(this._self, this._then);

  final _AiRateLimitsConfig _self;
  final $Res Function(_AiRateLimitsConfig) _then;

  /// Create a copy of AiRateLimitsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? maxRequestsPerMinute = null,
    Object? maxRequestsPerHour = null,
    Object? maxRequestsPerDay = null,
    Object? maxTokensPerRequest = null,
    Object? maxTotalTokensPerDay = null,
    Object? maxRequestsPerWindow = null,
    Object? timeWindowDuration = null,
    Object? backoffBaseDelay = null,
    Object? backoffMaxDelay = null,
    Object? maxRetryAttempts = null,
    Object? queueEnabled = null,
    Object? perOperationLimits = null,
  }) {
    return _then(_AiRateLimitsConfig(
      maxRequestsPerMinute: null == maxRequestsPerMinute
          ? _self.maxRequestsPerMinute
          : maxRequestsPerMinute // ignore: cast_nullable_to_non_nullable
              as int,
      maxRequestsPerHour: null == maxRequestsPerHour
          ? _self.maxRequestsPerHour
          : maxRequestsPerHour // ignore: cast_nullable_to_non_nullable
              as int,
      maxRequestsPerDay: null == maxRequestsPerDay
          ? _self.maxRequestsPerDay
          : maxRequestsPerDay // ignore: cast_nullable_to_non_nullable
              as int,
      maxTokensPerRequest: null == maxTokensPerRequest
          ? _self.maxTokensPerRequest
          : maxTokensPerRequest // ignore: cast_nullable_to_non_nullable
              as int,
      maxTotalTokensPerDay: null == maxTotalTokensPerDay
          ? _self.maxTotalTokensPerDay
          : maxTotalTokensPerDay // ignore: cast_nullable_to_non_nullable
              as int,
      maxRequestsPerWindow: null == maxRequestsPerWindow
          ? _self.maxRequestsPerWindow
          : maxRequestsPerWindow // ignore: cast_nullable_to_non_nullable
              as int,
      timeWindowDuration: null == timeWindowDuration
          ? _self.timeWindowDuration
          : timeWindowDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      backoffBaseDelay: null == backoffBaseDelay
          ? _self.backoffBaseDelay
          : backoffBaseDelay // ignore: cast_nullable_to_non_nullable
              as Duration,
      backoffMaxDelay: null == backoffMaxDelay
          ? _self.backoffMaxDelay
          : backoffMaxDelay // ignore: cast_nullable_to_non_nullable
              as Duration,
      maxRetryAttempts: null == maxRetryAttempts
          ? _self.maxRetryAttempts
          : maxRetryAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      queueEnabled: null == queueEnabled
          ? _self.queueEnabled
          : queueEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      perOperationLimits: null == perOperationLimits
          ? _self._perOperationLimits
          : perOperationLimits // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

// dart format on
