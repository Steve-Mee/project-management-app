import 'dart:async';
import 'dart:convert';

import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mirror_compute_backend.dart';

typedef PremiumAccessResolver = FutureOr<bool> Function(User? user);

class CloudFlyBackend implements MirrorComputeBackend {
  CloudFlyBackend({
    SupabaseClient? client,
    this.httpEndpoint = 'https://mirror-compute.fly.dev/compile',
    this.grpcHost = 'mirror-compute.fly.dev',
    this.grpcPort = 443,
    this.grpcServicePath = '/mirror.compute.v1.MirrorComputeService/Compile',
    this.useGrpc = false,
    this.timeout = const Duration(seconds: 45),
    PremiumAccessResolver? premiumResolver,
  }) : _client = client ?? Supabase.instance.client,
       _premiumResolver = premiumResolver ?? _defaultPremiumResolver;

  final SupabaseClient _client;
  final String httpEndpoint;
  final String grpcHost;
  final int grpcPort;
  final String grpcServicePath;
  final bool useGrpc;
  final Duration timeout;
  final PremiumAccessResolver _premiumResolver;

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(
      success: false,
      message: 'Generate is not implemented in CloudFlyBackend.',
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final user = _client.auth.currentUser;
    final hasPremium = await _premiumResolver(user);
    if (!hasPremium) {
      return const CompileResult(
        success: false,
        errors: <String>['Cloud compile is available for premium users only.'],
      );
    }

    final payload = <String, dynamic>{
      'prompt': prompt,
      'projectId': context.projectId,
      'taskId': context.taskId,
      'mode': mode,
      'files': context.files,
      'metadata': context.metadata,
    };

    return useGrpc
        ? _compileViaGrpc(payload)
        : _compileViaHttp(payload, _client.auth.currentSession?.accessToken);
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const ApplyResult(
      success: false,
      message: 'Apply is not implemented in CloudFlyBackend.',
    );
  }

  Future<CompileResult> _compileViaHttp(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(httpEndpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (accessToken != null && accessToken.isNotEmpty)
                'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final bodyText = response.body;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return CompileResult(
          success: false,
          errors: <String>['Fly compile HTTP ${response.statusCode}: $bodyText'],
        );
      }

      return _compileResultFromRaw(bodyText);
    } on TimeoutException {
      return const CompileResult(
        success: false,
        errors: <String>['Fly HTTP compile request timed out.'],
      );
    } catch (error) {
      return CompileResult(success: false, errors: <String>[error.toString()]);
    }
  }

  Future<CompileResult> _compileViaGrpc(Map<String, dynamic> payload) async {
    final channel = ClientChannel(
      grpcHost,
      port: grpcPort,
      options: const ChannelOptions(credentials: ChannelCredentials.secure()),
    );

    final method = ClientMethod<List<int>, List<int>>(
      grpcServicePath,
      (request) => request,
      (response) => response,
    );
    final client = _RawCloudFlyGrpcClient(channel, method);

    try {
      final requestBytes = utf8.encode(jsonEncode(payload));
      final responseBytes = await client.compile(requestBytes, timeout: timeout);
      final responseText = utf8.decode(responseBytes);
      return _compileResultFromRaw(responseText);
    } on GrpcError catch (error) {
      return CompileResult(
        success: false,
        errors: <String>[error.message ?? error.toString()],
      );
    } on TimeoutException {
      return const CompileResult(
        success: false,
        errors: <String>['Fly gRPC compile request timed out.'],
      );
    } catch (error) {
      return CompileResult(success: false, errors: <String>[error.toString()]);
    } finally {
      await channel.shutdown();
    }
  }

  CompileResult _compileResultFromRaw(String raw) {
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
  }

  static bool _defaultPremiumResolver(User? user) {
    if (user == null) {
      return false;
    }

    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata;

    final planValue =
        appMetadata['plan'] ??
        appMetadata['subscription'] ??
        userMetadata?['plan'] ??
        userMetadata?['subscription'];

    final normalized = planValue?.toString().toLowerCase().trim() ?? '';
    return normalized == 'premium' || normalized == 'pro' || normalized == 'enterprise';
  }
}

class _RawCloudFlyGrpcClient extends Client {
  _RawCloudFlyGrpcClient(super.channel, this._compileMethod);

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
