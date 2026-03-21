// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import '../mirror_signed_inputs_backend.dart';
import 'mirror_outbox_replay_service.dart';

/// Interactive execution path for user-triggered run flows.
class MirrorInteractiveExecutionPath {
  const MirrorInteractiveExecutionPath({required MirrorComputeBackend backend})
      : _backend = backend;

  final MirrorComputeBackend _backend;

  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    return _backend.generate(
      prompt: prompt,
      context: context,
      mode: mode,
    );
  }

  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    return _backend.compile(
      prompt: prompt,
      context: context,
      mode: mode,
    );
  }

  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) {
    return _backend.apply(
      prompt: prompt,
      context: context,
      mode: mode,
      compileFingerprint: compileFingerprint,
    );
  }
}

/// Replay execution path for deferred outbox operations.
class MirrorReplayExecutionPath {
  const MirrorReplayExecutionPath({required MirrorComputeBackend backend})
      : _backend = backend;

  final MirrorComputeBackend _backend;

  Future<MirrorOutboxOperationResult> execute(MirrorOutboxEntry entry) async {
    switch (entry.operation) {
      case 'generate':
        final result = await _backend.generate(
          prompt: entry.prompt,
          context: entry.context,
          mode: entry.mode,
        );
        return MirrorOutboxOperationResult(
          success: result.success,
          message: result.message ?? result.diagnostics.join(' | '),
        );
      case 'compile':
        final result = await _backend.compile(
          prompt: entry.prompt,
          context: entry.context,
          mode: entry.mode,
        );
        return MirrorOutboxOperationResult(
          success: result.success,
          message: result.errors.join(' | '),
        );
      case 'apply':
        final compileFingerprint = entry.context.metadata.compileFingerprint;
        final result = await _backend.apply(
          prompt: entry.prompt,
          context: entry.context,
          mode: entry.mode,
          compileFingerprint: compileFingerprint,
        );
        return MirrorOutboxOperationResult(
          success: result.success,
          message: result.message,
        );
      default:
        return MirrorOutboxOperationResult(
          success: false,
          message: 'Unknown outbox operation: ${entry.operation}',
        );
    }
  }
}
