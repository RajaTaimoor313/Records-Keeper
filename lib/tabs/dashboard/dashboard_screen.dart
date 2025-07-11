import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _primarySaleUnits = 0;
  double _primarySaleValue = 0.0;


  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  String _formatIndianNumber(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = DatabaseHelper.instance;
      int totalUnits = 0;
      double totalValue = 0.0;
      final loadFormHistory = await db.getLoadFormHistory();
      final products = await db.getProducts();
      Map<String, dynamic>? getProductByBrand(String brand) {
        try {
          return products.firstWhere(
            (prod) => prod['brand'] == brand,
          );
        } catch (_) {
          return null;
        }
      }
      for (final entry in loadFormHistory) {
        final data = entry['data'];
        if (data == null) continue;
        final List<dynamic> items = [];
        try {
          items.addAll((jsonDecode(data) as Map<String, dynamic>)['items'] as List<dynamic>);
        } catch (_) {
          continue;
        }
        for (final item in items) {
          final brandName = item['brandName'];
          final unitsSaled = int.tryParse(item['sale'].toString()) ?? 0;
          double tradeRate = 0.0;
          if (item.containsKey('tradeRate') && item['tradeRate'] != null && item['tradeRate'].toString().isNotEmpty) {
            tradeRate = double.tryParse(item['tradeRate'].toString()) ?? 0.0;
          } else {
            final prod = getProductByBrand(brandName);
            if (prod != null && prod['salePrice'] != null) {
              tradeRate = double.tryParse(prod['salePrice'].toString()) ?? 0.0;
            }
          }
          totalUnits += unitsSaled;
          totalValue += tradeRate * unitsSaled;
        }
      }
      if (!mounted) return;
      setState(() {
        _primarySaleUnits = totalUnits;
        _primarySaleValue = totalValue;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPrimarySaleCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.18),
            spreadRadius: 4,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Primary Sale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_num, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Units',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _primarySaleUnits.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.stay_current_landscape, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Value',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatIndianNumber(_primarySaleValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back! Here\'s your business overview',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildPrimarySaleCard(),
        ],
      ),
    );
  }
}
