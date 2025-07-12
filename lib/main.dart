import 'package:flutter/material.dart';
import 'package:haider_traders/database_config.dart';
import 'package:haider_traders/splash_screen.dart';
import 'package:haider_traders/tabs/history/load_form_history_screen.dart';
import 'package:haider_traders/tabs/history/pick_list_history_screen.dart';
import 'package:haider_traders/tabs/history/sales_history_screen.dart';
import 'package:haider_traders/tabs/history/expenditure_history_screen.dart';
import 'package:haider_traders/tabs/history/income_history_screen.dart';
import 'package:haider_traders/tabs/sales/pick_list_detail_screen.dart';
import 'package:haider_traders/tabs/sales/load_form_detail_screen.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initialize();
  try {
    await DatabaseConfig.initialize();
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Haider Traders',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const SplashScreen(),
    routes: {
      '/pick-list-history': (context) => const PickListHistoryScreen(),
      '/pick-list-detail': (context) => const PickListDetailScreen(),
      '/sales-history': (context) => const SalesHistoryScreen(),
      '/load-form-history': (context) => const LoadFormHistoryScreen(),
      '/load-form-detail': (context) => const LoadFormDetailScreen(),
      '/expenditure-history': (context) => const ExpenditureHistoryScreen(),
      '/income-history': (context) => const IncomeHistoryScreen(),
    },
    debugShowCheckedModeBanner: false,
  );
}
