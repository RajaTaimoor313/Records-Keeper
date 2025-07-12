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
  int _secondarySaleUnits = 0;
  double _secondarySaleValue = 0.0;
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      final currentDate = await db.getCurrentDate();
      _currentDate = currentDate;

      // --- AUTO ROLLOVER LOGIC ---
      final lastRolloverDate = await db.getAppMetadata(
        'last_dashboard_rollover',
      );
      if (lastRolloverDate != currentDate) {
        await performDailyRollover();
        await db.setAppMetadata('last_dashboard_rollover', currentDate);
      }
      // --- END AUTO ROLLOVER LOGIC ---

      // Check if we have data for today
      final todayData = await db.getDailySales(currentDate);

      if (todayData != null) {
        // Load today's saved data
        setState(() {
          _primarySaleUnits = todayData['primary_sale_units'] as int;
          _primarySaleValue = (todayData['primary_sale_value'] as num)
              .toDouble();
          _secondarySaleUnits = todayData['secondary_sale_units'] as int;
          _secondarySaleValue = (todayData['secondary_sale_value'] as num)
              .toDouble();
          _isLoading = false;
        });
      } else {
        // Show zeroes, do NOT recalculate and save
        setState(() {
          _primarySaleUnits = 0;
          _primarySaleValue = 0.0;
          _secondarySaleUnits = 0;
          _secondarySaleValue = 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // No SnackBar message per user request
    }
  }

  Future<void> _calculateAndSaveTodayData() async {
    try {
      final db = DatabaseHelper.instance;
      final database = await db.database;
      final currentDate = _currentDate;

      // Get stock summary data for Primary Sale (from Received totals)
      double primarySaleUnits = 0.0;
      double primarySaleValue = 0.0;

      // Get all companies
      final companies = await database.query(
        'products',
        columns: ['DISTINCT company'],
        orderBy: 'company ASC',
      );

      // Calculate totals from stock records for each company
      for (final companyRow in companies) {
        final company = companyRow['company'] as String;

        // Get all products for this company
        final products = await database.query(
          'products',
          where: 'company = ?',
          whereArgs: [company],
          orderBy: 'brand ASC',
        );

        // Get all stock records for this company's products
        for (final product in products) {
          final records = await database.query(
            'stock_records',
            where: 'product_id = ?',
            whereArgs: [product['id']],
            orderBy: 'date DESC',
            limit: 1, // Get only the latest record for each product
          );
          if (records.isNotEmpty) {
            final record = records.first;
            primarySaleUnits += (record['received_total'] as num).toDouble();
            primarySaleValue += (record['received_value'] as num).toDouble();
          }
        }
      }

      // For Secondary Sale, use the same logic as Secondary Sale Summary in Report
      int secondarySaleUnits = 0;
      double secondarySaleValue = 0.0;
      final loadFormHistory = await db.getLoadFormHistory();
      final products = await db.getProducts();
      final today = currentDate;
      final todayHistory = loadFormHistory
          .where((entry) => entry['date'] == today)
          .toList();
      Map<String, dynamic>? getProductByBrand(String brand) {
        try {
          return products.firstWhere((prod) => prod['brand'] == brand);
        } catch (_) {
          return null;
        }
      }

      for (final entry in todayHistory) {
        final data = entry['data'];
        if (data == null) continue;
        final List<dynamic> items = [];
        try {
          items.addAll(
            (jsonDecode(data) as Map<String, dynamic>)['items']
                as List<dynamic>,
          );
        } catch (_) {
          continue;
        }
        for (final item in items) {
          final unitsSaled = int.tryParse(item['sale'].toString()) ?? 0;
          final brandName = item['brandName'];
          double tradeRate = 0.0;
          final prod = getProductByBrand(brandName);
          if (prod != null && prod['salePrice'] != null) {
            tradeRate = double.tryParse(prod['salePrice'].toString()) ?? 0.0;
          }
          secondarySaleUnits += unitsSaled;
          secondarySaleValue += tradeRate * unitsSaled;
        }
      }

      // Save today's data
      await db.saveDailySales(
        _currentDate,
        primarySaleUnits.toInt(),
        primarySaleValue,
        secondarySaleUnits,
        secondarySaleValue,
      );

      if (!mounted) return;
      setState(() {
        _primarySaleUnits = primarySaleUnits.toInt();
        _primarySaleValue = primarySaleValue;
        _secondarySaleUnits = secondarySaleUnits;
        _secondarySaleValue = secondarySaleValue;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // No SnackBar message per user request
    }
  }

  Widget _buildPrimarySaleCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade100],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_num,
                      color: Colors.white,
                      size: 28,
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stay_current_landscape,
                      color: Colors.white,
                      size: 28,
                    ),
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

  Widget _buildSecondarySaleCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.18),
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
                'Secondary Sale',
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
                  Icons.trending_up,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_num,
                      color: Colors.white,
                      size: 28,
                    ),
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
                      _secondarySaleUnits.toString(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stay_current_landscape,
                      color: Colors.white,
                      size: 28,
                    ),
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
                      _formatIndianNumber(_secondarySaleValue),
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

  void _showPreviousSaleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getDailySalesHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 200,
                  child: Center(
                    child: Text('Error loading data: ${snapshot.error}'),
                  ),
                ),
              );
            }

            final historyData = snapshot.data ?? [];
            final filteredData = historyData
                .where((entry) => entry['date'] != _currentDate)
                .toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Previous Sales History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Table Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Date Column
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    // Primary Sale Column
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Primary Sale',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Units',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Value',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Secondary Sale Column
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Secondary Sale',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Units',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Value',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Historical Data Rows
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: filteredData.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(40),
                                        child: const Text(
                                          'No previous sales data available',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : Column(
                                        children: filteredData.map((entry) {
                                          final date = entry['date'] as String;
                                          final primaryUnits =
                                              entry['primary_sale_units']
                                                  .toString();
                                          final primaryValue =
                                              _formatIndianNumber(
                                                entry['primary_sale_value'],
                                              );
                                          final secondaryUnits =
                                              entry['secondary_sale_units']
                                                  .toString();
                                          final secondaryValue =
                                              _formatIndianNumber(
                                                entry['secondary_sale_value'],
                                              );

                                          return _buildDataRow(
                                            date,
                                            primaryUnits,
                                            'Rs. $primaryValue',
                                            secondaryUnits,
                                            'Rs. $secondaryValue',
                                          );
                                        }).toList(),
                                      ),
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
          },
        );
      },
    );
  }

  Widget _buildDataRow(
    String date,
    String primaryUnits,
    String primaryValue,
    String secondaryUnits,
    String secondaryValue,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Date Column
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                date,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Primary Sale Column
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      primaryUnits,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      primaryValue,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Secondary Sale Column
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      secondaryUnits,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      secondaryValue,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
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
            'Welcome back! Here\'s your Sale overview',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: 'Refresh',
                child: ElevatedButton(
                  onPressed: _calculateAndSaveTodayData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  child: const Icon(Icons.refresh, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _showPreviousSaleDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Previous Sale',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPrimarySaleCard(),
          const SizedBox(height: 24),
          _buildSecondarySaleCard(),
        ],
      ),
    );
  }

  Future<void> performDailyRollover() async {
    try {
      final db = DatabaseHelper.instance;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate =
          '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // Get yesterday's data
      final yesterdayData = await db.getDailySales(yesterdayDate);

      if (yesterdayData != null) {
        // Clear today's data to start fresh
        await db.clearDailySales(_currentDate);

        // Set dashboard state to zero
        if (mounted) {
          setState(() {
            _primarySaleUnits = 0;
            _primarySaleValue = 0.0;
            _secondarySaleUnits = 0;
            _secondarySaleValue = 0.0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // No SnackBar message per user request
      }
    }
  }
}
