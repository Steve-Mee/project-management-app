import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/core/repository/i_ai_usage_repository.dart';
import 'package:my_project_management_app/core/models/ai_usage_record.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';

/// Concrete implementation of IAiUsageRepository using Hive for local persistence
/// Implements caching for usage totals as per .github/issues/027-dashboard-cache-requirements.md pattern
class AiUsageRepository implements IAiUsageRepository {
  static const String _usageBoxName = 'ai_usage';
  static const String _totalsCacheKey = 'totals_cache';

  /// In-memory cache for usage totals to improve performance.
  /// Stores aggregated totals with TTL.
  final Map<String, dynamic> _cache = {};

  /// Timestamp when the cache was last updated.
  DateTime? _cacheTimestamp;

  /// Time-to-live duration for cache validity (5 minutes).
  static const Duration kCacheTTL = Duration(minutes: 5);

  Box<List>? _usageBox;

  /// Checks if the cache is valid (not expired based on TTL).
  bool _isCacheValid() {
    return _cacheTimestamp != null &&
           DateTime.now().difference(_cacheTimestamp!) < kCacheTTL;
  }

  /// Invalidates the cache by clearing it and resetting the timestamp.
  void _invalidateCache() {
    _cache.clear();
    _cacheTimestamp = null;
    AppLogger.instance.d('AI usage cache invalidated');
  }

  /// Updates the cache with new totals and sets the timestamp.
  void _updateCache(Map<String, dynamic> totals) {
    _cache[_totalsCacheKey] = totals;
    _cacheTimestamp = DateTime.now();
    AppLogger.instance.d('AI usage cache updated');
  }

  /// Retrieves totals from cache if valid.
  Map<String, dynamic>? _getTotalsFromCache() {
    if (_isCacheValid()) {
      final totals = _cache[_totalsCacheKey] as Map<String, dynamic>?;
      AppLogger.instance.d('AI usage cache hit');
      return totals;
    }
    AppLogger.instance.d('AI usage cache miss');
    return null;
  }

  Future<Box<List>> _getBox() async {
    _usageBox ??= await Hive.openBox<List>(_usageBoxName);
    return _usageBox!;
  }

  @override
  Future<void> logUsage(AiUsageRecord record) async {
    try {
      final box = await _getBox();
      final records = box.get('records', defaultValue: <Map<String, dynamic>>[])!
          .map((json) => AiUsageRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      records.add(record);
      await box.put('records', records.map((r) => r.toJson()).toList());

      // Invalidate cache since totals changed
      _invalidateCache();

      AppLogger.event('ai_usage_logged', params: {
        'operation': record.operation,
        'tokens': record.inputTokens + record.outputTokens,
        'cost': record.estimatedCost,
        'success': record.success,
      });
    } catch (e) {
      AppLogger.instance.e('Failed to log AI usage', error: e);
      rethrow;
    }
  }

  @override
  Future<List<AiUsageRecord>> getUsageHistory({
    DateTime? from,
    DateTime? to,
    String? userId,
    String? projectId,
  }) async {
    try {
      final box = await _getBox();
      final records = box.get('records', defaultValue: <Map<String, dynamic>>[])!
          .map((json) => AiUsageRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      // Apply filters
      var filtered = records;
      if (from != null) {
        filtered = filtered.where((r) => r.timestamp.isAfter(from) || r.timestamp.isAtSameMomentAs(from)).toList();
      }
      if (to != null) {
        filtered = filtered.where((r) => r.timestamp.isBefore(to) || r.timestamp.isAtSameMomentAs(to)).toList();
      }
      if (userId != null) {
        filtered = filtered.where((r) => r.userId == userId).toList();
      }
      if (projectId != null) {
        filtered = filtered.where((r) => r.projectId == projectId).toList();
      }

      // Sort by timestamp descending (most recent first)
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return filtered;
    } catch (e) {
      AppLogger.instance.e('Failed to get AI usage history', error: e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getUsageTotals({
    String? userId,
    String? projectId,
  }) async {
    // Check cache first
    final cached = _getTotalsFromCache();
    if (cached != null) {
      return cached;
    }

    try {
      final history = await getUsageHistory(userId: userId, projectId: projectId);

      final totals = {
        'totalTokens': history.fold<int>(0, (sum, r) => sum + r.inputTokens + r.outputTokens),
        'inputTokens': history.fold<int>(0, (sum, r) => sum + r.inputTokens),
        'outputTokens': history.fold<int>(0, (sum, r) => sum + r.outputTokens),
        'totalCost': history.fold<double>(0.0, (sum, r) => sum + r.estimatedCost),
        'requestCount': history.length,
        'successfulRequests': history.where((r) => r.success).length,
        'failedRequests': history.where((r) => !r.success).length,
      };

      // Update cache
      _updateCache(totals);

      return totals;
    } catch (e) {
      AppLogger.instance.e('Failed to get AI usage totals', error: e);
      return {
        'totalTokens': 0,
        'inputTokens': 0,
        'outputTokens': 0,
        'totalCost': 0.0,
        'requestCount': 0,
        'successfulRequests': 0,
        'failedRequests': 0,
      };
    }
  }

  @override
  Future<void> close() async {
    await _usageBox?.close();
    _usageBox = null;
    _invalidateCache();
  }
}