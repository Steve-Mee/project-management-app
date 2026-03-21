import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/providers/sync/sync_providers.dart';
import 'package:pma_core/services/cloud_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM-only initialization', () {
    test('main.dart initializes only Firebase Core + Messaging', () async {
      final mainFile = File('lib/main.dart');
      final source = await mainFile.readAsString();

      expect(source,
          contains("import 'package:firebase_core/firebase_core.dart';"));
      expect(
        source,
        contains(
            "import 'package:firebase_messaging/firebase_messaging.dart';"),
      );
      expect(source, contains('await Firebase.initializeApp();'));
      expect(
        source,
        contains('await FirebaseMessaging.instance.setAutoInitEnabled(true);'),
      );

      // Keep startup scoped to exactly two Firebase package imports.
      final firebaseImports = source
          .split('\n')
          .where((line) => line.contains("import 'package:firebase_"))
          .toList();
      expect(firebaseImports.length, 2);
    });
  });

  group('Push notifications', () {
    test('notification service uses FCM-only flow', () async {
      final candidatePaths = [
        'lib/core/services/notification_service.dart',
        'packages/pma_core/lib/services/notification_service.dart',
      ];
      final file = candidatePaths.map(File.new).firstWhere(
          (f) => f.existsSync(),
          orElse: () => File(candidatePaths.first));
      final source = await file.readAsString();

      expect(
          source,
          contains(
              "import 'package:firebase_messaging/firebase_messaging.dart';"));
      expect(source, contains('await _messaging.setAutoInitEnabled(true);'));
      expect(source, contains('await _messaging.requestPermission('));
      expect(source, isNot(contains('FlutterLocalNotificationsPlugin')));
    });
  });

  group('Offline + Supabase sync invariants', () {
    test('offline status remains available in sync state', () {
      expect(SyncStatus.offline().status, 'offline');
    });

    test('cloud sync service still exposes Supabase stream API', () {
      final service =
          CloudSyncService(supabaseClient: Supabase.instance.client);
      expect(service.getProjectsStream,
          isA<Stream<List<Map<String, dynamic>>> Function()>());
    });
  });
}
