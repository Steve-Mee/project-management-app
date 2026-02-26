// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_usage_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiUsageRecord {
  String get id;
  DateTime get timestamp;
  String get operation;
  int get inputTokens;
  int get outputTokens;
  double get estimatedCost;
  String? get userId;
  String? get projectId;
  bool get success;
  String? get errorMessage;

  /// Create a copy of AiUsageRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiUsageRecordCopyWith<AiUsageRecord> get copyWith =>
      _$AiUsageRecordCopyWithImpl<AiUsageRecord>(
          this as AiUsageRecord, _$identity);

  /// Serializes this AiUsageRecord to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiUsageRecord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.inputTokens, inputTokens) ||
                other.inputTokens == inputTokens) &&
            (identical(other.outputTokens, outputTokens) ||
                other.outputTokens == outputTokens) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      timestamp,
      operation,
      inputTokens,
      outputTokens,
      estimatedCost,
      userId,
      projectId,
      success,
      errorMessage);

  @override
  String toString() {
    return 'AiUsageRecord(id: $id, timestamp: $timestamp, operation: $operation, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCost: $estimatedCost, userId: $userId, projectId: $projectId, success: $success, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $AiUsageRecordCopyWith<$Res> {
  factory $AiUsageRecordCopyWith(
          AiUsageRecord value, $Res Function(AiUsageRecord) _then) =
      _$AiUsageRecordCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      String operation,
      int inputTokens,
      int outputTokens,
      double estimatedCost,
      String? userId,
      String? projectId,
      bool success,
      String? errorMessage});
}

/// @nodoc
class _$AiUsageRecordCopyWithImpl<$Res>
    implements $AiUsageRecordCopyWith<$Res> {
  _$AiUsageRecordCopyWithImpl(this._self, this._then);

  final AiUsageRecord _self;
  final $Res Function(AiUsageRecord) _then;

  /// Create a copy of AiUsageRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? operation = null,
    Object? inputTokens = null,
    Object? outputTokens = null,
    Object? estimatedCost = null,
    Object? userId = freezed,
    Object? projectId = freezed,
    Object? success = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String,
      inputTokens: null == inputTokens
          ? _self.inputTokens
          : inputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      outputTokens: null == outputTokens
          ? _self.outputTokens
          : outputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedCost: null == estimatedCost
          ? _self.estimatedCost
          : estimatedCost // ignore: cast_nullable_to_non_nullable
              as double,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AiUsageRecord].
extension AiUsageRecordPatterns on AiUsageRecord {
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
    TResult Function(_AiUsageRecord value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiUsageRecord() when $default != null:
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
    TResult Function(_AiUsageRecord value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsageRecord():
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
    TResult? Function(_AiUsageRecord value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsageRecord() when $default != null:
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
            DateTime timestamp,
            String operation,
            int inputTokens,
            int outputTokens,
            double estimatedCost,
            String? userId,
            String? projectId,
            bool success,
            String? errorMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AiUsageRecord() when $default != null:
        return $default(
            _that.id,
            _that.timestamp,
            _that.operation,
            _that.inputTokens,
            _that.outputTokens,
            _that.estimatedCost,
            _that.userId,
            _that.projectId,
            _that.success,
            _that.errorMessage);
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
            DateTime timestamp,
            String operation,
            int inputTokens,
            int outputTokens,
            double estimatedCost,
            String? userId,
            String? projectId,
            bool success,
            String? errorMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsageRecord():
        return $default(
            _that.id,
            _that.timestamp,
            _that.operation,
            _that.inputTokens,
            _that.outputTokens,
            _that.estimatedCost,
            _that.userId,
            _that.projectId,
            _that.success,
            _that.errorMessage);
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
            DateTime timestamp,
            String operation,
            int inputTokens,
            int outputTokens,
            double estimatedCost,
            String? userId,
            String? projectId,
            bool success,
            String? errorMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AiUsageRecord() when $default != null:
        return $default(
            _that.id,
            _that.timestamp,
            _that.operation,
            _that.inputTokens,
            _that.outputTokens,
            _that.estimatedCost,
            _that.userId,
            _that.projectId,
            _that.success,
            _that.errorMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AiUsageRecord implements AiUsageRecord {
  const _AiUsageRecord(
      {required this.id,
      required this.timestamp,
      required this.operation,
      required this.inputTokens,
      required this.outputTokens,
      required this.estimatedCost,
      this.userId,
      this.projectId,
      required this.success,
      this.errorMessage});
  factory _AiUsageRecord.fromJson(Map<String, dynamic> json) =>
      _$AiUsageRecordFromJson(json);

  @override
  final String id;
  @override
  final DateTime timestamp;
  @override
  final String operation;
  @override
  final int inputTokens;
  @override
  final int outputTokens;
  @override
  final double estimatedCost;
  @override
  final String? userId;
  @override
  final String? projectId;
  @override
  final bool success;
  @override
  final String? errorMessage;

  /// Create a copy of AiUsageRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiUsageRecordCopyWith<_AiUsageRecord> get copyWith =>
      __$AiUsageRecordCopyWithImpl<_AiUsageRecord>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AiUsageRecordToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiUsageRecord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.inputTokens, inputTokens) ||
                other.inputTokens == inputTokens) &&
            (identical(other.outputTokens, outputTokens) ||
                other.outputTokens == outputTokens) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      timestamp,
      operation,
      inputTokens,
      outputTokens,
      estimatedCost,
      userId,
      projectId,
      success,
      errorMessage);

  @override
  String toString() {
    return 'AiUsageRecord(id: $id, timestamp: $timestamp, operation: $operation, inputTokens: $inputTokens, outputTokens: $outputTokens, estimatedCost: $estimatedCost, userId: $userId, projectId: $projectId, success: $success, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$AiUsageRecordCopyWith<$Res>
    implements $AiUsageRecordCopyWith<$Res> {
  factory _$AiUsageRecordCopyWith(
          _AiUsageRecord value, $Res Function(_AiUsageRecord) _then) =
      __$AiUsageRecordCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      String operation,
      int inputTokens,
      int outputTokens,
      double estimatedCost,
      String? userId,
      String? projectId,
      bool success,
      String? errorMessage});
}

/// @nodoc
class __$AiUsageRecordCopyWithImpl<$Res>
    implements _$AiUsageRecordCopyWith<$Res> {
  __$AiUsageRecordCopyWithImpl(this._self, this._then);

  final _AiUsageRecord _self;
  final $Res Function(_AiUsageRecord) _then;

  /// Create a copy of AiUsageRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? operation = null,
    Object? inputTokens = null,
    Object? outputTokens = null,
    Object? estimatedCost = null,
    Object? userId = freezed,
    Object? projectId = freezed,
    Object? success = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_AiUsageRecord(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      operation: null == operation
          ? _self.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String,
      inputTokens: null == inputTokens
          ? _self.inputTokens
          : inputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      outputTokens: null == outputTokens
          ? _self.outputTokens
          : outputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedCost: null == estimatedCost
          ? _self.estimatedCost
          : estimatedCost // ignore: cast_nullable_to_non_nullable
              as double,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
