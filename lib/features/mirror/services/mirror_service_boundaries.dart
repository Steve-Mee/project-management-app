import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../mirror_signed_inputs_backend.dart';

/// PR1 boundary contract: interactive editor-triggered run flow.
///
/// This contract keeps UI entrypoints decoupled from orchestration internals.
abstract class MirrorInteractiveRunCoordinator {
  Future<void> runCurrentFileInTerminal({
    required BuildContext context,
    required WidgetRef ref,
    required String projectId,
    required String taskId,
    required String selectedMode,
    required String sessionKey,
    required AppLocalizations l10n,
    required bool Function() isMounted,
    required void Function(String line) appendTerminalLine,
  });
}

/// PR1 boundary contract: backend orchestration engine.
///
/// This contract isolates execution concerns (generate/compile/apply/replay)
/// from editor-specific UI behavior.
abstract class MirrorExecutionOrchestrator {
  Future<GenerateResult> generate({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  Future<CompileResult> compile({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  Future<ApplyResult> apply({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  });
}
