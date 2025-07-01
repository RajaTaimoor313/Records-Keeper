import 'package:flutter/material.dart';
import 'package:records_keeper/database_config.dart';
import 'package:records_keeper/home_screen.dart';
import 'package:records_keeper/tabs/history/load_form_history_screen.dart';
import 'package:records_keeper/tabs/history/pick_list_history_screen.dart';
import 'package:records_keeper/tabs/sales/pick_list_detail_screen.dart';
import 'package:records_keeper/tabs/sales/load_form_detail_screen.dart';
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
    routes: {
      '/pick-list-history': (context) => const PickListHistoryScreen(),
      '/pick-list-detail': (context) => const PickListDetailScreen(),
      '/load-form-history': (context) => const LoadFormHistoryScreen(),
      '/load-form-detail': (context) => const LoadFormDetailScreen(),
    },
    debugShowCheckedModeBanner: false,
  );
}
