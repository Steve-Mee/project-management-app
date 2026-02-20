import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('E2E', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Login and navigate to dashboard', () async {
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
