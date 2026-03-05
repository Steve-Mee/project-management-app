import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const double _defaultGoldenTolerance = 0.0;

/// Configures global golden test behavior.
///
/// Supported environment variables:
/// - GOLDEN_TOLERANCE: decimal threshold (e.g. 0.01 for 1% pixel diff)
/// - UPDATE_GOLDENS / GOLDEN_UPDATE: true|1|yes to force updates in tests
void configureGoldenTests() {
  final bool shouldUpdateGoldens = _readBoolEnv('UPDATE_GOLDENS') ||
      _readBoolEnv('GOLDEN_UPDATE');
  if (shouldUpdateGoldens) {
    autoUpdateGoldenFiles = true;
  }

  final double tolerance = _readDoubleEnv(
    'GOLDEN_TOLERANCE',
    fallback: _defaultGoldenTolerance,
  );

  final GoldenFileComparator currentComparator = goldenFileComparator;
  if (currentComparator is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenFileComparator(
      basedir: currentComparator.basedir,
      tolerance: tolerance,
    );
  }
}

class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator({
    required Uri basedir,
    required this.tolerance,
  }) : assert(tolerance >= 0 && tolerance <= 1),
       super(basedir);

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final bool passed = await super.compare(imageBytes, golden);
    if (passed || tolerance <= 0) {
      return passed;
    }

    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    try {
      return result.diffPercent <= tolerance;
    } finally {
      result.dispose();
    }
  }
}

bool _readBoolEnv(String key) {
  final String? raw = Platform.environment[key];
  if (raw == null) {
    return false;
  }

  switch (raw.trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'on':
      return true;
    default:
      return false;
  }
}

double _readDoubleEnv(String key, {required double fallback}) {
  final String? raw = Platform.environment[key];
  if (raw == null) {
    return fallback;
  }

  return double.tryParse(raw.trim()) ?? fallback;
}
