import 'package:flutter/material.dart';
import 'package:haider_traders/tabs/accounts/add_asset_tab.dart';
import 'package:haider_traders/tabs/accounts/view_assets_tab.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _totalAssets = 0.0;

  void _updateTotalAssets(double value) {
    setState(() {
      _totalAssets = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
                Tab(icon: Icon(Icons.visibility_outlined), text: 'View'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.deepPurple.shade50,
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: Colors.deepPurple, size: 32),
                  const SizedBox(width: 16),
                  Text(
                    'Total Assets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Rs. ${_totalAssets.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AddAssetTab(),
                ViewAssetsTab(onTotalAssetsChanged: _updateTotalAssets),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
