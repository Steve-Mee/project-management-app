// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardItem {
  @JsonKey(
      fromJson: _dashboardWidgetTypeFromJson,
      toJson: _dashboardWidgetTypeToJson)
  DashboardWidgetType get widgetType;
  @JsonKey(
      fromJson: _dashboardPositionFromJson, toJson: _dashboardPositionToJson)
  Map<String, dynamic> get position;

  /// Create a copy of DashboardItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DashboardItemCopyWith<DashboardItem> get copyWith =>
      _$DashboardItemCopyWithImpl<DashboardItem>(
          this as DashboardItem, _$identity);

  /// Serializes this DashboardItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DashboardItem &&
            (identical(other.widgetType, widgetType) ||
                other.widgetType == widgetType) &&
            const DeepCollectionEquality().equals(other.position, position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, widgetType, const DeepCollectionEquality().hash(position));

  @override
  String toString() {
    return 'DashboardItem(widgetType: $widgetType, position: $position)';
  }
}

/// @nodoc
abstract mixin class $DashboardItemCopyWith<$Res> {
  factory $DashboardItemCopyWith(
          DashboardItem value, $Res Function(DashboardItem) _then) =
      _$DashboardItemCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(
          fromJson: _dashboardWidgetTypeFromJson,
          toJson: _dashboardWidgetTypeToJson)
      DashboardWidgetType widgetType,
      @JsonKey(
          fromJson: _dashboardPositionFromJson,
          toJson: _dashboardPositionToJson)
      Map<String, dynamic> position});
}

/// @nodoc
class _$DashboardItemCopyWithImpl<$Res>
    implements $DashboardItemCopyWith<$Res> {
  _$DashboardItemCopyWithImpl(this._self, this._then);

  final DashboardItem _self;
  final $Res Function(DashboardItem) _then;

  /// Create a copy of DashboardItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? widgetType = null,
    Object? position = null,
  }) {
    return _then(_self.copyWith(
      widgetType: null == widgetType
          ? _self.widgetType
          : widgetType // ignore: cast_nullable_to_non_nullable
              as DashboardWidgetType,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DashboardItem].
extension DashboardItemPatterns on DashboardItem {
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
    TResult Function(_DashboardItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DashboardItem() when $default != null:
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
    TResult Function(_DashboardItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardItem():
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
    TResult? Function(_DashboardItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardItem() when $default != null:
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
            @JsonKey(
                fromJson: _dashboardWidgetTypeFromJson,
                toJson: _dashboardWidgetTypeToJson)
            DashboardWidgetType widgetType,
            @JsonKey(
                fromJson: _dashboardPositionFromJson,
                toJson: _dashboardPositionToJson)
            Map<String, dynamic> position)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DashboardItem() when $default != null:
        return $default(_that.widgetType, _that.position);
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
            @JsonKey(
                fromJson: _dashboardWidgetTypeFromJson,
                toJson: _dashboardWidgetTypeToJson)
            DashboardWidgetType widgetType,
            @JsonKey(
                fromJson: _dashboardPositionFromJson,
                toJson: _dashboardPositionToJson)
            Map<String, dynamic> position)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardItem():
        return $default(_that.widgetType, _that.position);
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
            @JsonKey(
                fromJson: _dashboardWidgetTypeFromJson,
                toJson: _dashboardWidgetTypeToJson)
            DashboardWidgetType widgetType,
            @JsonKey(
                fromJson: _dashboardPositionFromJson,
                toJson: _dashboardPositionToJson)
            Map<String, dynamic> position)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardItem() when $default != null:
        return $default(_that.widgetType, _that.position);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DashboardItem implements DashboardItem {
  const _DashboardItem(
      {@JsonKey(
          fromJson: _dashboardWidgetTypeFromJson,
          toJson: _dashboardWidgetTypeToJson)
      required this.widgetType,
      @JsonKey(
          fromJson: _dashboardPositionFromJson,
          toJson: _dashboardPositionToJson)
      required final Map<String, dynamic> position})
      : _position = position;
  factory _DashboardItem.fromJson(Map<String, dynamic> json) =>
      _$DashboardItemFromJson(json);

  @override
  @JsonKey(
      fromJson: _dashboardWidgetTypeFromJson,
      toJson: _dashboardWidgetTypeToJson)
  final DashboardWidgetType widgetType;
  final Map<String, dynamic> _position;
  @override
  @JsonKey(
      fromJson: _dashboardPositionFromJson, toJson: _dashboardPositionToJson)
  Map<String, dynamic> get position {
    if (_position is EqualUnmodifiableMapView) return _position;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_position);
  }

  /// Create a copy of DashboardItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DashboardItemCopyWith<_DashboardItem> get copyWith =>
      __$DashboardItemCopyWithImpl<_DashboardItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DashboardItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DashboardItem &&
            (identical(other.widgetType, widgetType) ||
                other.widgetType == widgetType) &&
            const DeepCollectionEquality().equals(other._position, _position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, widgetType, const DeepCollectionEquality().hash(_position));

  @override
  String toString() {
    return 'DashboardItem(widgetType: $widgetType, position: $position)';
  }
}

/// @nodoc
abstract mixin class _$DashboardItemCopyWith<$Res>
    implements $DashboardItemCopyWith<$Res> {
  factory _$DashboardItemCopyWith(
          _DashboardItem value, $Res Function(_DashboardItem) _then) =
      __$DashboardItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(
          fromJson: _dashboardWidgetTypeFromJson,
          toJson: _dashboardWidgetTypeToJson)
      DashboardWidgetType widgetType,
      @JsonKey(
          fromJson: _dashboardPositionFromJson,
          toJson: _dashboardPositionToJson)
      Map<String, dynamic> position});
}

/// @nodoc
class __$DashboardItemCopyWithImpl<$Res>
    implements _$DashboardItemCopyWith<$Res> {
  __$DashboardItemCopyWithImpl(this._self, this._then);

  final _DashboardItem _self;
  final $Res Function(_DashboardItem) _then;

  /// Create a copy of DashboardItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? widgetType = null,
    Object? position = null,
  }) {
    return _then(_DashboardItem(
      widgetType: null == widgetType
          ? _self.widgetType
          : widgetType // ignore: cast_nullable_to_non_nullable
              as DashboardWidgetType,
      position: null == position
          ? _self._position
          : position // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$DashboardTemplate {
  String get id;
  String get name;
  List<DashboardItem> get items;
  bool get isPreset;
  DateTime get createdAt;

  /// Create a copy of DashboardTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DashboardTemplateCopyWith<DashboardTemplate> get copyWith =>
      _$DashboardTemplateCopyWithImpl<DashboardTemplate>(
          this as DashboardTemplate, _$identity);

  /// Serializes this DashboardTemplate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DashboardTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.items, items) &&
            (identical(other.isPreset, isPreset) ||
                other.isPreset == isPreset) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name,
      const DeepCollectionEquality().hash(items), isPreset, createdAt);

  @override
  String toString() {
    return 'DashboardTemplate(id: $id, name: $name, items: $items, isPreset: $isPreset, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $DashboardTemplateCopyWith<$Res> {
  factory $DashboardTemplateCopyWith(
          DashboardTemplate value, $Res Function(DashboardTemplate) _then) =
      _$DashboardTemplateCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      List<DashboardItem> items,
      bool isPreset,
      DateTime createdAt});
}

/// @nodoc
class _$DashboardTemplateCopyWithImpl<$Res>
    implements $DashboardTemplateCopyWith<$Res> {
  _$DashboardTemplateCopyWithImpl(this._self, this._then);

  final DashboardTemplate _self;
  final $Res Function(DashboardTemplate) _then;

  /// Create a copy of DashboardTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? items = null,
    Object? isPreset = null,
    Object? createdAt = null,
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
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DashboardItem>,
      isPreset: null == isPreset
          ? _self.isPreset
          : isPreset // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [DashboardTemplate].
extension DashboardTemplatePatterns on DashboardTemplate {
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
    TResult Function(_DashboardTemplate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DashboardTemplate() when $default != null:
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
    TResult Function(_DashboardTemplate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardTemplate():
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
    TResult? Function(_DashboardTemplate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardTemplate() when $default != null:
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
    TResult Function(String id, String name, List<DashboardItem> items,
            bool isPreset, DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DashboardTemplate() when $default != null:
        return $default(
            _that.id, _that.name, _that.items, _that.isPreset, _that.createdAt);
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
    TResult Function(String id, String name, List<DashboardItem> items,
            bool isPreset, DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardTemplate():
        return $default(
            _that.id, _that.name, _that.items, _that.isPreset, _that.createdAt);
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
    TResult? Function(String id, String name, List<DashboardItem> items,
            bool isPreset, DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DashboardTemplate() when $default != null:
        return $default(
            _that.id, _that.name, _that.items, _that.isPreset, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DashboardTemplate implements DashboardTemplate {
  const _DashboardTemplate(
      {required this.id,
      required this.name,
      required final List<DashboardItem> items,
      required this.isPreset,
      required this.createdAt})
      : _items = items;
  factory _DashboardTemplate.fromJson(Map<String, dynamic> json) =>
      _$DashboardTemplateFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<DashboardItem> _items;
  @override
  List<DashboardItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final bool isPreset;
  @override
  final DateTime createdAt;

  /// Create a copy of DashboardTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DashboardTemplateCopyWith<_DashboardTemplate> get copyWith =>
      __$DashboardTemplateCopyWithImpl<_DashboardTemplate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DashboardTemplateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DashboardTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.isPreset, isPreset) ||
                other.isPreset == isPreset) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name,
      const DeepCollectionEquality().hash(_items), isPreset, createdAt);

  @override
  String toString() {
    return 'DashboardTemplate(id: $id, name: $name, items: $items, isPreset: $isPreset, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$DashboardTemplateCopyWith<$Res>
    implements $DashboardTemplateCopyWith<$Res> {
  factory _$DashboardTemplateCopyWith(
          _DashboardTemplate value, $Res Function(_DashboardTemplate) _then) =
      __$DashboardTemplateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<DashboardItem> items,
      bool isPreset,
      DateTime createdAt});
}

/// @nodoc
class __$DashboardTemplateCopyWithImpl<$Res>
    implements _$DashboardTemplateCopyWith<$Res> {
  __$DashboardTemplateCopyWithImpl(this._self, this._then);

  final _DashboardTemplate _self;
  final $Res Function(_DashboardTemplate) _then;

  /// Create a copy of DashboardTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? items = null,
    Object? isPreset = null,
    Object? createdAt = null,
  }) {
    return _then(_DashboardTemplate(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DashboardItem>,
      isPreset: null == isPreset
          ? _self.isPreset
          : isPreset // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
