import 'package:flutter/material.dart';
import '../database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _totalSales = 0;
  double _totalExpenditure = 0;
  double _totalIncome = 0;
  int _totalProducts = 0;
  int _totalShops = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = DatabaseHelper.instance;
      
      // Load summary data
      final products = await db.getProducts();
      final shops = await db.getShops();
      final incomes = await db.getIncomes();
      final expenditures = await db.getExpenditures();
      final invoices = await db.getInvoices();

      if (!mounted) return;

      setState(() {
        _totalProducts = products.length;
        _totalShops = shops.length;
        _totalIncome = incomes.fold(0.0, (sum, item) => sum + (item['amount'] as double));
        _totalExpenditure = expenditures.fold(0.0, (sum, item) => sum + (item['amount'] as double));
        _totalSales = invoices.fold(0.0, (sum, item) => sum + (item['total'] as double));
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
              Icon(
                icon,
                color: color,
                size: 24,
              ),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 
                          (MediaQuery.of(context).size.width > 800 ? 3 : 2),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard(
                title: 'Total Sales',
                value: 'Rs. ${_totalSales.toStringAsFixed(2)}',
                icon: Icons.trending_up,
                color: Colors.blue,
                backgroundColor: Colors.blue.shade50,
              ),
              _buildSummaryCard(
                title: 'Total Income',
                value: 'Rs. ${_totalIncome.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
                backgroundColor: Colors.green.shade50,
              ),
              _buildSummaryCard(
                title: 'Total Expenditure',
                value: 'Rs. ${_totalExpenditure.toStringAsFixed(2)}',
                icon: Icons.shopping_cart,
                color: Colors.orange,
                backgroundColor: Colors.orange.shade50,
              ),
              _buildSummaryCard(
                title: 'Total Products',
                value: _totalProducts.toString(),
                icon: Icons.inventory_2,
                color: Colors.purple,
                backgroundColor: Colors.purple.shade50,
              ),
              _buildSummaryCard(
                title: 'Total Shops',
                value: _totalShops.toString(),
                icon: Icons.store,
                color: Colors.indigo,
                backgroundColor: Colors.indigo.shade50,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 