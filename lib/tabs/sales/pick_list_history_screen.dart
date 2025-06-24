import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:records_keeper/database_helper.dart';
import 'package:records_keeper/tabs/sales/pick_list_tab.dart';
import 'package:intl/intl.dart';

class PickListHistoryScreen extends StatefulWidget {
  const PickListHistoryScreen({super.key});

  @override
  State<PickListHistoryScreen> createState() => _PickListHistoryScreenState();
}

class _PickListHistoryScreenState extends State<PickListHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DatabaseHelper.instance.getPickListHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List History'),
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
                final List<PickListItem> items = (data['items'] as List)
                    .map((item) => PickListItem.fromMap(item))
                    .toList();

                // Calculate totals
                double totalBillAmount = 0;
                double totalCash = 0;
                double totalCredit = 0;
                double totalDiscount = 0;
                double totalReturn = 0;

                for (var item in items) {
                  totalBillAmount += item.billAmount;
                  totalCash += item.cash;
                  totalCredit += item.credit;
                  totalDiscount += item.discount;
                  totalReturn += item.return_;
                }

                final formatter = NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: '',
                  decimalDigits: 2,
                );

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
                        '/pick-list-detail',
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
                                'Pick List from ${date.toLocal().toString().split(' ')[0]}',
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
                                _buildTotalItem('Bill Amount', totalBillAmount, formatter),
                                _buildTotalItem('Cash', totalCash, formatter),
                                _buildTotalItem('Credit', totalCredit, formatter),
                                _buildTotalItem('Discount', totalDiscount, formatter),
                                _buildTotalItem('Return', totalReturn, formatter),
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

  Widget _buildTotalItem(String label, double value, NumberFormat formatter) {
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
            formatter.format(value),
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