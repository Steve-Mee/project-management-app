import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project detail screen reads project via projectByIdProvider', () async {
    final file = File('lib/features/project/project_detail_screen.dart');
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();
    expect(content.contains('projectByIdProvider('), isTrue);
    expect(content.contains('projectsProvider.notifier).getProjectById('), isFalse);
  });

  test('project feature runtime files avoid deprecated notifier getProjectById calls', () async {
    final projectFeatureDir = Directory('lib/features/project');
    expect(projectFeatureDir.existsSync(), isTrue);

    final forbiddenPattern = RegExp(r'projectsProvider\.notifier\)\.getProjectById\(');
    final offendingFiles = <String>[];

    await for (final entity in projectFeatureDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final content = await entity.readAsString();
      if (forbiddenPattern.hasMatch(content)) {
        offendingFiles.add(entity.path.replaceAll('\\', '/'));
      }
    }

    expect(offendingFiles, isEmpty,
        reason: 'Deprecated ProjectsNotifier.getProjectById usage found in: ${offendingFiles.join(', ')}');
  });
}
