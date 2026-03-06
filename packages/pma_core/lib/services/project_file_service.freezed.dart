// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_file_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectFileContent {
  String get name;
  String get content;

  /// Create a copy of ProjectFileContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectFileContentCopyWith<ProjectFileContent> get copyWith =>
      _$ProjectFileContentCopyWithImpl<ProjectFileContent>(
          this as ProjectFileContent, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProjectFileContent &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, content);

  @override
  String toString() {
    return 'ProjectFileContent(name: $name, content: $content)';
  }
}

/// @nodoc
abstract mixin class $ProjectFileContentCopyWith<$Res> {
  factory $ProjectFileContentCopyWith(
          ProjectFileContent value, $Res Function(ProjectFileContent) _then) =
      _$ProjectFileContentCopyWithImpl;
  @useResult
  $Res call({String name, String content});
}

/// @nodoc
class _$ProjectFileContentCopyWithImpl<$Res>
    implements $ProjectFileContentCopyWith<$Res> {
  _$ProjectFileContentCopyWithImpl(this._self, this._then);

  final ProjectFileContent _self;
  final $Res Function(ProjectFileContent) _then;

  /// Create a copy of ProjectFileContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? content = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProjectFileContent].
extension ProjectFileContentPatterns on ProjectFileContent {
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
    TResult Function(_ProjectFileContent value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFileContent() when $default != null:
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
    TResult Function(_ProjectFileContent value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFileContent():
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
    TResult? Function(_ProjectFileContent value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFileContent() when $default != null:
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
    TResult Function(String name, String content)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProjectFileContent() when $default != null:
        return $default(_that.name, _that.content);
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
    TResult Function(String name, String content) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFileContent():
        return $default(_that.name, _that.content);
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
    TResult? Function(String name, String content)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProjectFileContent() when $default != null:
        return $default(_that.name, _that.content);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ProjectFileContent implements ProjectFileContent {
  const _ProjectFileContent({required this.name, required this.content});

  @override
  final String name;
  @override
  final String content;

  /// Create a copy of ProjectFileContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectFileContentCopyWith<_ProjectFileContent> get copyWith =>
      __$ProjectFileContentCopyWithImpl<_ProjectFileContent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProjectFileContent &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, content);

  @override
  String toString() {
    return 'ProjectFileContent(name: $name, content: $content)';
  }
}

/// @nodoc
abstract mixin class _$ProjectFileContentCopyWith<$Res>
    implements $ProjectFileContentCopyWith<$Res> {
  factory _$ProjectFileContentCopyWith(
          _ProjectFileContent value, $Res Function(_ProjectFileContent) _then) =
      __$ProjectFileContentCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String content});
}

/// @nodoc
class __$ProjectFileContentCopyWithImpl<$Res>
    implements _$ProjectFileContentCopyWith<$Res> {
  __$ProjectFileContentCopyWithImpl(this._self, this._then);

  final _ProjectFileContent _self;
  final $Res Function(_ProjectFileContent) _then;

  /// Create a copy of ProjectFileContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? content = null,
  }) {
    return _then(_ProjectFileContent(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$CachedFile {
  String get content;
  DateTime get lastModified;

  /// Create a copy of _CachedFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CachedFileCopyWith<_CachedFile> get copyWith =>
      __$CachedFileCopyWithImpl<_CachedFile>(this as _CachedFile, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CachedFile &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.lastModified, lastModified) ||
                other.lastModified == lastModified));
  }

  @override
  int get hashCode => Object.hash(runtimeType, content, lastModified);

  @override
  String toString() {
    return '_CachedFile(content: $content, lastModified: $lastModified)';
  }
}

/// @nodoc
abstract mixin class _$CachedFileCopyWith<$Res> {
  factory _$CachedFileCopyWith(
          _CachedFile value, $Res Function(_CachedFile) _then) =
      __$CachedFileCopyWithImpl;
  @useResult
  $Res call({String content, DateTime lastModified});
}

/// @nodoc
class __$CachedFileCopyWithImpl<$Res> implements _$CachedFileCopyWith<$Res> {
  __$CachedFileCopyWithImpl(this._self, this._then);

  final _CachedFile _self;
  final $Res Function(_CachedFile) _then;

  /// Create a copy of _CachedFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? lastModified = null,
  }) {
    return _then(_self.copyWith(
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      lastModified: null == lastModified
          ? _self.lastModified
          : lastModified // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [_CachedFile].
extension _CachedFilePatterns on _CachedFile {
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
    TResult Function(__CachedFile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case __CachedFile() when $default != null:
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
    TResult Function(__CachedFile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case __CachedFile():
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
    TResult? Function(__CachedFile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case __CachedFile() when $default != null:
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
    TResult Function(String content, DateTime lastModified)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case __CachedFile() when $default != null:
        return $default(_that.content, _that.lastModified);
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
    TResult Function(String content, DateTime lastModified) $default,
  ) {
    final _that = this;
    switch (_that) {
      case __CachedFile():
        return $default(_that.content, _that.lastModified);
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
    TResult? Function(String content, DateTime lastModified)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case __CachedFile() when $default != null:
        return $default(_that.content, _that.lastModified);
      case _:
        return null;
    }
  }
}

/// @nodoc

class __CachedFile implements _CachedFile {
  const __CachedFile({required this.content, required this.lastModified});

  @override
  final String content;
  @override
  final DateTime lastModified;

  /// Create a copy of _CachedFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$_CachedFileCopyWith<__CachedFile> get copyWith =>
      __$_CachedFileCopyWithImpl<__CachedFile>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is __CachedFile &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.lastModified, lastModified) ||
                other.lastModified == lastModified));
  }

  @override
  int get hashCode => Object.hash(runtimeType, content, lastModified);

  @override
  String toString() {
    return '_CachedFile(content: $content, lastModified: $lastModified)';
  }
}

/// @nodoc
abstract mixin class _$_CachedFileCopyWith<$Res>
    implements _$CachedFileCopyWith<$Res> {
  factory _$_CachedFileCopyWith(
          __CachedFile value, $Res Function(__CachedFile) _then) =
      __$_CachedFileCopyWithImpl;
  @override
  @useResult
  $Res call({String content, DateTime lastModified});
}

/// @nodoc
class __$_CachedFileCopyWithImpl<$Res> implements _$_CachedFileCopyWith<$Res> {
  __$_CachedFileCopyWithImpl(this._self, this._then);

  final __CachedFile _self;
  final $Res Function(__CachedFile) _then;

  /// Create a copy of _CachedFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? content = null,
    Object? lastModified = null,
  }) {
    return _then(__CachedFile(
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      lastModified: null == lastModified
          ? _self.lastModified
          : lastModified // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
