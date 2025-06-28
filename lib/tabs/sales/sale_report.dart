import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'dart:convert';

class SaleReport extends StatefulWidget {
  const SaleReport({super.key});

  @override
  State<SaleReport> createState() => _SaleReportState();
}

class _SaleReportState extends State<SaleReport> {
  bool isLoading = true;
  List<Map<String, dynamic>> invoices = [];
  Set<int> expandedIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final invList = await db.query('invoices', orderBy: 'date DESC');
    setState(() {
      invoices = invList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, idx) {
                final inv = invoices[idx];
                final items = (inv['items'] is String)
                    ? List<Map<String, dynamic>>.from(jsonDecode(inv['items']))
                    : List<Map<String, dynamic>>.from(inv['items']);
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice #: ${inv['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Date: ${inv['date']}'),
                        Text('Shop: ${inv['shopName'] ?? '-'}'),
                        Text('Total: Rs. ${inv['total'] ?? '-'}'),
                        const Divider(),
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item['description'] ?? '')),
                                  Text('Units: ${item['unit']}'),
                                  const SizedBox(width: 12),
                                  Text('Amount: Rs. ${item['amount']}'),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 