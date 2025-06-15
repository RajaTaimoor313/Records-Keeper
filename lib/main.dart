import 'package:flutter/material.dart';
import 'package:records_keeper/home_screen.dart';
import 'database/database_config.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await DatabaseHelper.instance.deleteDatabase();
    await DatabaseConfig.initialize();
    final db = await DatabaseHelper.instance.database;
    await db.close();
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Accounts Holder',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const HomeScreen(),
    debugShowCheckedModeBanner: false,
  );
}
