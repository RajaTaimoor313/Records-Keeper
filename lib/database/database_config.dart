import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseConfig {
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      // Change the default factory for desktop
      databaseFactory = databaseFactoryFfi;
    }
  }
} 