import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:records_keeper/database_helper.dart';
import 'package:records_keeper/tabs/sales/load_form.dart';

class LoadFormHistoryScreen extends StatefulWidget {
  const LoadFormHistoryScreen({super.key});

  @override
  State<LoadFormHistoryScreen> createState() => _LoadFormHistoryScreenState();
}

class _LoadFormHistoryScreenState extends State<LoadFormHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DatabaseHelper.instance.getLoadFormHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Form History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history found.'));
          } else {
            final history = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final data = jsonDecode(item['data']);
                final date = DateTime.parse(data['date']);
                final List<LoadFormItem> items = (data['items'] as List)
                    .map((item) => LoadFormItem.fromMap(item))
                    .toList();

                // Calculate totals
                int totalUnits = 0;
                int totalReturn = 0;
                int totalSale = 0;
                int totalSaledReturn = 0;

                for (var item in items) {
                  totalUnits += item.units;
                  totalReturn += item.returnQty;
                  totalSale += item.sale;
                  totalSaledReturn += item.saledReturn;
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/load-form-detail',
                        arguments: item,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Load Form from ${date.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              Text(
                                '${items.length} items',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTotalItem('Units', totalUnits),
                                _buildTotalItem('Return', totalReturn),
                                _buildTotalItem('Sale', totalSale),
                                _buildTotalItem('Saled Return', totalSaledReturn),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildTotalItem(String label, int value) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
} 