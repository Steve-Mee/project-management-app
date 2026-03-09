import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';

class MirrorHttpGateway {
  MirrorHttpGateway({
    required this.bindAddress,
    required this.httpPort,
    required this.grpcHost,
    required this.grpcPort,
  });

  final String bindAddress;
  final int httpPort;
  final String grpcHost;
  final int grpcPort;

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
    if (request.method == 'OPTIONS') {
      _writeJson(request.response, 200, <String, dynamic>{'ok': true});
      return;
    }

    if (request.method != 'POST') {
      _writeJson(
        request.response,
        405,
        <String, dynamic>{'success': false, 'error': 'method_not_allowed'},
      );
      return;
    }

    final action = _resolveAction(request.uri.path);
    if (action == null) {
      _writeJson(
        request.response,
        404,
        <String, dynamic>{'success': false, 'error': 'not_found'},
      );
      return;
    }

    final bytes = await _readBodyBytes(request);

    try {
      final responseBytes = await _forwardToGrpc(
        action: action,
        body: bytes,
        metadata: _extractMetadata(request),
      );
      _writeRawJson(request.response, 200, responseBytes);
    } on GrpcError catch (error) {
      _writeJson(
        request.response,
        _grpcToHttpStatus(error),
        <String, dynamic>{
          'success': false,
          'error': error.message ?? error.toString(),
        },
      );
    } catch (error) {
      _writeJson(
        request.response,
        500,
        <String, dynamic>{'success': false, 'error': error.toString()},
      );
    }
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
      options: CallOptions(metadata: metadata),
    );
  }

  Future<List<int>> _readBodyBytes(HttpRequest request) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
    }
    return bytes;
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
