import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/models/ai_usage_record.dart';
import 'package:my_project_management_app/core/providers/analytics_providers.dart';
import 'package:my_project_management_app/core/repository/i_ai_usage_repository.dart';

class FakeAiUsageRepository implements IAiUsageRepository {
  final List<AiUsageRecord> _records = [];
  final Map<String, dynamic> _totals = {
    'totalTokens': 0,
    'inputTokens': 0,
    'outputTokens': 0,
    'totalCost': 0.0,
    'requestCount': 0,
    'successfulRequests': 0,
    'failedRequests': 0,
  };

  @override
  Future<void> logUsage(AiUsageRecord record) async {
    _records.add(record);
    _totals['totalTokens'] = (_totals['totalTokens'] as int) + record.inputTokens + record.outputTokens;
    _totals['inputTokens'] = (_totals['inputTokens'] as int) + record.inputTokens;
    _totals['outputTokens'] = (_totals['outputTokens'] as int) + record.outputTokens;
    _totals['totalCost'] = (_totals['totalCost'] as double) + record.estimatedCost;
    _totals['requestCount'] = (_totals['requestCount'] as int) + 1;
    if (record.success) {
      _totals['successfulRequests'] = (_totals['successfulRequests'] as int) + 1;
    } else {
      _totals['failedRequests'] = (_totals['failedRequests'] as int) + 1;
    }
  }

  @override
  Future<List<AiUsageRecord>> getUsageHistory({
    DateTime? from,
    DateTime? to,
    String? userId,
    String? projectId,
  }) async {
    var filtered = _records;
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
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  @override
  Future<Map<String, dynamic>> getUsageTotals({
    String? userId,
    String? projectId,
  }) async {
    final history = await getUsageHistory(userId: userId, projectId: projectId);
    return {
      'totalTokens': history.fold<int>(0, (sum, r) => sum + r.inputTokens + r.outputTokens),
      'inputTokens': history.fold<int>(0, (sum, r) => sum + r.inputTokens),
      'outputTokens': history.fold<int>(0, (sum, r) => sum + r.outputTokens),
      'totalCost': history.fold<double>(0.0, (sum, r) => sum + r.estimatedCost),
      'requestCount': history.length,
      'successfulRequests': history.where((r) => r.success).length,
      'failedRequests': history.where((r) => !r.success).length,
    };
  }

  @override
  Future<void> close() async {}
}

void main() {
  late FakeAiUsageRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeAiUsageRepository();
    container = ProviderContainer(
      overrides: [
        aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AiUsageNotifier', () {
    test('initial state is empty data', () {
      final notifier = container.read(aiUsageHistoryProvider.notifier);
      expect(notifier.state, const AsyncValue<List<AiUsageRecord>>.data([]));
    });

    test('logUsage calls repository and updates state', () async {
      final record = AiUsageRecord(
        id: 'test-id-1',
        operation: 'chat',
        inputTokens: 100,
        outputTokens: 50,
        estimatedCost: 0.002,
        timestamp: DateTime.now(),
        success: true,
      );

      final notifier = container.read(aiUsageHistoryProvider.notifier);
      await notifier.logUsage(record);

      expect(notifier.state.value, [record]);
      expect(fakeRepository._records, [record]);
    });

    test('fetchHistory updates state with repository data', () async {
      final record = AiUsageRecord(
        id: 'test-id-2',
        operation: 'chat',
        inputTokens: 100,
        outputTokens: 50,
        estimatedCost: 0.002,
        timestamp: DateTime.now(),
        success: true,
      );
      await fakeRepository.logUsage(record);

      final notifier = container.read(aiUsageHistoryProvider.notifier);
      await notifier.fetchHistory();

      expect(notifier.state.value, [record]);
    });

    test('fetchHistory handles errors', () async {
      // Create a failing repository for this test
      final failingRepository = _FailingAiUsageRepository();
      final testContainer = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(failingRepository),
        ],
      );

      final notifier = testContainer.read(aiUsageHistoryProvider.notifier);
      await notifier.fetchHistory();

      expect(notifier.state.error, isA<Exception>());
      testContainer.dispose();
    });

    test('getTotals calls repository with filters', () async {
      final record = AiUsageRecord(
        id: 'test-id-3',
        operation: 'chat',
        inputTokens: 100,
        outputTokens: 50,
        estimatedCost: 0.002,
        timestamp: DateTime.now(),
        success: true,
        userId: 'user1',
        projectId: 'project1',
      );
      await fakeRepository.logUsage(record);

      final notifier = container.read(aiUsageHistoryProvider.notifier);
      final result = await notifier.getTotals(userId: 'user1', projectId: 'project1');

      expect(result['totalTokens'], 150);
      expect(result['totalCost'], 0.002);
      expect(result['requestCount'], 1);
    });
  });

  group('Computed Providers', () {
    test('aiUsageTotalCostProvider calculates total cost', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-3',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
        ),
        AiUsageRecord(
          id: 'test-id-4',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: true,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
          aiUsageHistoryProvider.overrideWith((ref) => AiUsageNotifier(fakeRepository)
            ..state = AsyncValue.data(records)),
        ],
      );

      final totalCost = container.read(aiUsageTotalCostProvider);
      expect(totalCost, 0.006);
    });

    test('aiUsageByOperationProvider aggregates by operation', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-5',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
        ),
        AiUsageRecord(
          id: 'test-id-6',
          operation: 'chat',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: true,
        ),
        AiUsageRecord(
          id: 'test-id-7',
          operation: 'summarize',
          inputTokens: 150,
          outputTokens: 75,
          estimatedCost: 0.003,
          timestamp: DateTime.now(),
          success: true,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
          aiUsageHistoryProvider.overrideWith((ref) => AiUsageNotifier(fakeRepository)
            ..state = AsyncValue.data(records)),
        ],
      );

      final usageByOperation = container.read(aiUsageByOperationProvider);
      expect(usageByOperation, {'chat': 2, 'summarize': 1});
    });

    test('aiUsagePerUserProvider aggregates by user', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-8',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
          userId: 'user1',
        ),
        AiUsageRecord(
          id: 'test-id-9',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: false,
          userId: 'user1',
        ),
        AiUsageRecord(
          id: 'test-id-10',
          operation: 'chat',
          inputTokens: 150,
          outputTokens: 75,
          estimatedCost: 0.003,
          timestamp: DateTime.now(),
          success: true,
          userId: 'user2',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
          aiUsageHistoryProvider.overrideWith((ref) => AiUsageNotifier(fakeRepository)
            ..state = AsyncValue.data(records)),
        ],
      );

      final perUser = container.read(aiUsagePerUserProvider);
      expect(perUser.length, 2);
      expect(perUser['user1']!['totalTokens'], 450);
      expect(perUser['user1']!['totalCost'], 0.006);
      expect(perUser['user1']!['requestCount'], 2);
      expect(perUser['user1']!['successfulRequests'], 1);
      expect(perUser['user2']!['totalTokens'], 225);
      expect(perUser['user2']!['totalCost'], 0.003);
      expect(perUser['user2']!['requestCount'], 1);
      expect(perUser['user2']!['successfulRequests'], 1);
    });

    test('aiUsagePerProjectProvider aggregates by project', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-11',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
          projectId: 'project1',
        ),
        AiUsageRecord(
          id: 'test-id-12',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: false,
          projectId: 'project1',
        ),
        AiUsageRecord(
          id: 'test-id-13',
          operation: 'chat',
          inputTokens: 150,
          outputTokens: 75,
          estimatedCost: 0.003,
          timestamp: DateTime.now(),
          success: true,
          projectId: 'project2',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
          aiUsageHistoryProvider.overrideWith((ref) => AiUsageNotifier(fakeRepository)
            ..state = AsyncValue.data(records)),
        ],
      );

      final perProject = container.read(aiUsagePerProjectProvider);
      expect(perProject.length, 2);
      expect(perProject['project1']!['totalTokens'], 450);
      expect(perProject['project1']!['totalCost'], 0.006);
      expect(perProject['project1']!['requestCount'], 2);
      expect(perProject['project1']!['successfulRequests'], 1);
      expect(perProject['project2']!['totalTokens'], 225);
      expect(perProject['project2']!['totalCost'], 0.003);
      expect(perProject['project2']!['requestCount'], 1);
      expect(perProject['project2']!['successfulRequests'], 1);
    });
  });

  group('Helper Functions', () {
    test('calculateTotalCost sums all record costs', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-14',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
        ),
        AiUsageRecord(
          id: 'test-id-15',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: true,
        ),
      ];

      final total = calculateTotalCost(records);
      expect(total, 0.006);
    });

    test('getUsageByOperation counts operations', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-16',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
        ),
        AiUsageRecord(
          id: 'test-id-17',
          operation: 'chat',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: true,
        ),
        AiUsageRecord(
          id: 'test-id-18',
          operation: 'summarize',
          inputTokens: 150,
          outputTokens: 75,
          estimatedCost: 0.003,
          timestamp: DateTime.now(),
          success: true,
        ),
      ];

      final usage = getUsageByOperation(records);
      expect(usage, {'chat': 2, 'summarize': 1});
    });

    test('getPerUserAggregation handles null userIds', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-19',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
          userId: 'user1',
        ),
        AiUsageRecord(
          id: 'test-id-20',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: true,
          // No userId
        ),
      ];

      final aggregation = getPerUserAggregation(records);
      expect(aggregation.length, 1); // Only user1
      expect(aggregation['user1']!['totalTokens'], 150);
      expect(aggregation['user1']!['totalCost'], 0.002);
      expect(aggregation['user1']!['requestCount'], 1);
      expect(aggregation['user1']!['successfulRequests'], 1);
    });

    test('getPerProjectAggregation handles null projectIds', () {
      final records = [
        AiUsageRecord(
          id: 'test-id-21',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.002,
          timestamp: DateTime.now(),
          success: true,
          projectId: 'project1',
        ),
        AiUsageRecord(
          id: 'test-id-22',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.004,
          timestamp: DateTime.now(),
          success: true,
          // No projectId
        ),
      ];

      final aggregation = getPerProjectAggregation(records);
      expect(aggregation.length, 1); // Only project1
      expect(aggregation['project1']!['totalTokens'], 150);
      expect(aggregation['project1']!['totalCost'], 0.002);
      expect(aggregation['project1']!['requestCount'], 1);
      expect(aggregation['project1']!['successfulRequests'], 1);
    });
  });

  group('Edge Cases', () {
    test('providers return defaults when history is loading', () {
      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
          aiUsageHistoryProvider.overrideWith((ref) => AiUsageNotifier(fakeRepository)
            ..state = const AsyncValue.loading()),
        ],
      );

      final totalCost = container.read(aiUsageTotalCostProvider);
      final usageByOperation = container.read(aiUsageByOperationProvider);
      final perUser = container.read(aiUsagePerUserProvider);
      final perProject = container.read(aiUsagePerProjectProvider);

      expect(totalCost, 0.0);
      expect(usageByOperation, {});
      expect(perUser, {});
      expect(perProject, {});
    });

    test('providers return defaults when history has error', () {
      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepository),
          aiUsageHistoryProvider.overrideWith((ref) => AiUsageNotifier(fakeRepository)
            ..state = AsyncValue.error(Exception('Test error'), StackTrace.empty)),
        ],
      );

      final totalCost = container.read(aiUsageTotalCostProvider);
      final usageByOperation = container.read(aiUsageByOperationProvider);
      final perUser = container.read(aiUsagePerUserProvider);
      final perProject = container.read(aiUsagePerProjectProvider);

      expect(totalCost, 0.0);
      expect(usageByOperation, {});
      expect(perUser, {});
      expect(perProject, {});
    });

    test('empty records return zero values', () {
      final total = calculateTotalCost([]);
      final usage = getUsageByOperation([]);
      final perUser = getPerUserAggregation([]);
      final perProject = getPerProjectAggregation([]);

      expect(total, 0.0);
      expect(usage, {});
      expect(perUser, {});
      expect(perProject, {});
    });
  });
}

class _FailingAiUsageRepository implements IAiUsageRepository {
  @override
  Future<void> logUsage(AiUsageRecord record) async {
    throw Exception('Test error');
  }

  @override
  Future<List<AiUsageRecord>> getUsageHistory({
    DateTime? from,
    DateTime? to,
    String? userId,
    String? projectId,
  }) async {
    throw Exception('Test error');
  }

  @override
  Future<Map<String, dynamic>> getUsageTotals({
    String? userId,
    String? projectId,
  }) async {
    throw Exception('Test error');
  }

  @override
  Future<void> close() async {}
}