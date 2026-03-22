import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/mirror_route_intent.dart';

void main() {
  group('mirror route intent parsing', () {
    test('parses valid mirror path', () {
      final parsed = tryParseMirrorRouteIntent(
        '/mirror/11111111-1111-4111-8111-111111111111/22222222-2222-4222-8222-222222222222',
      );

      expect(parsed, isNotNull);
      expect(parsed!.projectId, equals('11111111-1111-4111-8111-111111111111'));
      expect(parsed.taskId, equals('22222222-2222-4222-8222-222222222222'));
    });

    test('parses valid mirror path with query params', () {
      final parsed = tryParseMirrorRouteIntent(
        '/mirror/33333333-3333-4333-8333-333333333333/44444444-4444-4444-8444-444444444444?foo=bar',
      );

      expect(parsed, isNotNull);
      expect(parsed!.projectId, equals('33333333-3333-4333-8333-333333333333'));
      expect(parsed.taskId, equals('44444444-4444-4444-8444-444444444444'));
    });

    test('rejects non-mirror route', () {
      expect(tryParseMirrorRouteIntent('/projects/123'), isNull);
      expect(isMirrorRouteIntent('/projects/123'), isFalse);
    });

    test('rejects incomplete mirror route', () {
      expect(tryParseMirrorRouteIntent('/mirror/project-only'), isNull);
      expect(isMirrorRouteIntent('/mirror/project-only'), isFalse);
    });

    test('rejects mirror route with invalid projectId UUID', () {
      expect(
        tryParseMirrorRouteIntent(
          '/mirror/not-a-uuid/22222222-2222-4222-8222-222222222222',
        ),
        isNull,
      );
      expect(
        isMirrorRouteIntent(
          '/mirror/not-a-uuid/22222222-2222-4222-8222-222222222222',
        ),
        isFalse,
      );
    });

    test('rejects mirror route with invalid taskId UUID', () {
      expect(
        tryParseMirrorRouteIntent(
          '/mirror/11111111-1111-4111-8111-111111111111/not-a-uuid',
        ),
        isNull,
      );
      expect(
        isMirrorRouteIntent(
          '/mirror/11111111-1111-4111-8111-111111111111/not-a-uuid',
        ),
        isFalse,
      );
    });
  });
}
