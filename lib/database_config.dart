import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:records_keeper/database_helper.dart';

class DatabaseConfig {
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      await DatabaseHelper.instance.initialize();

      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'databases');

      await Directory(dbPath).create(recursive: true);

      await DatabaseHelper.instance.database;
    }
  }
}
