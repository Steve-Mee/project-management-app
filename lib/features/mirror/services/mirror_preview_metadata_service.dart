import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/project_context.dart';

/// Builds and normalizes preview/apply metadata for Mirror orchestration.
class MirrorPreviewMetadataService {
  const MirrorPreviewMetadataService();

  ProjectContextMetadata buildApplyMetadata({
    required ProjectContextMetadata metadata,
    required String? previewServerVersionToken,
    required String previewCompileFingerprint,
    required String previewCompileOutput,
  }) {
    final previewCompileOutputSha256 =
        sha256.convert(utf8.encode(previewCompileOutput)).toString();

    if (previewServerVersionToken == null) {
      return metadata.copyWith(
        previewCompileFingerprint: previewCompileFingerprint,
        previewCompileOutputSha256: previewCompileOutputSha256,
        previewReuseRequested: false,
        previewReuseStrategy: ProjectContextPreviewReuseStrategy.none,
      );
    }

    final reusePayload = _buildPreviewReusePayload(
      serverVersionToken: previewServerVersionToken,
      compileFingerprint: previewCompileFingerprint,
      compileOutput: previewCompileOutput,
    );

    return metadata.copyWith(
      previewCompileFingerprint: previewCompileFingerprint,
      previewCompileOutputSha256: previewCompileOutputSha256,
      previewReuseRequested: true,
      previewReuseStrategy:
          ProjectContextPreviewReuseStrategy.serverVersionToken,
      previewServerVersionToken: previewServerVersionToken,
      previewArtifactPath: previewServerVersionToken,
      previewReusePayload: reusePayload,
    );
  }

  String? normalizeServerVersionToken(String? rawToken) {
    final token = rawToken?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  String computeContextFingerprint(Map<String, String> files) {
    final entries = files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer
        ..write(entry.key)
        ..write('::')
        ..write(entry.value)
        ..write('\n');
    }

    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  ProjectContextPreviewReusePayload _buildPreviewReusePayload({
    required String serverVersionToken,
    required String compileFingerprint,
    required String compileOutput,
  }) {
    const maxInlinePreviewChars = 64 * 1024;
    final normalizedOutput = compileOutput.trim();
    final inlineOutput = normalizedOutput.length <= maxInlinePreviewChars
        ? normalizedOutput
        : normalizedOutput.substring(0, maxInlinePreviewChars);

    return ProjectContextPreviewReusePayload(
      token: serverVersionToken,
      fingerprint: compileFingerprint,
      outputSha256: sha256.convert(utf8.encode(normalizedOutput)).toString(),
      inlineOutput: inlineOutput,
      inlineOutputTruncated: normalizedOutput.length > maxInlinePreviewChars,
    );
  }
}
