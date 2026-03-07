import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/providers/offline_status_providers.dart';
import 'package:pma_core/widgets/offline_indicator.dart';

class _TestOfflineStatusNotifier extends OfflineStatusNotifier {
  _TestOfflineStatusNotifier(this._initialState);

  final OfflineStatusState _initialState;
  bool manualSyncCalled = false;

  @override
  OfflineStatusState build() {
    return _initialState;
  }

  @override
  Future<void> manualSync() async {
    manualSyncCalled = true;
    state = OfflineStatusState.synced(
      lastSyncTime: DateTime(2026, 3, 7, 10, 30),
    );
  }
}

void main() {
  group('Offline status colors', () {
    test('maps synced/syncing/offline to required colors', () {
      expect(OfflineStatusState.synced().statusColor, Colors.green);
      expect(OfflineStatusState.syncing().statusColor, Colors.orange);
      expect(OfflineStatusState.offline().statusColor, Colors.red);
    });
  });

  group('OfflineIndicatorAppBar', () {
    testWidgets('tap opens sync sheet and manual sync updates status', (
      tester,
    ) async {
      final notifier = _TestOfflineStatusNotifier(
        OfflineStatusState.offline(
          lastSyncTime: DateTime(2026, 3, 6, 9, 15),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineStatusProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: OfflineIndicatorAppBar(
                appBar: AppBar(title: const Text('Projects')),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.textContaining('Offline | Offline'), findsOneWidget);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Sync Status'), findsOneWidget);
      expect(find.text('Last sync'), findsOneWidget);
      expect(find.text('Manual Sync Now'), findsOneWidget);

      await tester.tap(find.text('Manual Sync Now'));
      await tester.pumpAndSettle();

      expect(notifier.manualSyncCalled, isTrue);
      expect(find.textContaining('Online | Synced'), findsWidgets);
    });
  });
}
