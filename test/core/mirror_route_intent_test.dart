import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/mirror_route_intent.dart';

void main() {
  group('mirror route intent parsing', () {
    test('parses valid mirror path', () {
      final parsed = tryParseMirrorRouteIntent('/mirror/project-1/task-2');

      expect(parsed, isNotNull);
      expect(parsed!.projectId, equals('project-1'));
      expect(parsed.taskId, equals('task-2'));
    });

    test('parses valid mirror path with query params', () {
      final parsed = tryParseMirrorRouteIntent('/mirror/p/t?foo=bar');

      expect(parsed, isNotNull);
      expect(parsed!.projectId, equals('p'));
      expect(parsed.taskId, equals('t'));
    });

    test('rejects non-mirror route', () {
      expect(tryParseMirrorRouteIntent('/projects/123'), isNull);
      expect(isMirrorRouteIntent('/projects/123'), isFalse);
    });

    test('rejects incomplete mirror route', () {
      expect(tryParseMirrorRouteIntent('/mirror/project-only'), isNull);
      expect(isMirrorRouteIntent('/mirror/project-only'), isFalse);
    });
  });
}
