import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final server = Server.create(
    services: <Service>[MirrorCompileService()],
    codecRegistry: CodecRegistry(codecs: const <Codec>[GzipCodec(), IdentityCodec()]),
  );

  await server.serve(address: '0.0.0.0', port: port);
  stdout.writeln('mirror-cloud-runner gRPC compile service listening on port $port');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.shutdown();
    exit(0);
  });
}

class MirrorCompileService extends Service {
  @override
  String get $name => 'mirror.compute.v1.MirrorComputeService';

  MirrorCompileService()
    : _artifactSigner = ArtifactSigner(
        baseUrl:
            Platform.environment['ARTIFACT_BASE_URL'] ??
            'https://mirror-compute.fly.dev/artifacts',
        secret: Platform.environment['SIGNED_URL_SECRET'] ?? 'dev-secret',
      ) {
    $addMethod(ServiceMethod<List<int>, List<int>>(
      'Compile',
      compile,
      false,
      false,
      (List<int> value) => value,
      (List<int> value) => value,
    ));
  }

  final ArtifactSigner _artifactSigner;

  Future<List<int>> compile(ServiceCall call, List<int> requestBytes) async {
    final requestRaw = utf8.decode(requestBytes);
    final request = CompileRequestPayload.fromJson(_tryParseJson(requestRaw));
    final runner = CompileRunner(workspaceRoot: _workspaceRoot());

    final compileResult = await runner.run(request);
    final artifactPath = compileResult.artifactPath;

    final signedUrl = artifactPath == null
        ? null
        : _artifactSigner.sign(
            artifactPath,
            validFor: const Duration(minutes: 30),
          );

    final response = CompileResponsePayload(
      success: compileResult.success,
      output: signedUrl,
      errors: compileResult.errors,
      warnings: compileResult.warnings,
      logs: compileResult.logs,
      signedUrl: signedUrl,
      artifactPath: artifactPath,
    );

    return utf8.encode(jsonEncode(response.toJson()));
  }

  static String _workspaceRoot() {
    return Platform.environment['MIRROR_WORKSPACE_ROOT'] ?? '/tmp/mirror-workspaces';
  }

  Map<String, dynamic> _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'raw': value};
    } catch (_) {
      return <String, dynamic>{'raw': value};
    }
  }
}

class CompileRequestPayload {
  const CompileRequestPayload({
    required this.prompt,
    required this.projectId,
    required this.taskId,
    required this.mode,
    required this.files,
    required this.metadata,
  });

  final String prompt;
  final String projectId;
  final String taskId;
  final String mode;
  final Map<String, String> files;
  final Map<String, dynamic> metadata;

  factory CompileRequestPayload.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final metadataRaw = json['metadata'];

    return CompileRequestPayload(
      prompt: (json['prompt'] ?? '').toString(),
      projectId: (json['projectId'] ?? json['project_id'] ?? '').toString(),
      taskId: (json['taskId'] ?? json['task_id'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      files: filesRaw is Map
          ? filesRaw.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
      metadata: metadataRaw is Map
          ? metadataRaw.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{},
    );
  }
}

class CompileResponsePayload {
  const CompileResponsePayload({
    required this.success,
    required this.output,
    required this.errors,
    required this.warnings,
    required this.logs,
    required this.signedUrl,
    required this.artifactPath,
  });

  final bool success;
  final String? output;
  final List<String> errors;
  final List<String> warnings;
  final List<String> logs;
  final String? signedUrl;
  final String? artifactPath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'output': output,
      'errors': errors,
      'warnings': warnings,
      'logs': logs,
      'signedUrl': signedUrl,
      'artifactPath': artifactPath,
    };
  }
}

class CompileExecutionResult {
  const CompileExecutionResult({
    required this.success,
    required this.logs,
    required this.errors,
    required this.warnings,
    required this.artifactPath,
  });

  final bool success;
  final List<String> logs;
  final List<String> errors;
  final List<String> warnings;
  final String? artifactPath;
}

class CompileRunner {
  CompileRunner({required this.workspaceRoot});

  final String workspaceRoot;

  Future<CompileExecutionResult> run(CompileRequestPayload request) async {
    final logs = <String>[];
    final warnings = <String>[];
    final errors = <String>[];

    if (request.projectId.isEmpty || request.taskId.isEmpty) {
      return const CompileExecutionResult(
        success: false,
        logs: <String>[],
        errors: <String>['Missing projectId or taskId.'],
        warnings: <String>[],
        artifactPath: null,
      );
    }

    final workspace = Directory(
      '$workspaceRoot/${request.projectId}/${request.taskId}/${DateTime.now().millisecondsSinceEpoch}',
    );
    await workspace.create(recursive: true);

    await _writeFiles(workspace, request.files);

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
    if (buildTarget == 'flutter' || (buildTarget == 'auto' && await _hasFlutterEntrypoint(workspace))) {
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
      artifactPath: artifactPath,
    );
  }

  Future<void> _writeFiles(Directory workspace, Map<String, String> files) async {
    for (final entry in files.entries) {
      final normalized = entry.key.replaceAll('\\', '/');
      if (normalized.contains('..')) {
        continue;
      }
      final target = File('${workspace.path}/$normalized');
      await target.parent.create(recursive: true);
      await target.writeAsString(entry.value);
    }
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

class ArtifactSigner {
  const ArtifactSigner({required this.baseUrl, required this.secret});

  final String baseUrl;
  final String secret;

  String sign(String artifactPath, {required Duration validFor}) {
    final expiresAt = DateTime.now().toUtc().add(validFor).millisecondsSinceEpoch;
    final payload = '$artifactPath:$expiresAt';
    final signature = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
    final encodedPath = Uri.encodeComponent(artifactPath);
    return '$baseUrl/$encodedPath?exp=$expiresAt&sig=${signature.toString()}';
  }
}
