// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../database_helper.dart';

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
    _initializeQuickDates();
    // Set default date range from 1st of current month to current date
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1); // 1st of current month
    endDate = now; // Current date
    isDateRange = true;
    _loadData();
  }

  void _initializeQuickDates() {
    final now = DateTime.now();
    quickDates = [
      now, // Today
      now.subtract(Duration(days: 1)), // Yesterday
      now.subtract(Duration(days: 2)), // 2 days ago
      now.subtract(Duration(days: 3)), // 3 days ago
      now.subtract(Duration(days: 4)), // 4 days ago
    ];
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

      // Calculate all-time totals
      allTimeIncome = incomeData.fold(0, (sum, record) => sum + record.amount);
      allTimeExpenditure = expenditureData.fold(0, (sum, record) => sum + record.amount);

      // Combine and sort all records by date
      setState(() {
        allRecords = [...incomeData, ...expenditureData];
        allRecords.sort((a, b) {
          final aDateParts = a.date.split('/');
          final bDateParts = b.date.split('/');

          final aDate = DateTime(
            int.parse(aDateParts[2]),
            int.parse(aDateParts[1]),
            int.parse(aDateParts[0]),
          );
          final bDate = DateTime(
            int.parse(bDateParts[2]),
            int.parse(bDateParts[1]),
            int.parse(bDateParts[0]),
          );

          return aDate.compareTo(bDate);
        });
        _filterRecords();
      });
    } catch (e) {
      print('Error loading B/F data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterRecords() {
    if (startDate == null) {
      filteredRecords = allRecords;
    } else {
      filteredRecords = allRecords.where((record) {
        final dateParts = record.date.split('/');
        final recordDate = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );

        if (endDate != null) {
          return recordDate.isAtSameMomentAs(startDate!) ||
                 (recordDate.isAfter(startDate!) && recordDate.isBefore(endDate!)) ||
                 recordDate.isAtSameMomentAs(endDate!);
        } else {
          return recordDate.year == startDate!.year &&
                 recordDate.month == startDate!.month &&
                 recordDate.day == startDate!.day;
        }
      }).toList();
    }

    // Calculate financial summaries
    salesRecoveryTotal = 0;
    otherIncomeTotal = 0;
    totalIncome = 0;
    totalExpenditure = 0;

    for (var record in filteredRecords) {
      if (record.isIncome) {
        totalIncome += record.amount;
        if (record.category == 'Sales & Recovery') {
          salesRecoveryTotal += record.amount;
        } else if (record.category == 'Other Income') {
          otherIncomeTotal += record.amount;
        }
      } else {
        totalExpenditure += record.amount;
      }
    }

    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (!isDateRange) {
            endDate = picked; // In single date mode, set both dates to same day
          } else if (endDate != null && picked.isAfter(endDate!)) {
            // If start date is after end date, clear end date
            endDate = null;
          }
        } else {
          if (picked.isBefore(startDate!)) {
            // Show error message if end date is before start date
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('End date must be after start date'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            endDate = picked;
          }
        }
      });
      _filterRecords();
    }
  }

  String _getDateRangeText() {
    if (startDate == null) {
      return 'All Time';
    } else if (!isDateRange) {
      return '${startDate!.day}/${startDate!.month}/${startDate!.year}';
    } else {
      return '${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}';
    }
  }



  void _resetToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      startDate = DateTime(now.year, now.month, 1); // 1st of current month
      endDate = now; // Current date
      isDateRange = true;
    });
    _filterRecords();
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
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                      icon: Icon(Icons.refresh, color: Colors.deepPurple),
                      onPressed: _resetToCurrentMonth,
                      tooltip: 'Reset to Current Month',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: isDateRange,
                    onChanged: (value) {
                      setState(() {
                        isDateRange = value ?? false;
                        if (!isDateRange && startDate != null) {
                          // In single date mode, set both dates to same day
                          endDate = startDate;
                        }
                      });
                      _filterRecords();
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  Text(
                    'Show Date Range',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: Icon(Icons.calendar_today, size: 18),
                      label: Text(isDateRange ? 'Start Date' : 'Select Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  if (isDateRange) ...[
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text('End Date'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(
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
                          SizedBox(width: 16),
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
                      SizedBox(height: 16),
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
                          SizedBox(width: 16),
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
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: _buildFinancialCard(
                          title: 'Net Balance',
                          amount: allTimeIncome - allTimeExpenditure,
                          icon: Icons.account_balance,
                          color: (allTimeIncome - allTimeExpenditure) >= 0 ? Colors.green : Colors.red,
                          showAllTime: true,
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
    bool showAllTime = false,
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
                  style: TextStyle(
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