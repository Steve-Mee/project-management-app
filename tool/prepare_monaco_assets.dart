import 'dart:io';

Future<void> main() async {
  const sourcePath = 'node_modules/monaco-editor/min/vs';
  const targetPath = 'assets/monaco/vs';

  final sourceDir = Directory(sourcePath);
  if (!sourceDir.existsSync()) {
    stderr.writeln(
      'Missing Monaco source at $sourcePath. '
      'Run: npm install --save-dev monaco-editor@0.52.2',
    );
    exitCode = 1;
    return;
  }

  final targetDir = Directory(targetPath);
  if (targetDir.existsSync()) {
    targetDir.deleteSync(recursive: true);
  }
  targetDir.createSync(recursive: true);

  await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
    final relativePath = entity.path.substring(sourceDir.path.length + 1);
    final destinationPath =
      '${targetDir.path}${Platform.pathSeparator}$relativePath';

    if (entity is Directory) {
      Directory(destinationPath).createSync(recursive: true);
      continue;
    }

    if (entity is File) {
      final destinationFile = File(destinationPath);
      destinationFile.parent.createSync(recursive: true);
      await entity.copy(destinationFile.path);
    }
  }

  stdout.writeln('Monaco assets synced to $targetPath from monaco-editor@0.52.2');
}
