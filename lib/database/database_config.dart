import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseConfig {
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      // Change the default factory for desktop
      databaseFactory = databaseFactoryFfi;
      
      // Set the database path for Windows/Linux
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'databases');
      // Create the database directory if it doesn't exist
      await Directory(dbPath).create(recursive: true);
      // Set the database path
      await databaseFactory.setDatabasesPath(dbPath);
    }
  }
} 