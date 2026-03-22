import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/features/mirror/grpc_generated/mirror.pbgrpc.dart';
import 'request_validator.dart';

class MirrorGatewayQuotaConfig {
  const MirrorGatewayQuotaConfig({
    this.maxFiles = 500,
    this.maxWorkspaceBytes = 50 * 1024 * 1024,
    this.maxExecutionWindow = const Duration(seconds: 300),
  });

  final int maxFiles;
  final int maxWorkspaceBytes;
  final Duration maxExecutionWindow;
}

class _GatewayStructuredError {
  const _GatewayStructuredError({
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

class MirrorHttpGateway {
  MirrorHttpGateway({
    required this.bindAddress,
    required this.httpPort,
    required this.grpcHost,
    required this.grpcPort,
    this.quota = const MirrorGatewayQuotaConfig(),
  });

  final String bindAddress;
  final int httpPort;
  final String grpcHost;
  final int grpcPort;
  final MirrorGatewayQuotaConfig quota;

  HttpServer? _server;
  ClientChannel? _channel;

  Future<void> start() async {
    if (_server != null) {
      return;
    }

    _channel = ClientChannel(
      grpcHost,
      port: grpcPort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );

    _server = await HttpServer.bind(bindAddress, httpPort);
    unawaited(_serve(_server!));
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await channel.shutdown();
    }
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      unawaited(_handle(request));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final requestId = _resolveRequestId(request);

    if (request.method == 'OPTIONS') {
      _writeJson(request.response, 200, <String, dynamic>{'ok': true});
      return;
    }

    if (request.method != 'POST') {
      _writeError(
        request.response,
        status: 405,
        error: _GatewayStructuredError(
          code: 'method_not_allowed',
          message: 'Only POST is supported.',
          retryable: false,
          requestId: requestId,
        ),
      );
      return;
    }

    final action = _resolveAction(request.uri.path);
    if (action == null) {
      _writeError(
        request.response,
        status: 404,
        error: _GatewayStructuredError(
          code: 'bad_request',
          message: 'Unsupported action path. Expected /compile or /apply.',
          retryable: false,
          requestId: requestId,
        ),
      );
      return;
    }

    final bytes = await _readBodyBytes(request);
    if (bytes.length > quota.maxWorkspaceBytes) {
      _writeError(
        request.response,
        status: 413,
        error: _GatewayStructuredError(
          code: 'payload_too_large',
          message:
              'Request payload exceeds ${quota.maxWorkspaceBytes} bytes limit.',
          retryable: false,
          requestId: requestId,
          details: <String, Object>{
            'maxWorkspaceBytes': quota.maxWorkspaceBytes,
            'receivedBytes': bytes.length,
          },
        ),
      );
      return;
    }

    late final Map<String, dynamic> requestBody;
    try {
      requestBody = _decodeJsonObject(bytes);
    } on FormatException {
      _writeError(
        request.response,
        status: 400,
        error: _GatewayStructuredError(
          code: 'bad_request',
          message: 'Request body must be a JSON object.',
          retryable: false,
          requestId: requestId,
        ),
      );
      return;
    }

    final schemaViolation = _validateRequestSchema(
      requestBody,
      action: action,
      requestId: requestId,
    );
    if (schemaViolation != null) {
      _writeError(
        request.response,
        status: 400,
        error: schemaViolation,
      );
      return;
    }

    final quotaViolation = _validateQuota(requestBody, requestId: requestId);
    if (quotaViolation != null) {
      _writeError(
        request.response,
        status: 400,
        error: quotaViolation,
      );
      return;
    }

    try {
      final responseJson = await _forwardToGrpc(
        action: action,
        body: requestBody,
        metadata: _extractMetadata(request),
      );
      _writeJson(request.response, 200, responseJson);
    } on GrpcError catch (error) {
      final status = _grpcToHttpStatus(error);
      final isTimeout = error.code == StatusCode.deadlineExceeded;
      _writeError(
        request.response,
        status: status,
        error: _GatewayStructuredError(
          code: isTimeout ? 'timeout' : 'upstream_error',
          message: error.message ?? error.toString(),
          retryable: isTimeout || status >= 500,
          requestId: requestId,
          details: <String, Object>{
            'grpcCode': error.code,
          },
        ),
      );
    } catch (error) {
      _writeError(
        request.response,
        status: 500,
        error: _GatewayStructuredError(
          code: 'internal_error',
          message: 'Internal server error',
          retryable: false,
          requestId: requestId,
          details: error.toString(),
        ),
      );
    }
  }

  _GatewayStructuredError? _validateRequestSchema(
    Map<String, dynamic> body, {
    required String action,
    required String requestId,
  }) {
    final errors = action == 'Apply'
        ? MirrorRequestValidator.validateApplyBody(body)
        : MirrorRequestValidator.validateCompileBody(body);

    if (errors.isEmpty) {
      return null;
    }

    return _GatewayStructuredError(
      code: 'bad_request',
      message: 'Request schema validation failed.',
      retryable: false,
      requestId: requestId,
      details: <String, Object>{
        'errors': errors,
      },
    );
  }

  _GatewayStructuredError? _validateQuota(
    Map<String, dynamic> body, {
    required String requestId,
  }) {
    final filesRaw = body['files'];
    if (filesRaw is! Map) {
      return _GatewayStructuredError(
        code: 'bad_request',
        message: 'Request must include a files map.',
        retryable: false,
        requestId: requestId,
      );
    }

    final fileCount = filesRaw.length;
    if (fileCount > quota.maxFiles) {
      return _GatewayStructuredError(
        code: 'bad_request',
        message: 'File count exceeds ${quota.maxFiles} limit.',
        retryable: false,
        requestId: requestId,
        details: <String, Object>{
          'maxFiles': quota.maxFiles,
          'receivedFiles': fileCount,
        },
      );
    }

    var workspaceBytes = 0;
    for (final entry in filesRaw.entries) {
      final pathBytes = utf8.encode(entry.key.toString()).length;
      final contentBytes = utf8.encode((entry.value ?? '').toString()).length;
      workspaceBytes += pathBytes + contentBytes;
      if (workspaceBytes > quota.maxWorkspaceBytes) {
        return _GatewayStructuredError(
          code: 'payload_too_large',
          message:
              'Workspace size exceeds ${quota.maxWorkspaceBytes} bytes limit.',
          retryable: false,
          requestId: requestId,
          details: <String, Object>{
            'maxWorkspaceBytes': quota.maxWorkspaceBytes,
            'receivedWorkspaceBytes': workspaceBytes,
          },
        );
      }
    }

    return null;
  }

  String? _resolveAction(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('/compile')) {
      return 'Compile';
    }
    if (normalized.endsWith('/apply')) {
      return 'Apply';
    }
    return null;
  }

  Map<String, String> _extractMetadata(HttpRequest request) {
    final metadata = <String, String>{};
    request.headers.forEach((name, values) {
      if (values.isEmpty) {
        return;
      }
      final key = name.toLowerCase();
      metadata[key] = values.first;
    });
    return metadata;
  }

  Future<Map<String, dynamic>> _forwardToGrpc({
    required String action,
    required Map<String, dynamic> body,
    required Map<String, String> metadata,
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('HTTP gateway is not started.');
    }

    final client = MirrorComputeServiceClient(channel);
    final options = CallOptions(
      metadata: metadata,
      timeout: quota.maxExecutionWindow,
    );

    switch (action) {
      case 'Compile':
        final response = await client.compile(
          _buildCompileRequest(body),
          options: options,
        );
        return _compileResponseToJson(response);
      case 'Apply':
        final response = await client.apply(
          _buildApplyRequest(body),
          options: options,
        );
        return _applyResponseToJson(response);
      default:
        throw StateError('Unsupported gRPC action: $action');
    }
  }

  Future<List<int>> _readBodyBytes(HttpRequest request) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in request) {
      bytes.add(chunk);
      if (bytes.length > quota.maxWorkspaceBytes) {
        break;
      }
    }
    return bytes.toBytes();
  }

  int _grpcToHttpStatus(GrpcError error) {
    switch (error.code) {
      case StatusCode.unauthenticated:
      case StatusCode.permissionDenied:
        return 401;
      case StatusCode.invalidArgument:
        return 400;
      case StatusCode.deadlineExceeded:
        return 504;
      default:
        return 502;
    }
  }

  void _writeError(
    HttpResponse response, {
    required int status,
    required _GatewayStructuredError error,
  }) {
    _writeJson(
      response,
      status,
      <String, dynamic>{
        'success': false,
        'error': error.toJson(),
      },
    );
  }

  String _resolveRequestId(HttpRequest request) {
    final direct = request.headers.value('x-request-id');
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    return 'gateway-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  void _writeJson(HttpResponse response, int status, Map<String, dynamic> body) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    unawaited(response.close());
  }

  Map<String, dynamic> _decodeJsonObject(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Request body must be a JSON object.');
    }
    return decoded;
  }

  CompileRequest _buildCompileRequest(Map<String, dynamic> body) {
    return CompileRequest(
      prompt: (body['prompt'] ?? '').toString(),
      projectId: (body['projectId'] ?? body['project_id'] ?? '').toString(),
      taskId: (body['taskId'] ?? body['task_id'] ?? '').toString(),
      mode: (body['mode'] ?? '').toString(),
      files: _filesFromBody(body).entries,
      metadataJson: _metadataJson(body),
    );
  }

  ApplyRequest _buildApplyRequest(Map<String, dynamic> body) {
    return ApplyRequest(
      prompt: (body['prompt'] ?? '').toString(),
      projectId: (body['projectId'] ?? body['project_id'] ?? '').toString(),
      taskId: (body['taskId'] ?? body['task_id'] ?? '').toString(),
      mode: (body['mode'] ?? '').toString(),
      files: _filesFromBody(body).entries,
      metadataJson: _metadataJson(body),
    );
  }

  Map<String, String> _filesFromBody(Map<String, dynamic> body) {
    final filesRaw = body['files'];
    if (filesRaw is! Map) {
      return const <String, String>{};
    }
    return filesRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  String _metadataJson(Map<String, dynamic> body) {
    final metadataRaw = body['metadata'];
    if (metadataRaw is! Map) {
      return '{}';
    }
    return jsonEncode(
      metadataRaw.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  Map<String, dynamic> _compileResponseToJson(CompileResponse response) {
    return <String, dynamic>{
      'success': response.success,
      'output': _decodeJsonField(response.output),
      'errors': response.errors,
      'warnings': response.warnings,
      'logs': response.logs,
      'signedUrl': response.signedUrl.isEmpty ? null : response.signedUrl,
      'artifactPath':
          response.artifactPath.isEmpty ? null : response.artifactPath,
      if (response.errorJson.isNotEmpty)
        'error': _decodeJsonField(response.errorJson),
    };
  }

  Map<String, dynamic> _applyResponseToJson(ApplyResponse response) {
    return <String, dynamic>{
      'success': response.success,
      'output': _decodeJsonField(response.output),
      'errors': response.errors,
      'warnings': response.warnings,
      'logs': response.logs,
      'signedUrl': response.signedUrl.isEmpty ? null : response.signedUrl,
      'artifactPath':
          response.artifactPath.isEmpty ? null : response.artifactPath,
      if (response.errorJson.isNotEmpty)
        'error': _decodeJsonField(response.errorJson),
    };
  }

  Object? _decodeJsonField(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }
}