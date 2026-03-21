@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supabase singleton migration guard', () {
    test('migrated files avoid direct Supabase.instance.client usage', () {
      const guardedFiles = <String>[
        'packages/pma_core/lib/services/cloud_sync_service.dart',
        'packages/pma_core/lib/providers/auth/auth_providers.dart',
        'packages/pma_core/lib/repository/impl/hive_project_repository.dart',
        'packages/pma_core/lib/providers/sync/sync_providers.dart',
        'packages/pma_core/lib/providers/offline_status_providers.dart',
        'packages/pma_core/lib/providers/project/project_providers.dart',
        'lib/features/project/project_plan_display.dart',
        'lib/main.dart',
      ];

      final offenders = <String>[];
      for (final path in guardedFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'Missing guarded file: $path');

        final content = file.readAsStringSync();
        if (content.contains('Supabase.instance.client')) {
          offenders.add(path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Direct Supabase singleton usage detected in guarded files: ${offenders.join(', ')}',
      );
    });
  });
}
