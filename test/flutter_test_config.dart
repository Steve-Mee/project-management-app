import 'dart:async';

import 'helpers/golden_test_setup.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  configureGoldenTests();
  await testMain();
}
