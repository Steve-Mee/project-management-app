import 'dart:async';
import 'dart:convert';

import 'package:grpc/grpc.dart';

import 'mirror_compute_backend.dart';

class PrivateGrpcBackend implements MirrorComputeBackend {
  PrivateGrpcBackend({
    this.host = '127.0.0.1',
    this.port = 50051,
    this.timeout = const Duration(seconds: 30),
    this.servicePath = '/mirror.compute.v1.MirrorComputeService/Compile',
  });

  final String host;
  final int port;
  final Duration timeout;
  final String servicePath;

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(
      success: false,
      message: 'Generate is not implemented in PrivateGrpcBackend.',
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );

    final method = ClientMethod<List<int>, List<int>>(
      servicePath,
      (request) => request,
      (response) => response,
    );
    final client = _RawMirrorGrpcClient(channel, method);

    try {
      final requestPayload = <String, dynamic>{
        'prompt': prompt,
        'projectId': context.projectId,
        'taskId': context.taskId,
        'mode': mode,
        'files': context.files,
        'metadata': context.metadata,
      };

      final requestBytes = utf8.encode(jsonEncode(requestPayload));

      final responseBytes = await client.compile(
        requestBytes,
        timeout: timeout,
      );
      final raw = utf8.decode(responseBytes);

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        decoded = <String, dynamic>{'success': true, 'output': raw};
      }

      if (decoded is Map<String, dynamic>) {
        final errorsRaw = decoded['errors'];
        final warningsRaw = decoded['warnings'];

        return CompileResult(
          success: (decoded['success'] as bool?) ?? true,
          output: decoded['output']?.toString(),
          errors: errorsRaw is List
              ? errorsRaw.map((e) => e.toString()).toList()
              : const <String>[],
          warnings: warningsRaw is List
              ? warningsRaw.map((e) => e.toString()).toList()
              : const <String>[],
        );
      }

      return CompileResult(success: true, output: raw);
    } on GrpcError catch (error) {
      return CompileResult(
        success: false,
        errors: <String>[error.message ?? error.toString()],
      );
    } on TimeoutException {
      return const CompileResult(
        success: false,
        errors: <String>['gRPC compile request timed out.'],
      );
    } catch (error) {
      return CompileResult(
        success: false,
        errors: <String>[error.toString()],
      );
    } finally {
      await channel.shutdown();
    }
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const ApplyResult(
      success: false,
      message: 'Apply is not implemented in PrivateGrpcBackend.',
    );
  }
}

class _RawMirrorGrpcClient extends Client {
  _RawMirrorGrpcClient(super.channel, this._compileMethod);

  final ClientMethod<List<int>, List<int>> _compileMethod;

  ResponseFuture<List<int>> compile(
    List<int> requestBytes, {
    Duration? timeout,
  }) {
    return $createUnaryCall(
      _compileMethod,
      requestBytes,
      options: CallOptions(timeout: timeout),
    );
  }
}
