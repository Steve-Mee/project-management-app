import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_context_budget_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_start_service.dart';

void main() {
  const service = MirrorRunStartService();

  group('MirrorRunStartService', () {
    test('returns terminal baseline count with no budget message when not enforced',
        () {
      const budgetService = MirrorContextBudgetService(maxBytes: 1024 * 1024);
      final files = <String, String>{
        'lib/main.dart': 'void main() {}',
      };

      final result = service.prepare(
        budgetService: budgetService,
        projectId: 'p1',
        taskId: 't1',
        files: files,
        terminalLog: const <String>['ready', 'line'],
      );

      expect(result.beforeTerminalCount, 2);
      expect(result.budgetMessage, isNull);
    });

    test('returns budget preflight message when context budget is enforced', () {
      const budgetService = MirrorContextBudgetService(maxBytes: 20);
      final files = <String, String>{
        'lib/main.dart': 'void main() { print("hello world"); }',
      };

      final result = service.prepare(
        budgetService: budgetService,
        projectId: 'p1',
        taskId: 't1',
        files: files,
        terminalLog: const <String>[],
      );

      expect(result.beforeTerminalCount, 0);
      expect(result.budgetMessage, isNotNull);
      expect(result.budgetMessage, contains('Payload budget:'));
    });
  });
}