class MirrorStructuredError {
  const MirrorStructuredError({
    required this.errorFamily,
    required this.retryable,
    this.message,
  });

  final String errorFamily;
  final bool retryable;
  final String? message;
}
