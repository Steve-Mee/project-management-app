// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_request_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueMetrics _$QueueMetricsFromJson(Map<String, dynamic> json) =>
    _QueueMetrics(
      queueLength: (json['queueLength'] as num).toInt(),
      processedCount: (json['processedCount'] as num).toInt(),
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      averageProcessingTime: json['averageProcessingTime'] == null
          ? Duration.zero
          : Duration(
              microseconds: (json['averageProcessingTime'] as num).toInt()),
    );

Map<String, dynamic> _$QueueMetricsToJson(_QueueMetrics instance) =>
    <String, dynamic>{
      'queueLength': instance.queueLength,
      'processedCount': instance.processedCount,
      'failedCount': instance.failedCount,
      'averageProcessingTime': instance.averageProcessingTime.inMicroseconds,
    };
