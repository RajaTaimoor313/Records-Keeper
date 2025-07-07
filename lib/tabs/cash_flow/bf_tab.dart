// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class BFData {
  final String date;
  final String category;
  final String details;
  final double amount;
  final bool isIncome;

  BFData({
    required this.date,
    required this.category,
    required this.details,
    required this.amount,
    required this.isIncome,
  });
}

class BFTab extends StatefulWidget {
  const BFTab({super.key});

  @override
  State<BFTab> createState() => _BFTabState();
}

class _BFTabState extends State<BFTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'B/F tab is under construction.',
        style: TextStyle(fontSize: 20, color: Colors.deepPurple),
      ),
    );
  }
}
