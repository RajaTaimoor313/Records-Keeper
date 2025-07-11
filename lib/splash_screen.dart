import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:intl/intl.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;
  late final AnimationController _textController;
  late final Animation<double> _textFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      _textController.forward();
    });
    _handleDateChangeAndNavigate();
  }

  Future<void> _handleDateChangeAndNavigate() async {
    final db = DatabaseHelper.instance;
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final lastDate = await db.getAppMetadata('last_open_date');
    if (lastDate == null || lastDate != todayStr) {
      await db.deleteTodayExpenditure(todayStr);
      await db.deleteTodayIncome(todayStr);
      await db.setAppMetadata('last_open_date', todayStr);
    }
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoAnimation,
              child: Image.asset('assets/logo.png', width: 120, height: 120),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _textFadeAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Text(
                  'Haider Traders',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.black,
                    fontFamily: 'Segoe Script',
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Color(0x26512DA8),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
