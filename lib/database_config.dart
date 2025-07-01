import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:records_keeper/database_helper.dart';

class DatabaseConfig {
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize the database helper
      await DatabaseHelper.instance.initialize();

      // Set the database path for Windows/Linux
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'databases');

      // Create the database directory if it doesn't exist
      await Directory(dbPath).create(recursive: true);

      // Set the database path
      await DatabaseHelper.instance.database;
    }
  }
}
