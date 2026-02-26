// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_request_queue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiRequest {
  String get id;
  String get action;
  Map<String, dynamic> get payload;
  DateTime get timestamp;
  int get priority;
  Completer<dynamic> get completer;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiRequestCopyWith<AiRequest> get copyWith =>
      _$AiRequestCopyWithImpl<AiRequest>(this as AiRequest, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiRequest &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.action, action) || other.action == action) &&
            const DeepCollectionEquality().equals(other.payload, payload) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.completer, completer) ||
                other.completer == completer));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      action,
      const DeepCollectionEquality().hash(payload),
      timestamp,
      priority,
      completer);

  @override
  String toString() {
    return 'AiRequest(id: $id, action: $action, payload: $payload, timestamp: $timestamp, priority: $priority, completer: $completer)';
  }
}

/// @nodoc
abstract mixin class $AiRequestCopyWith<$Res> {
  factory $AiRequestCopyWith(AiRequest value, $Res Function(AiRequest) _then) =
      _$AiRequestCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String action,
      Map<String, dynamic> payload,
      DateTime timestamp,
      int priority,
      Completer<dynamic> completer});
}

/// @nodoc
class _$AiRequestCopyWithImpl<$Res> implements $AiRequestCopyWith<$Res> {
  _$AiRequestCopyWithImpl(this._self, this._then);

  final AiRequest _self;
  final $Res Function(AiRequest) _then;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? action = null,
    Object? payload = null,
    Object? timestamp = null,
    Object? priority = null,
    Object? completer = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _self.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      completer: null == completer
          ? _self.completer
          : completer // ignore: cast_nullable_to_non_nullable
              as Completer<dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [AiRequest].
extension AiRequestPatterns on AiRequest {
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
    TResult Function(_AiRequest value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
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
    TResult Function(_AiRequest value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest():
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
    TResult? Function(_AiRequest value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
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
    TResult Function(String id, String action, Map<String, dynamic> payload,
            DateTime timestamp, int priority, Completer<dynamic> completer)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
        return $default(_that.id, _that.action, _that.payload, _that.timestamp,
            _that.priority, _that.completer);
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
    TResult Function(String id, String action, Map<String, dynamic> payload,
            DateTime timestamp, int priority, Completer<dynamic> completer)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest():
        return $default(_that.id, _that.action, _that.payload, _that.timestamp,
            _that.priority, _that.completer);
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
    TResult? Function(String id, String action, Map<String, dynamic> payload,
            DateTime timestamp, int priority, Completer<dynamic> completer)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiRequest() when $default != null:
        return $default(_that.id, _that.action, _that.payload, _that.timestamp,
            _that.priority, _that.completer);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AiRequest extends AiRequest {
  const _AiRequest(
      {required this.id,
      required this.action,
      required final Map<String, dynamic> payload,
      required this.timestamp,
      this.priority = 1,
      required this.completer})
      : _payload = payload,
        super._();

  @override
  final String id;
  @override
  final String action;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final int priority;
  @override
  final Completer<dynamic> completer;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiRequestCopyWith<_AiRequest> get copyWith =>
      __$AiRequestCopyWithImpl<_AiRequest>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiRequest &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.action, action) || other.action == action) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.completer, completer) ||
                other.completer == completer));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      action,
      const DeepCollectionEquality().hash(_payload),
      timestamp,
      priority,
      completer);

  @override
  String toString() {
    return 'AiRequest(id: $id, action: $action, payload: $payload, timestamp: $timestamp, priority: $priority, completer: $completer)';
  }
}

/// @nodoc
abstract mixin class _$AiRequestCopyWith<$Res>
    implements $AiRequestCopyWith<$Res> {
  factory _$AiRequestCopyWith(
          _AiRequest value, $Res Function(_AiRequest) _then) =
      __$AiRequestCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String action,
      Map<String, dynamic> payload,
      DateTime timestamp,
      int priority,
      Completer<dynamic> completer});
}

/// @nodoc
class __$AiRequestCopyWithImpl<$Res> implements _$AiRequestCopyWith<$Res> {
  __$AiRequestCopyWithImpl(this._self, this._then);

  final _AiRequest _self;
  final $Res Function(_AiRequest) _then;

  /// Create a copy of AiRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? action = null,
    Object? payload = null,
    Object? timestamp = null,
    Object? priority = null,
    Object? completer = null,
  }) {
    return _then(_AiRequest(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      payload: null == payload
          ? _self._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      completer: null == completer
          ? _self.completer
          : completer // ignore: cast_nullable_to_non_nullable
              as Completer<dynamic>,
    ));
  }
}

/// @nodoc
mixin _$QueueMetrics {
  int get queueLength;
  int get processedCount;
  int get failedCount;
  Duration get averageProcessingTime;

  /// Create a copy of QueueMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QueueMetricsCopyWith<QueueMetrics> get copyWith =>
      _$QueueMetricsCopyWithImpl<QueueMetrics>(
          this as QueueMetrics, _$identity);

  /// Serializes this QueueMetrics to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QueueMetrics &&
            (identical(other.queueLength, queueLength) ||
                other.queueLength == queueLength) &&
            (identical(other.processedCount, processedCount) ||
                other.processedCount == processedCount) &&
            (identical(other.failedCount, failedCount) ||
                other.failedCount == failedCount) &&
            (identical(other.averageProcessingTime, averageProcessingTime) ||
                other.averageProcessingTime == averageProcessingTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, queueLength, processedCount,
      failedCount, averageProcessingTime);

  @override
  String toString() {
    return 'QueueMetrics(queueLength: $queueLength, processedCount: $processedCount, failedCount: $failedCount, averageProcessingTime: $averageProcessingTime)';
  }
}

/// @nodoc
abstract mixin class $QueueMetricsCopyWith<$Res> {
  factory $QueueMetricsCopyWith(
          QueueMetrics value, $Res Function(QueueMetrics) _then) =
      _$QueueMetricsCopyWithImpl;
  @useResult
  $Res call(
      {int queueLength,
      int processedCount,
      int failedCount,
      Duration averageProcessingTime});
}

/// @nodoc
class _$QueueMetricsCopyWithImpl<$Res> implements $QueueMetricsCopyWith<$Res> {
  _$QueueMetricsCopyWithImpl(this._self, this._then);

  final QueueMetrics _self;
  final $Res Function(QueueMetrics) _then;

  /// Create a copy of QueueMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queueLength = null,
    Object? processedCount = null,
    Object? failedCount = null,
    Object? averageProcessingTime = null,
  }) {
    return _then(_self.copyWith(
      queueLength: null == queueLength
          ? _self.queueLength
          : queueLength // ignore: cast_nullable_to_non_nullable
              as int,
      processedCount: null == processedCount
          ? _self.processedCount
          : processedCount // ignore: cast_nullable_to_non_nullable
              as int,
      failedCount: null == failedCount
          ? _self.failedCount
          : failedCount // ignore: cast_nullable_to_non_nullable
              as int,
      averageProcessingTime: null == averageProcessingTime
          ? _self.averageProcessingTime
          : averageProcessingTime // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

/// Adds pattern-matching-related methods to [QueueMetrics].
extension QueueMetricsPatterns on QueueMetrics {
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
    TResult Function(_QueueMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QueueMetrics() when $default != null:
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
    TResult Function(_QueueMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueueMetrics():
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
    TResult? Function(_QueueMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueueMetrics() when $default != null:
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
    TResult Function(int queueLength, int processedCount, int failedCount,
            Duration averageProcessingTime)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QueueMetrics() when $default != null:
        return $default(_that.queueLength, _that.processedCount,
            _that.failedCount, _that.averageProcessingTime);
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
    TResult Function(int queueLength, int processedCount, int failedCount,
            Duration averageProcessingTime)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueueMetrics():
        return $default(_that.queueLength, _that.processedCount,
            _that.failedCount, _that.averageProcessingTime);
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
    TResult? Function(int queueLength, int processedCount, int failedCount,
            Duration averageProcessingTime)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QueueMetrics() when $default != null:
        return $default(_that.queueLength, _that.processedCount,
            _that.failedCount, _that.averageProcessingTime);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _QueueMetrics implements QueueMetrics {
  const _QueueMetrics(
      {required this.queueLength,
      required this.processedCount,
      this.failedCount = 0,
      this.averageProcessingTime = Duration.zero});
  factory _QueueMetrics.fromJson(Map<String, dynamic> json) =>
      _$QueueMetricsFromJson(json);

  @override
  final int queueLength;
  @override
  final int processedCount;
  @override
  @JsonKey()
  final int failedCount;
  @override
  @JsonKey()
  final Duration averageProcessingTime;

  /// Create a copy of QueueMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QueueMetricsCopyWith<_QueueMetrics> get copyWith =>
      __$QueueMetricsCopyWithImpl<_QueueMetrics>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$QueueMetricsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QueueMetrics &&
            (identical(other.queueLength, queueLength) ||
                other.queueLength == queueLength) &&
            (identical(other.processedCount, processedCount) ||
                other.processedCount == processedCount) &&
            (identical(other.failedCount, failedCount) ||
                other.failedCount == failedCount) &&
            (identical(other.averageProcessingTime, averageProcessingTime) ||
                other.averageProcessingTime == averageProcessingTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, queueLength, processedCount,
      failedCount, averageProcessingTime);

  @override
  String toString() {
    return 'QueueMetrics(queueLength: $queueLength, processedCount: $processedCount, failedCount: $failedCount, averageProcessingTime: $averageProcessingTime)';
  }
}

/// @nodoc
abstract mixin class _$QueueMetricsCopyWith<$Res>
    implements $QueueMetricsCopyWith<$Res> {
  factory _$QueueMetricsCopyWith(
          _QueueMetrics value, $Res Function(_QueueMetrics) _then) =
      __$QueueMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int queueLength,
      int processedCount,
      int failedCount,
      Duration averageProcessingTime});
}

/// @nodoc
class __$QueueMetricsCopyWithImpl<$Res>
    implements _$QueueMetricsCopyWith<$Res> {
  __$QueueMetricsCopyWithImpl(this._self, this._then);

  final _QueueMetrics _self;
  final $Res Function(_QueueMetrics) _then;

  /// Create a copy of QueueMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? queueLength = null,
    Object? processedCount = null,
    Object? failedCount = null,
    Object? averageProcessingTime = null,
  }) {
    return _then(_QueueMetrics(
      queueLength: null == queueLength
          ? _self.queueLength
          : queueLength // ignore: cast_nullable_to_non_nullable
              as int,
      processedCount: null == processedCount
          ? _self.processedCount
          : processedCount // ignore: cast_nullable_to_non_nullable
              as int,
      failedCount: null == failedCount
          ? _self.failedCount
          : failedCount // ignore: cast_nullable_to_non_nullable
              as int,
      averageProcessingTime: null == averageProcessingTime
          ? _self.averageProcessingTime
          : averageProcessingTime // ignore: cast_nullable_to_non_nullable
              as Duration,
    ));
  }
}

// dart format on
