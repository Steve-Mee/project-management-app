import 'package:pma_core/repository/hive_initializer.dart' as core_hive;

class HiveInitializer {
  static Future<void> initialize() async {
    await core_hive.HiveInitializer.initialize();
  }
}
