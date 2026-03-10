import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CompileRunnerFileWritePolicy {
  const CompileRunnerFileWritePolicy({
    this.allowedPathPrefixes = const <String>[
      'lib/',
      'bin/',
      'test/',
      'web/',
      'assets/',
      'config/',
      'tool/',
      '.vscode/',
      'analysis_options.yaml',
      'pubspec.yaml',
      'pubspec.lock',
      'README.md',
      'CHANGELOG.md',
      'LICENSE',
      'main.dart',
    ],
    this.deniedPathPrefixes = const <String>[
      '.git/',
      '.dart_tool/',
      '.idea/',
      'build/',
      'android/',
      'ios/',
      'linux/',
      'macos/',
      'windows/',
      'node_modules/',
    ],
    this.deniedFileExtensions = const <String>[
      '.exe',
      '.dll',
      '.so',
      '.dylib',
      '.bat',
      '.cmd',
      '.ps1',
      '.sh',
      '.msi',
      '.apk',
      '.ipa',
      '.jar',
      '.class',
      '.pyc',
      '.pdb',
      '.tmp',
    ],
    this.maxFileBytes = 512 * 1024,
  });

  final List<String> allowedPathPrefixes;
  final List<String> deniedPathPrefixes;
  final List<String> deniedFileExtensions;
  final int maxFileBytes;
}

class CompileRunnerContractError {
  const CompileRunnerContractError({
    required this.code,
    required this.message,
    required this.retryable,
    required this.requestId,
    this.details,
  });

  final String code;
  final String message;
  final bool retryable;
  final String requestId;
  final Object? details;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'message': message,
      'retryable': retryable,
      'requestId': requestId,
      if (details != null) 'details': details,
    };
  }
}

class CompileRunnerInput {
  const CompileRunnerInput({
    required this.projectId,
    required this.taskId,
    required this.files,
    required this.metadata,
  });

  final String projectId;
  final String taskId;
  final Map<String, String> files;
  final Map<String, dynamic> metadata;
}

class CompileExecutionResult {
  const CompileExecutionResult({
    required this.success,
    required this.logs,
    required this.errors,
    required this.warnings,
    required this.outputFiles,
    required this.artifactPath,
    this.contractError,
  });

  final bool success;
  final List<String> logs;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, String> outputFiles;
  final String? artifactPath;
  final CompileRunnerContractError? contractError;
}

class CompileRunner {
  CompileRunner({
    required this.workspaceRoot,
    this.fileWritePolicy = const CompileRunnerFileWritePolicy(),
  });

  final String workspaceRoot;
  final CompileRunnerFileWritePolicy fileWritePolicy;

  Future<CompileExecutionResult> run(CompileRunnerInput request) async {
    final requestId = 'compile-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final logs = <String>[];
    final warnings = <String>[];
    final errors = <String>[];

    if (request.projectId.isEmpty || request.taskId.isEmpty) {
      return _contractErrorResult(
        requestId: requestId,
        code: 'bad_request',
        message: 'Missing projectId or taskId.',
        details: const <String, Object>{
          'required': <String>['projectId', 'taskId'],
        },
      );
    }

    final writeValidation = _validateFileWritePolicy(
      files: request.files,
      requestId: requestId,
    );
    if (writeValidation != null) {
      return _contractErrorResult(
        requestId: requestId,
        code: writeValidation.code,
        message: writeValidation.message,
        details: writeValidation.details,
      );
    }

    final workspace = Directory(
      '$workspaceRoot/${request.projectId}/${request.taskId}/${DateTime.now().millisecondsSinceEpoch}',
    );
    await workspace.create(recursive: true);

    final writeResult = await _writeFiles(workspace, request.files, requestId);
    if (writeResult != null) {
      return _contractErrorResult(
        requestId: requestId,
        code: writeResult.code,
        message: writeResult.message,
        details: writeResult.details,
      );
    }

    final pubspec = File('${workspace.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      final pubGet = await _runCommand(
        executable: 'flutter',
        arguments: const <String>['pub', 'get'],
        workingDirectory: workspace.path,
        timeout: const Duration(minutes: 3),
      );
      logs.addAll(pubGet.logs);
      if (!pubGet.success) {
        errors.add('flutter pub get failed');
        errors.addAll(pubGet.errors);
        return CompileExecutionResult(
          success: false,
          logs: logs,
          errors: errors,
          warnings: warnings,
          outputFiles: Map<String, String>.from(request.files),
          artifactPath: null,
        );
      }
    } else {
      warnings.add('pubspec.yaml not found; skipping flutter pub get.');
    }

    final buildTarget =
        (request.metadata['buildTarget'] ?? request.metadata['build_target'] ?? 'auto')
            .toString()
            .toLowerCase();

    String? artifactPath;
    if (buildTarget == 'flutter' ||
        (buildTarget == 'auto' && await _hasFlutterEntrypoint(workspace))) {
      final flutterBuild = await _runCommand(
        executable: 'flutter',
        arguments: const <String>['build', 'web', '--release'],
        workingDirectory: workspace.path,
        timeout: const Duration(minutes: 10),
      );
      logs.addAll(flutterBuild.logs);
      if (!flutterBuild.success) {
        errors.add('flutter build failed');
        errors.addAll(flutterBuild.errors);
      } else {
        artifactPath = '${workspace.path}/build/web';
      }
    }

    if (artifactPath == null) {
      final dartEntrypoint = await _resolveDartEntrypoint(workspace);
      if (dartEntrypoint == null) {
        errors.add('No valid Dart entrypoint found (bin/main.dart or main.dart).');
      } else {
        final outputFile = '${workspace.path}/build/app.exe';
        final outputDir = Directory('${workspace.path}/build');
        await outputDir.create(recursive: true);

        final dartCompile = await _runCommand(
          executable: 'dart',
          arguments: <String>['compile', 'exe', dartEntrypoint, '-o', outputFile],
          workingDirectory: workspace.path,
          timeout: const Duration(minutes: 5),
        );
        logs.addAll(dartCompile.logs);
        if (!dartCompile.success) {
          errors.add('dart compile failed');
          errors.addAll(dartCompile.errors);
        } else {
          artifactPath = outputFile;
        }
      }
    }

    final success = errors.isEmpty && artifactPath != null;
    return CompileExecutionResult(
      success: success,
      logs: logs,
      errors: errors,
      warnings: warnings,
      outputFiles: Map<String, String>.from(request.files),
      artifactPath: artifactPath,
    );
  }

  CompileExecutionResult _contractErrorResult({
    required String requestId,
    required String code,
    required String message,
    Object? details,
  }) {
    final contractError = CompileRunnerContractError(
      code: code,
      message: message,
      retryable: false,
      requestId: requestId,
      details: details,
    );
    return CompileExecutionResult(
        success: false,
        logs: <String>[],
        errors: <String>['$code: $message'],
        warnings: <String>[],
        outputFiles: <String, String>{},
        artifactPath: null,
        contractError: contractError,
      );
  }

  _FileWritePolicyViolation? _validateFileWritePolicy({
    required Map<String, String> files,
    required String requestId,
  }) {
    for (final entry in files.entries) {
      final normalized = _normalizePath(entry.key);
      if (normalized == null) {
        return _FileWritePolicyViolation(
          code: 'bad_request',
          message: 'Invalid file path; traversal or absolute paths are not allowed.',
          details: <String, Object?>{
            'path': entry.key,
            'requestId': requestId,
          },
        );
      }

      if (_isDeniedPath(normalized)) {
        return _FileWritePolicyViolation(
          code: 'forbidden_path',
          message: 'File path is denied by write policy.',
          details: <String, Object?>{
            'path': normalized,
            'requestId': requestId,
          },
        );
      }

      if (!_isAllowedPath(normalized)) {
        return _FileWritePolicyViolation(
          code: 'forbidden_path',
          message: 'File path is outside allowed write prefixes.',
          details: <String, Object?>{
            'path': normalized,
            'allowedPathPrefixes': fileWritePolicy.allowedPathPrefixes,
            'requestId': requestId,
          },
        );
      }

      if (_isDeniedFileType(normalized)) {
        return _FileWritePolicyViolation(
          code: 'forbidden_file_type',
          message: 'File type is denied by write policy.',
          details: <String, Object?>{
            'path': normalized,
            'deniedFileExtensions': fileWritePolicy.deniedFileExtensions,
            'requestId': requestId,
          },
        );
      }

      final bytes = utf8.encode(entry.value).length;
      if (bytes > fileWritePolicy.maxFileBytes) {
        return _FileWritePolicyViolation(
          code: 'payload_too_large',
          message: 'File content exceeds per-file size limit.',
          details: <String, Object?>{
            'path': normalized,
            'maxFileBytes': fileWritePolicy.maxFileBytes,
            'receivedBytes': bytes,
            'requestId': requestId,
          },
        );
      }
    }

    return null;
  }

  Future<_FileWritePolicyViolation?> _writeFiles(
    Directory workspace,
    Map<String, String> files,
    String requestId,
  ) async {
    for (final entry in files.entries) {
      final normalized = _normalizePath(entry.key);
      if (normalized == null) {
        return _FileWritePolicyViolation(
          code: 'bad_request',
          message: 'Invalid file path; traversal or absolute paths are not allowed.',
          details: <String, Object?>{
            'path': entry.key,
            'requestId': requestId,
          },
        );
      }
      final target = File('${workspace.path}/$normalized');
      await target.parent.create(recursive: true);
      await target.writeAsString(entry.value);
    }
    return null;
  }

  String? _normalizePath(String raw) {
    final normalized = raw.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.startsWith('/') || normalized.startsWith('~')) {
      return null;
    }
    if (normalized.contains(':')) {
      return null;
    }

    final parts = normalized.split('/');
    if (parts.any((part) => part.isEmpty || part == '.' || part == '..')) {
      return null;
    }

    return parts.join('/');
  }

  bool _isAllowedPath(String normalizedPath) {
    for (final prefix in fileWritePolicy.allowedPathPrefixes) {
      final normalizedPrefix = prefix.replaceAll('\\', '/');
      if (normalizedPath == normalizedPrefix ||
          normalizedPath.startsWith(normalizedPrefix)) {
        return true;
      }
    }
    return false;
  }

  bool _isDeniedPath(String normalizedPath) {
    for (final prefix in fileWritePolicy.deniedPathPrefixes) {
      final normalizedPrefix = prefix.replaceAll('\\', '/');
      if (normalizedPath == normalizedPrefix ||
          normalizedPath.startsWith(normalizedPrefix)) {
        return true;
      }
    }
    return false;
  }

  bool _isDeniedFileType(String normalizedPath) {
    final lowercasePath = normalizedPath.toLowerCase();
    for (final extension in fileWritePolicy.deniedFileExtensions) {
      if (lowercasePath.endsWith(extension.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _hasFlutterEntrypoint(Directory workspace) async {
    final flutterMain = File('${workspace.path}/lib/main.dart');
    return flutterMain.exists();
  }

  Future<String?> _resolveDartEntrypoint(Directory workspace) async {
    final binMain = File('${workspace.path}/bin/main.dart');
    if (await binMain.exists()) {
      return 'bin/main.dart';
    }

    final rootMain = File('${workspace.path}/main.dart');
    if (await rootMain.exists()) {
      return 'main.dart';
    }

    return null;
  }

  Future<CommandResult> _runCommand({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
  }) async {
    try {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
      );

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      final exitCode = await process.exitCode.timeout(timeout);
      final stdoutText = await stdoutFuture;
      final stderrText = await stderrFuture;

      final combinedLogs = <String>[];
      if (stdoutText.trim().isNotEmpty) {
        combinedLogs.add(stdoutText.trim());
      }
      if (stderrText.trim().isNotEmpty) {
        combinedLogs.add(stderrText.trim());
      }

      return CommandResult(
        success: exitCode == 0,
        logs: combinedLogs,
        errors: exitCode == 0 ? const <String>[] : combinedLogs,
      );
    } on TimeoutException {
      return CommandResult(
        success: false,
        logs: const <String>[],
        errors: <String>['$executable timed out after ${timeout.inSeconds}s'],
      );
    } catch (error) {
      return CommandResult(
        success: false,
        logs: const <String>[],
        errors: <String>[error.toString()],
      );
    }
  }
}

class _FileWritePolicyViolation {
  const _FileWritePolicyViolation({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;
}

class CommandResult {
  const CommandResult({
    required this.success,
    required this.logs,
    required this.errors,
  });

  final bool success;
  final List<String> logs;
  final List<String> errors;
}
