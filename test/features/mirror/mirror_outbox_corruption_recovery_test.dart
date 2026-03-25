import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_outbox_replay_service.dart';

void main() {
  group('Mirror outbox corruption recovery', () {
    test('classifies corruption reasons into explicit recovery actions', () {
      expect(
        MirrorOutboxEntry.recoveryActionForReason('missing_required_fields'),
        MirrorOutboxCorruptionRecoveryAction.migrateLegacy,
      );
      expect(
        MirrorOutboxEntry.recoveryActionForReason('context_not_map'),
        MirrorOutboxCorruptionRecoveryAction.migrateLegacy,
      );
      expect(
        MirrorOutboxEntry.recoveryActionForReason('invalid_created_at'),
        MirrorOutboxCorruptionRecoveryAction.quarantine,
      );
      expect(
        MirrorOutboxEntry.recoveryActionForReason('raw_not_map'),
        MirrorOutboxCorruptionRecoveryAction.quarantine,
      );
    });

    test('migrates legacy snake_case payloads when fields are recoverable', () {
      final entry = MirrorOutboxEntry.tryRecoverLegacyFromRaw(
        <String, dynamic>{
          'operation': 'generate',
          'prompt': 'legacy prompt',
          'mode': 'private',
          'created_at': '2026-03-20T10:00:00Z',
          'project_id': 'project-1',
          'task_id': 'task-1',
          'files': <String, String>{'lib/main.dart': 'void main() {}'},
          'metadata': <String, dynamic>{'branch': 'legacy'},
          'idempotency_key': 'idem-legacy',
        },
        reason: 'missing_required_fields',
      );

      expect(entry, isNotNull);
      expect(entry!.sessionKey, 'project-1::task-1');
      expect(entry.context.projectId, 'project-1');
      expect(entry.context.taskId, 'task-1');
      expect(entry.idempotencyKey, 'idem-legacy');
    });

    test('does not migrate when policy says quarantine', () {
      final entry = MirrorOutboxEntry.tryRecoverLegacyFromRaw(
        <String, dynamic>{
          'operation': 'generate',
          'prompt': 'legacy prompt',
          'created_at': '2026-03-20T10:00:00Z',
          'project_id': 'project-1',
          'task_id': 'task-1',
        },
        reason: 'invalid_created_at',
      );

      expect(entry, isNull);
    });

    test('reports raw_not_map for invalid root payloads', () {
      String? reason;

      final entry = MirrorOutboxEntry.fromRaw(
        'not-a-map',
        onFailure: (value) => reason = value,
      );

      expect(entry, isNull);
      expect(reason, 'raw_not_map');
    });

    test('reports missing_required_fields for incomplete payloads', () {
      String? reason;

      final entry = MirrorOutboxEntry.fromRaw(
        <String, dynamic>{
          'operation': 'generate',
          'sessionKey': 'project::task',
          'prompt': 'hello',
          'mode': 'private',
          'context': <String, dynamic>{
            'projectId': 'project',
            'taskId': 'task',
            'files': <String, String>{},
            'metadata': <String, dynamic>{},
          },
        },
        onFailure: (value) => reason = value,
      );

      expect(entry, isNull);
      expect(reason, 'missing_required_fields');
    });

    test('reports invalid_created_at for malformed timestamps', () {
      String? reason;

      final entry = MirrorOutboxEntry.fromRaw(
        <String, dynamic>{
          'operation': 'generate',
          'sessionKey': 'project::task',
          'prompt': 'hello',
          'mode': 'private',
          'createdAt': 'not-a-date',
          'context': <String, dynamic>{
            'projectId': 'project',
            'taskId': 'task',
            'files': <String, String>{},
            'metadata': <String, dynamic>{},
          },
        },
        onFailure: (value) => reason = value,
      );

      expect(entry, isNull);
      expect(reason, 'invalid_created_at');
    });
  });
}
