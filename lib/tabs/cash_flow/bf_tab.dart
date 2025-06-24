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

class BFTab extends StatefulWidget {
  const BFTab({super.key});

  @override
  State<BFTab> createState() => _BFTabState();
}

class _BFTabState extends State<BFTab> {
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
      final incomeData = incomeRecords.map((record) => BFData(
        date: record['date'],
        category: record['category'],
        details: record['details'],
        amount: record['amount'],
        isIncome: true,
      )).toList();

      // Load expenditure records
      final expenditureRecords = await DatabaseHelper.instance.getExpenditures();
      final expenditureData = expenditureRecords.map((record) => BFData(
        date: record['date'],
        category: record['category'],
        details: record['details'],
        amount: record['amount'],
        isIncome: false,
      )).toList();

      // Get today's date in the same format as stored (dd/MM/yyyy or yyyy-MM-dd)
      final now = DateTime.now();
      final todayStr1 = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final todayStr2 = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Filter for today only
      final todayIncome = incomeData.where((r) => r.date == todayStr1 || r.date == todayStr2).toList();
      final todayExpenditure = expenditureData.where((r) => r.date == todayStr1 || r.date == todayStr2).toList();

      // Calculate financial summaries for today
      salesRecoveryTotal = todayIncome.where((r) => r.category == 'Sales & Recovery').fold(0.0, (sum, r) => sum + r.amount);
      otherIncomeTotal = todayIncome.where((r) => r.category == 'Other Income').fold(0.0, (sum, r) => sum + r.amount);
      totalIncome = salesRecoveryTotal + otherIncomeTotal;
      totalExpenditure = todayExpenditure.fold(0.0, (sum, r) => sum + r.amount);

      // Save summary to bf_summary table (use yyyy-MM-dd for key)
      final todayDbKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
      print('Error loading B/F data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        final dayStr = DateFormat('EEEE').format(now).toUpperCase();
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
                              title: 'Other Income',
                              amount: otherIncomeTotal,
                              icon: Icons.wallet_membership,
                              color: Colors.green,
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
                      SizedBox(
                        width: double.infinity,
                        child: _buildFinancialCard(
                          title: 'Net Balance',
                          amount: totalIncome - totalExpenditure,
                          icon: Icons.account_balance,
                          color: (totalIncome - totalExpenditure) >= 0 ? Colors.green : Colors.red,
                        ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
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
                  'Rs. ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),],
            ),
          ),
        ],
      ),
    );
  }
} 