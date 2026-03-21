@TestOn('vm')
library;

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('e2e_driver', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('login_then_dashboard_navigation', () async {
      await driver.waitFor(find.byValueKey('login_username'));
      await driver.tap(find.byValueKey('login_username'));
      await driver.enterText('test');

      await driver.tap(find.byValueKey('login_password'));
      await driver.enterText('password');

      await driver.tap(find.byValueKey('login_button'));
      await driver.waitFor(find.byType('DashboardScreen'));
    });
  });
}
