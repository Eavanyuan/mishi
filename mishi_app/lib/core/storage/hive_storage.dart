import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static Future<void> init() async {
    await Hive.initFlutter();
    // 注册适配器
    // Hive.registerAdapter(YourAdapter());
  }

  static Future<Box<T>> openBox<T>(String name) async {
    return await Hive.openBox<T>(name);
  }

  static Future<void> closeBox<T>(Box<T> box) async {
    await box.close();
  }
}
