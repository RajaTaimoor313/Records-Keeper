import 'package:flutter/material.dart';
import 'package:records_keeper/home_screen.dart';
import 'database/database_config.dart';
import 'database_helper.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Delete existing database to ensure schema is up to date
    await DatabaseHelper.instance.deleteDatabase();
    
    // Initialize database for desktop platforms
    await DatabaseConfig.initialize();
    
    // Ensure database is created with latest schema
    final db = await DatabaseHelper.instance.database;
    await db.close();
  } catch (e) {
    // Continue anyway as the app can still function with a fresh database
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accounts Holder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
