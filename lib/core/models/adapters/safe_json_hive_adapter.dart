import 'dart:convert';

import 'package:hive/hive.dart';

typedef JsonFromMap<T> = T Function(Map<String, dynamic> json);
typedef JsonToMap<T> = Map<String, dynamic> Function(T value);

class SafeJsonHiveAdapter<T> extends TypeAdapter<T> {
  SafeJsonHiveAdapter({
    required this.typeId,
    required JsonFromMap<T> fromJson,
    required JsonToMap<T> toJson,
  })  : _fromJson = fromJson,
        _toJson = toJson;

  @override
  final int typeId;

  final JsonFromMap<T> _fromJson;
  final JsonToMap<T> _toJson;

  @override
  T read(BinaryReader reader) {
    final raw = reader.read();
    final map = _asMap(raw);
    return _fromJson(map);
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer.write(_normalize(_toJson(obj)));
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) {
      return _normalize(raw);
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _normalize(decoded);
      }
    }
    throw HiveError(
      'SafeJsonHiveAdapter expected Map/String payload but found ${raw.runtimeType}.',
    );
  }

  static dynamic _normalize(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _normalize(nested)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalize).toList();
    }
    return value;
  }
}
