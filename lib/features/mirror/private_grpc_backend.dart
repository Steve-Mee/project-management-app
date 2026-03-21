// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'grpc_generated/mirror.pbgrpc.dart';
import 'mirror_signed_inputs_backend.dart';
import 'services/mirror_backend_workflows.dart';

const bool _isProductionGrpcRuntime =
    bool.fromEnvironment('dart.vm.product', defaultValue: false);
const ChannelCredentials _insecureChannelCredentials =
    ChannelCredentials.insecure();
const MirrorBackendWorkflows _mirrorWorkflows = MirrorBackendWorkflows();

class PrivateGrpcBackend implements MirrorComputeBackend {
  PrivateGrpcBackend({
    required this.client,
    this.host = '127.0.0.1',
    this.port = 50051,
    this.timeout = const Duration(seconds: 30),
    this.credentials = const ChannelCredentials.insecure(),
  }) {
    _enforceProductionTransportSecurity();
  }

  final SupabaseClient client;
  final String host;
  final int port;
  final Duration timeout;
  final ChannelCredentials credentials;

  void _enforceProductionTransportSecurity() {
    // Production guard: fail closed when insecure transport is configured in
    // release/runtime-product environments.
    if (!kReleaseMode && !_isProductionGrpcRuntime) {
      return;
    }

    if (identical(credentials, _insecureChannelCredentials)) {
      throw StateError(
        'Insecure gRPC transport is blocked in production runtime. Configure TLS credentials for PrivateGrpcBackend.',
      );
    }
  }

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    final compileResult = await compile(
      prompt: prompt,
      context: context,
      mode: mode,
    );

    if (!compileResult.success) {
      return GenerateResult(
        success: false,
        message: compileResult.errors.join(' | '),
        diagnostics: compileResult.errors,
      );
    }

    return GenerateResult(
      success: true,
      code: compileResult.output,
      diagnostics: compileResult.warnings,
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    // Use a short-lived channel per RPC and always close it to prevent
    // file-descriptor/socket leakage in long-running production sessions.
    final channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(credentials: credentials),
    );

    final client = MirrorComputeServiceClient(channel);

    try {
      final response = await client.compile(
        CompileRequest(
          prompt: prompt,
          projectId: context.projectId,
          taskId: context.taskId,
          mode: mode,
          files: context.files.entries,
          metadataJson: jsonEncode(context.metadata.toJson()),
        ),
        options: CallOptions(timeout: timeout),
      );
      return CompileResult(
        success: response.success,
        output: response.output.trim().isEmpty ? null : response.output,
        serverVersionToken:
            response.artifactPath.trim().isEmpty ? null : response.artifactPath,
        errors: response.errors.toList(),
        warnings: response.warnings.toList(),
      );
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
    String? compileFingerprint,
  }) async {
    return _mirrorWorkflows.secureApply(
      client: client,
      prompt: prompt,
      context: context,
      mode: mode,
      onApply: (ApplySecurityArtifacts artifacts) async {
        final compileResult = await compile(
          prompt: prompt,
          context: context,
          mode: mode,
        );

        if (!compileResult.success || compileResult.output == null) {
          return ApplyResult(
            success: false,
            message: compileResult.errors.isEmpty
                ? 'Apply failed: compile output is empty.'
                : compileResult.errors.join(' | '),
          );
        }

        final output = compileResult.output!;
        if (compileFingerprint != null && compileFingerprint.isNotEmpty) {
          final actualFingerprint = computeCompileResultFingerprint(
            prompt: prompt,
            context: context,
            mode: mode,
            output: output,
          );
          if (actualFingerprint != compileFingerprint) {
            return const ApplyResult(
              success: false,
              message:
                  'Apply blocked: preview fingerprint mismatch. Re-run preview before applying.',
            );
          }
        }

        final applyRpcResult = await _applyRpc(
          prompt: prompt,
          context: context,
          mode: mode,
        );
        if (!applyRpcResult.success || applyRpcResult.output == null) {
          return ApplyResult(
            success: false,
            message: applyRpcResult.errors.isEmpty
                ? 'Apply failed: compile output is empty.'
                : applyRpcResult.errors.join(' | '),
          );
        }

        final patches = _mirrorWorkflows.buildPatchesFromApplyPayload(
          context: context,
          output: applyRpcResult.output!,
        );

        if (patches.isEmpty) {
          return const ApplyResult(
            success: false,
            message: 'Apply failed: no patchable changes returned.',
          );
        }

        final updatedFiles = _mirrorWorkflows.applyPatchesToFiles(
          files: context.files,
          patches: patches,
        );

        await _mirrorWorkflows.persistApplyToHive(
          context: context,
          mode: mode,
          prompt: prompt,
          patches: patches,
          artifacts: artifacts,
          backend: 'private_grpc',
          updatedFiles: updatedFiles,
        );

        return ApplyResult(
          success: true,
          appliedFiles: patches.map((patch) => patch.path).toSet().toList(),
          message:
              'Applied ${patches.length} patch(es) with backup ${artifacts.backupId}.',
        );
      },
    );
  }

  Future<_ApplyRpcResult> _applyRpc({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    // Use a short-lived channel per RPC and always close it to prevent
    // file-descriptor/socket leakage in long-running production sessions.
    final channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(credentials: credentials),
    );
    final client = MirrorComputeServiceClient(channel);

    try {
      final response = await client.apply(
        ApplyRequest(
          prompt: prompt,
          projectId: context.projectId,
          taskId: context.taskId,
          mode: mode,
          files: context.files.entries,
          metadataJson: jsonEncode(context.metadata.toJson()),
        ),
        options: CallOptions(timeout: timeout),
      );
      return _ApplyRpcResult(
        success: response.success,
        output: response.output.trim().isEmpty ? null : response.output,
        errors: response.errors.toList(),
      );
    } on GrpcError catch (error) {
      return _ApplyRpcResult(
        success: false,
        errors: <String>[error.message ?? error.toString()],
      );
    } on TimeoutException {
      return const _ApplyRpcResult(
        success: false,
        errors: <String>['gRPC apply request timed out.'],
      );
    } catch (error) {
      return _ApplyRpcResult(
        success: false,
        errors: <String>[error.toString()],
      );
    } finally {
      await channel.shutdown();
    }
  }
}

class _ApplyRpcResult {
  const _ApplyRpcResult({
    required this.success,
    required this.errors,
    this.output,
  });

  final bool success;
  final String? output;
  final List<String> errors;
}
