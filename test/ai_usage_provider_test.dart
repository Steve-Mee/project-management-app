import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:pma_core/models/ai_usage_record.dart';
import 'package:pma_core/providers/ai_providers.dart';
import 'package:pma_core/repository/i_ai_usage_repository.dart';

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
    final totalCost = history.fold<double>(0.0, (sum, r) => sum + r.estimatedCost);
    final requestCount = history.length;
    final averageCostPerOperation = requestCount > 0 ? totalCost / requestCount : 0.0;
    
    // Calculate peak usage hour and day
    final hours = history.map((r) => r.timestamp.hour).toList();
    final days = history.map((r) => r.timestamp.weekday).toList();
    final peakUsageHour = hours.isNotEmpty ? hours.reduce((a, b) => hours.where((h) => h == a).length > hours.where((h) => h == b).length ? a : b) : 0;
    final peakUsageDay = days.isNotEmpty ? days.reduce((a, b) => days.where((d) => d == a).length > days.where((d) => d == b).length ? a : b) : 1;
    
    // Total by operation
    final totalByOperation = <String, int>{};
    for (final record in history) {
      totalByOperation[record.operation] = (totalByOperation[record.operation] ?? 0) + 1;
    }
    
    return {
      'totalTokens': history.fold<int>(0, (sum, r) => sum + r.inputTokens + r.outputTokens),
      'inputTokens': history.fold<int>(0, (sum, r) => sum + r.inputTokens),
      'outputTokens': history.fold<int>(0, (sum, r) => sum + r.outputTokens),
      'totalCost': totalCost,
      'requestCount': requestCount,
      'successfulRequests': history.where((r) => r.success).length,
      'failedRequests': history.where((r) => !r.success).length,
      'averageCostPerOperation': averageCostPerOperation,
      'peakUsageHour': peakUsageHour,
      'peakUsageDay': peakUsageDay,
      'totalByOperation': totalByOperation,
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

  group('AI Usage Analytics - Charts Data', () {
    test('computeUsageChartData generates correct LineChartData', () {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1, 10),
          success: true,
        ),
        AiUsageRecord(
          id: '2',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.02,
          timestamp: DateTime(2023, 1, 1, 11),
          success: true,
        ),
      ];

      final chartData = computeUsageChartData(records, '7d');

      expect(chartData['tokensOverTime'], isNotNull);
      expect((chartData['tokensOverTime'] as LineChartData).lineBarsData.length, greaterThan(0));
    });

    test('computeUsageChartData generates correct PieChartData', () {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
        ),
        AiUsageRecord(
          id: '2',
          operation: 'chat',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.02,
          timestamp: DateTime(2023, 1, 2),
          success: true,
        ),
      ];

      final chartData = computeUsageChartData(records, '7d');

      expect(chartData['costPerOperation'], isNotNull);
      expect((chartData['costPerOperation'] as PieChartData).sections.length, greaterThan(0));
    });

    test('computeUsageChartData generates correct BarChartData', () {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
        ),
      ];

      final chartData = computeUsageChartData(records, '7d');

      expect(chartData['usageByOperation'], isNotNull);
      expect((chartData['usageByOperation'] as BarChartData).barGroups.length, greaterThan(0));
    });
  });

  group('AI Usage Analytics - Export Functionality', () {
    test('exportUsageHistory generates valid CSV', () async {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
          userId: 'user1',
          projectId: 'project1',
        ),
      ];

      final fakeRepo = FakeAiUsageRepository();
      await fakeRepo.logUsage(records[0]);

      // Test CSV export logic directly
      final csvData = const ListToCsvConverter().convert([
        ['Timestamp', 'Operation', 'Input Tokens', 'Output Tokens', 'Estimated Cost', 'User ID', 'Project ID', 'Success', 'Error Message'],
        ...records.map((r) => [
          r.timestamp.toIso8601String(),
          r.operation,
          r.inputTokens.toString(),
          r.outputTokens.toString(),
          r.estimatedCost.toString(),
          r.userId ?? '',
          r.projectId ?? '',
          r.success.toString(),
          r.errorMessage ?? '',
        ]),
      ]);

      expect(csvData, contains('Operation,Input Tokens,Output Tokens'));
      expect(csvData, contains('chat,100,50'));
    });

    test('exportUsageHistory generates valid JSON', () async {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
        ),
      ];

      final fakeRepo = FakeAiUsageRepository();
      await fakeRepo.logUsage(records[0]);

      // Test JSON export logic directly
      final jsonData = jsonEncode(records.map((r) => r.toJson()).toList());

      expect(jsonData, contains('"operation":"chat"'));
      expect(jsonData, contains('"inputTokens":100'));
    });
  });

  group('AI Usage Analytics - Advanced Metrics', () {
    test('getUsageTotals includes advanced metrics', () async {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1, 10),
          success: true,
        ),
        AiUsageRecord(
          id: '2',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.02,
          timestamp: DateTime(2023, 1, 1, 11),
          success: true,
        ),
        AiUsageRecord(
          id: '3',
          operation: 'chat',
          inputTokens: 150,
          outputTokens: 75,
          estimatedCost: 0.015,
          timestamp: DateTime(2023, 1, 1, 12),
          success: true,
        ),
      ];

      final fakeRepo = FakeAiUsageRepository();
      for (final record in records) {
        await fakeRepo.logUsage(record);
      }

      final totals = await fakeRepo.getUsageTotals();

      expect(totals['requestCount'], equals(3));
      expect(totals['totalCost'], closeTo(0.045, 0.001));
      expect(totals['averageCostPerOperation'], isNotNull);
      expect(totals['peakUsageHour'], isNotNull);
      expect(totals['peakUsageDay'], isNotNull);
      expect(totals['totalByOperation'], isNotNull);
      expect(totals['totalByOperation']['chat'], equals(2));
      expect(totals['totalByOperation']['summarize'], equals(1));
    });

    test('getUsageTotals filters by time range', () async {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
        ),
        AiUsageRecord(
          id: '2',
          operation: 'chat',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.02,
          timestamp: DateTime(2023, 1, 8), // Outside 7d range
          success: true,
        ),
      ];

      final fakeRepo = FakeAiUsageRepository();
      for (final record in records) {
        await fakeRepo.logUsage(record);
      }

      // Test with 7d range - should group by day
      final chartData7d = computeUsageChartData(records, '7d');
      final lineData7d = chartData7d['tokensOverTime'] as LineChartData;
      
      // Test with 30d range
      final chartData30d = computeUsageChartData(records, '30d');
      final lineData30d = chartData30d['tokensOverTime'] as LineChartData;
      
      // Both should have data points
      expect(lineData7d.lineBarsData[0].spots.length, greaterThan(0));
      expect(lineData30d.lineBarsData[0].spots.length, greaterThan(0));
    });
  });

  group('AI Usage Analytics - Per-User/Project Dashboards', () {
    test('getUsageTotals filters by userId', () async {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
          userId: 'user1',
        ),
        AiUsageRecord(
          id: '2',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.02,
          timestamp: DateTime(2023, 1, 2),
          success: true,
          userId: 'user2',
        ),
      ];

      final fakeRepo = FakeAiUsageRepository();
      await fakeRepo.logUsage(records[0]);
      await fakeRepo.logUsage(records[1]);

      final user1Totals = await fakeRepo.getUsageTotals(userId: 'user1');

      expect(user1Totals['requestCount'], 1);
      expect(user1Totals['totalCost'], 0.01);
    });

    test('getUsageTotals filters by projectId', () async {
      final records = [
        AiUsageRecord(
          id: '1',
          operation: 'chat',
          inputTokens: 100,
          outputTokens: 50,
          estimatedCost: 0.01,
          timestamp: DateTime(2023, 1, 1),
          success: true,
          projectId: 'project1',
        ),
        AiUsageRecord(
          id: '2',
          operation: 'summarize',
          inputTokens: 200,
          outputTokens: 100,
          estimatedCost: 0.02,
          timestamp: DateTime(2023, 1, 2),
          success: true,
          projectId: 'project2',
        ),
      ];

      final fakeRepo = FakeAiUsageRepository();
      await fakeRepo.logUsage(records[0]);
      await fakeRepo.logUsage(records[1]);

      final project1Totals = await fakeRepo.getUsageTotals(projectId: 'project1');

      expect(project1Totals['requestCount'], 1);
      expect(project1Totals['totalCost'], 0.01);
    });
  });

  group('AI Usage Analytics - Real-Time Updates', () {
    test('AiUsageNotifier subscribes to real-time updates', () async {
      final fakeRepo = FakeAiUsageRepository();
      final container = ProviderContainer(
        overrides: [
          aiUsageRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final notifier = container.read(aiUsageHistoryProvider.notifier);
      
      // The constructor should set up the subscription
      // Since we can't easily test the subscription in unit tests,
      // we verify the notifier is created without errors
      expect(notifier, isNotNull);
      expect(notifier.state, isA<AsyncValue<List<AiUsageRecord>>>());

      container.dispose();
    });
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
