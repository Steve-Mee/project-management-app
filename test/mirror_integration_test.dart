import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/mirror_compute_backend.dart';

// Run this test with:
// flutter test test/mirror_integration_test.dart -r expanded
void main() {
  group('Mirror integration simulation', () {
    test('simulates Private vs Cloud mode and prints diff', () async {
      final backend = _FakeMirrorBackend();
      final context = ProjectContext(
        projectId: 'project-123',
        taskId: 'task-456',
        files: const <String, String>{
          'lib/main.dart': 'void main() {}',
        },
        metadata: const <String, dynamic>{
          'teamMode': true,
        },
      );

      final privateResult = await backend.compile(
        prompt: 'Add a logging line',
        context: context,
        mode: 'private',
      );
      final cloudResult = await backend.compile(
        prompt: 'Add a logging line',
        context: context,
        mode: 'cloud',
      );

      final diff = _buildLineDiff(
        privateResult.output ?? '',
        cloudResult.output ?? '',
      );

      // Visible in test output using -r expanded.
      // ignore: avoid_print
      print('Mode diff:\n$diff');

      expect(privateResult.success, isTrue);
      expect(cloudResult.success, isTrue);
      expect(diff, contains('- mode: private'));
      expect(diff, contains('+ mode: cloud'));
      expect(diff, contains('+ backend: fly'));
    });
  });
}

class _FakeMirrorBackend implements MirrorComputeBackend {
  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return GenerateResult(
      success: true,
      code: '// generated for $mode',
      message: 'ok',
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final output = mode == 'cloud'
        ? 'mode: cloud\nbackend: fly\nresult: optimized\n'
        : 'mode: private\nbackend: local\nresult: deterministic\n';

    return CompileResult(success: true, output: output);
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return ApplyResult(
      success: true,
      appliedFiles: context.files.keys.toList(),
      message: 'applied in $mode',
    );
  }
}

String _buildLineDiff(String before, String after) {
  final beforeLines = before.trimRight().split('\n');
  final afterLines = after.trimRight().split('\n');
  final maxLen = beforeLines.length > afterLines.length
      ? beforeLines.length
      : afterLines.length;

  final rows = <String>[];
  for (var i = 0; i < maxLen; i++) {
    final left = i < beforeLines.length ? beforeLines[i] : null;
    final right = i < afterLines.length ? afterLines[i] : null;

    if (left == right) {
      if (left != null) {
        rows.add('  $left');
      }
      continue;
    }

    if (left != null) {
      rows.add('- $left');
    }
    if (right != null) {
      rows.add('+ $right');
    }
  }

  return rows.join('\n');
}
