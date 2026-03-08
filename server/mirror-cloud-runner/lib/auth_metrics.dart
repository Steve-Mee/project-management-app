class RunnerMetrics {
  int _authDeniedCount = 0;
  int _compileCount = 0;
  int _compileFailureCount = 0;
  int _compileTotalLatencyMs = 0;
  int _compileMaxLatencyMs = 0;
  final Map<String, int> _authDeniedByReason = <String, int>{};

  void recordAuthDenied(String reason) {
    _authDeniedCount += 1;
    _authDeniedByReason.update(reason, (value) => value + 1, ifAbsent: () => 1);
  }

  void recordCompile({required Duration latency, required bool success}) {
    _compileCount += 1;
    if (!success) {
      _compileFailureCount += 1;
    }

    final latencyMs = latency.inMilliseconds;
    _compileTotalLatencyMs += latencyMs;
    if (latencyMs > _compileMaxLatencyMs) {
      _compileMaxLatencyMs = latencyMs;
    }
  }

  Map<String, Object> snapshot() {
    final avgLatencyMs = _compileCount == 0
        ? 0
        : (_compileTotalLatencyMs ~/ _compileCount);
    return <String, Object>{
      'authDeniedCount': _authDeniedCount,
      'authDeniedByReason': Map<String, int>.from(_authDeniedByReason),
      'compileCount': _compileCount,
      'compileFailureCount': _compileFailureCount,
      'compileAvgLatencyMs': avgLatencyMs,
      'compileMaxLatencyMs': _compileMaxLatencyMs,
    };
  }
}
