// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_viewers_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActiveViewer _$ActiveViewerFromJson(Map<String, dynamic> json) =>
    _ActiveViewer(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      currentFilter: json['currentFilter'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ActiveViewerToJson(_ActiveViewer instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'lastSeen': instance.lastSeen.toIso8601String(),
      'currentFilter': instance.currentFilter,
    };
