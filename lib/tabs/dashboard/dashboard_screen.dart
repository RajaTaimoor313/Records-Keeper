import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _totalExpenditure = 0;
  double _totalIncome = 0;
  int _totalProducts = 0;
  int _totalShops = 0;
  int _totalManPower = 0;

  bool _isRange = false;
  DateTime? _selectedDate;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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

      final products = await db.getProducts();
      final shops = await db.getShops();
      final manPowers = await db.getSuppliers();
      double totalIncome = 0;
      double totalExpenditure = 0;
      if (_isRange && _selectedRange != null) {
        final start = _selectedRange!.start;
        final end = _selectedRange!.end;
        final startStr =
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
        final endStr =
            '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
        final summaries = await db.getBFSummariesInRange(startStr, endStr);
        for (final row in summaries) {
          totalIncome += (row['total_income'] as num?)?.toDouble() ?? 0.0;
          totalExpenditure +=
              (row['total_expenditure'] as num?)?.toDouble() ?? 0.0;
        }
      } else if (!_isRange && _selectedDate != null) {
        final d = _selectedDate!;
        final dateStr =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final row = await db.getBFSummaryByDate(dateStr);
        if (row != null) {
          totalIncome = (row['total_income'] as num?)?.toDouble() ?? 0.0;
          totalExpenditure =
              (row['total_expenditure'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (!mounted) return;

      setState(() {
        _totalProducts = products.length;
        _totalShops = shops.length;
        _totalManPower = manPowers.length;
        _totalIncome = totalIncome;
        _totalExpenditure = totalExpenditure;
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

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
            'Welcome back! Here\'s your business overview',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Switch(
                value: _isRange,
                onChanged: (val) {
                  setState(() {
                    _isRange = val;
                  });
                },
                activeColor: Colors.deepPurple,
              ),
              Text(
                _isRange ? 'Range Picker' : 'Single Date Picker',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              if (!_isRange)
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDate != null
                        ? DateFormat('dd-MMMM-yyyy').format(_selectedDate!)
                        : 'Select Date',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                      _loadDashboardData();
                    }
                  },
                ),
              if (_isRange)
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _selectedRange != null
                        ? '${DateFormat('dd-MMMM-yyyy').format(_selectedRange!.start)} - ${DateFormat('dd-MMMM-yyyy').format(_selectedRange!.end)}'
                        : 'Select Date Range',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: _selectedRange,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedRange = picked;
                      });
                      _loadDashboardData();
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Income',
                  value: 'Rs. ${_formatIndianNumber(_totalIncome)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  backgroundColor: Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Expenditure',
                  value: 'Rs. ${_formatIndianNumber(_totalExpenditure)}',
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                  backgroundColor: Colors.orange.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: Divider(thickness: 2)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Other Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              Expanded(child: Divider(thickness: 2)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Products',
                  value: _totalProducts.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.purple,
                  backgroundColor: Colors.purple.shade50,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Shops',
                  value: _totalShops.toString(),
                  icon: Icons.store,
                  color: Colors.indigo,
                  backgroundColor: Colors.indigo.shade50,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Man Power',
                  value: _totalManPower.toString(),
                  icon: Icons.people,
                  color: Colors.teal,
                  backgroundColor: Colors.teal.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
