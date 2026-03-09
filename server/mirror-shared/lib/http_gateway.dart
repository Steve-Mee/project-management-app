import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';

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

    final quotaViolation = _validateQuota(bytes, requestId: requestId);
    if (quotaViolation != null) {
      _writeError(
        request.response,
        status: 400,
        error: quotaViolation,
      );
      return;
    }

    try {
      final responseBytes = await _forwardToGrpc(
        action: action,
        body: bytes,
        metadata: _extractMetadata(request),
      );
      _writeRawJson(request.response, 200, responseBytes);
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

  _GatewayStructuredError? _validateQuota(
    List<int> bytes, {
    required String requestId,
  }) {
    late final Object decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return const _GatewayStructuredError(
        code: 'bad_request',
        message: 'Request body must be valid JSON.',
        retryable: false,
        requestId: '',
      ).copyWithRequestId(requestId);
    }

    if (decoded is! Map) {
      return _GatewayStructuredError(
        code: 'bad_request',
        message: 'Request body must be a JSON object.',
        retryable: false,
        requestId: requestId,
      );
    }

    final filesRaw = decoded['files'];
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

  Future<List<int>> _forwardToGrpc({
    required String action,
    required List<int> body,
    required Map<String, String> metadata,
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('HTTP gateway is not started.');
    }

    final method = ClientMethod<List<int>, List<int>>(
      '/mirror.compute.v1.MirrorComputeService/$action',
      (List<int> request) => request,
      (List<int> response) => response,
    );

    final client = _RawUnaryGrpcClient(channel, method);
    return client.invoke(
      body,
      options: CallOptions(
        metadata: metadata,
        timeout: quota.maxExecutionWindow,
      ),
    );
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

  void _writeRawJson(HttpResponse response, int status, List<int> jsonBytes) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.add(jsonBytes);
    unawaited(response.close());
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
}

class _RawUnaryGrpcClient extends Client {
  _RawUnaryGrpcClient(
    super.channel,
    this._method,
  );

  final ClientMethod<List<int>, List<int>> _method;

  ResponseFuture<List<int>> invoke(
    List<int> requestBytes, {
    CallOptions? options,
  }) {
    return $createUnaryCall(_method, requestBytes, options: options);
  }
}

extension on _GatewayStructuredError {
  _GatewayStructuredError copyWithRequestId(String requestId) {
    return _GatewayStructuredError(
      code: code,
      message: message,
      retryable: retryable,
      requestId: requestId,
      details: details,
    );
  }
}