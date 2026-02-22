import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger instance = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void event(String name, {Map<String, Object?>? params}) {
    final payload = params ?? const {};
    if (payload.isEmpty) {
      instance.i('Event: $name');
      return;
    }

    final buffer = StringBuffer('Event: $name');
    payload.forEach((key, value) {
      buffer.write(', $key: $value');
    });
    instance.i(buffer.toString());
  }

  static Future<void> error(String message, {Object? error, StackTrace? stackTrace}) async {
    instance.e(message, error: error, stackTrace: stackTrace);
  }
}
