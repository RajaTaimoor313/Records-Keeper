// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'package:intl/intl.dart';

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

class DayEndSummaryTab extends StatefulWidget {
  const DayEndSummaryTab({super.key});

  @override
  State<DayEndSummaryTab> createState() => _DayEndSummaryTabState();
}

class _DayEndSummaryTabState extends State<DayEndSummaryTab> {
  bool isLoading = false;
  List<BFData> allRecords = [];
  List<BFData> filteredRecords = [];

  DateTime? startDate;
  DateTime? endDate;
  bool isDateRange = false;

  // Financial summary data
  double salesRecoveryTotal = 0;
  double otherIncomeTotal = 0;
  double totalIncome = 0;
  double totalExpenditure = 0;
  double personalExpenses = 0;
  double otherExpenses = 0;

  // Quick date selection
  List<DateTime> quickDates = [];

  // Add a new variable to track all-time totals
  double allTimeIncome = 0;
  double allTimeExpenditure = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load income records
      final incomeRecords = await DatabaseHelper.instance.getIncomes();
      final incomeData = incomeRecords
          .map(
            (record) => BFData(
              date: record['date'],
              category: record['category'],
              details: record['details'],
              amount: record['amount'],
              isIncome: true,
            ),
          )
          .toList();

      // Load expenditure records
      final expenditureRecords = await DatabaseHelper.instance
          .getExpenditures();
      final expenditureData = expenditureRecords
          .map(
            (record) => BFData(
              date: record['date'],
              category: record['category'],
              details: record['details'],
              amount: record['amount'],
              isIncome: false,
            ),
          )
          .toList();

      // Get today's date in yyyy-MM-dd format
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      // Filter for today only
      final todayIncome = incomeData.where((r) => r.date == todayStr).toList();
      final todayExpenditure = expenditureData
          .where((r) => r.date == todayStr)
          .toList();

      // Calculate financial summaries for today
      salesRecoveryTotal = todayIncome
          .where((r) => r.category == 'Sales & Recovery')
          .fold(0.0, (sum, r) => sum + r.amount);
      otherIncomeTotal = todayIncome
          .where((r) => r.category == 'Other Income')
          .fold(0.0, (sum, r) => sum + r.amount);
      totalIncome = salesRecoveryTotal + otherIncomeTotal;
      totalExpenditure = todayExpenditure.fold(0.0, (sum, r) => sum + r.amount);
      personalExpenses = todayExpenditure
          .where((r) => r.category == 'Personal')
          .fold(0.0, (sum, r) => sum + r.amount);
      otherExpenses = todayExpenditure
          .where((r) => r.category != 'Personal')
          .fold(0.0, (sum, r) => sum + r.amount);

      // Save summary to bf_summary table (use yyyy-MM-dd for key)
      final todayDbKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await DatabaseHelper.instance.upsertBFSummary(
        date: todayDbKey,
        salesRecovery: salesRecoveryTotal,
        otherIncome: otherIncomeTotal,
        totalIncome: totalIncome,
        totalExpenditure: totalExpenditure,
        netBalance: totalIncome - totalExpenditure,
      );

      setState(() {
        allRecords = [...todayIncome, ...todayExpenditure];
        filteredRecords = allRecords;
      });
    } catch (e) {
      print('Error loading Day End Summary data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatIndianNumberNoDecimal(double value) {
    final formatter = NumberFormat.decimalPattern('en_IN');
    return formatter.format(value.round());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
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
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final dateStr = DateFormat('dd-MMMM-yyyy').format(now);
                        final dayStr = DateFormat(
                          'EEEE',
                        ).format(now).toUpperCase();
                        return Text(
                          '$dateStr  ($dayStr)',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading data...',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFinancialCard(
                              title: 'Sales & Recovery',
                              amount: salesRecoveryTotal,
                              icon: Icons.wallet,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancialCard(
                              title: 'Personal Expenses',
                              amount: personalExpenses,
                              icon: Icons.person,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFinancialCard(
                              title: 'Other Income',
                              amount: otherIncomeTotal,
                              icon: Icons.wallet_membership,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancialCard(
                              title: 'Other Expenses',
                              amount: otherExpenses,
                              icon: Icons.money_off,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFinancialCard(
                              title: 'Total Income',
                              amount: totalIncome,
                              icon: Icons.account_balance_wallet,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancialCard(
                              title: 'Total Expenditure',
                              amount: totalExpenditure,
                              icon: Icons.shopping_cart,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFinancialCard(
                        title: 'Net Balance',
                        amount: totalIncome - totalExpenditure,
                        icon: Icons.account_balance,
                        color: (totalIncome - totalExpenditure) >= 0
                            ? Colors.green
                            : Colors.red,
                        isNetBalance: true,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isNetBalance = false,
  }) {
    if (isNetBalance) {
      final bool isPositive = amount >= 0;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [Colors.green.shade400, Colors.blue.shade400]
                : [Colors.red.shade400, Colors.orange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.25),
              spreadRadius: 2,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs. ${_formatIndianNumberNoDecimal(amount)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_formatIndianNumberNoDecimal(amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 