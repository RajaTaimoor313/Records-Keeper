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
  List<Map<String, dynamic>> loadFormHistory = [];
  Set<int> expandedIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final history = await DatabaseHelper.instance.getLoadFormHistory();
    setState(() {
      loadFormHistory = history;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getDetailedItems(String data) async {
    final List<dynamic> items = jsonDecode(data)['items'];
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> detailed = [];
    for (final item in items) {
      final brandName = item['brandName'];
      final prodList = await db.query(
        'products',
        where: 'brand = ?',
        whereArgs: [brandName],
      );
      if (prodList.isNotEmpty) {
        final prod = prodList.first;
        detailed.add({
          'brandName': brandName,
          'company': prod['company'] ?? '',
          'boxRate': prod['boxRate'] ?? '',
          'tradeRate': prod['salePrice'] ?? '',
          'unitsSaled': item['sale'] ?? '',
        });
      } else {
        detailed.add({
          'brandName': brandName,
          'company': '',
          'boxRate': '',
          'tradeRate': '',
          'unitsSaled': item['sale'] ?? '',
        });
      }
    }
    return detailed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: loadFormHistory.length,
              itemBuilder: (context, idx) {
                final entry = loadFormHistory[idx];
                final date = entry['date'];
                final data = entry['data'];
                final isExpanded = expandedIndexes.contains(idx);
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Date: $date'),
                        trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onTap: () async {
                          setState(() {
                            if (isExpanded) {
                              expandedIndexes.remove(idx);
                            } else {
                              expandedIndexes.add(idx);
                            }
                          });
                        },
                      ),
                      if (isExpanded)
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getDetailedItems(data),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final items = snapshot.data!;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Brand Name')),
                                  DataColumn(label: Text('Company Name')),
                                  DataColumn(label: Text('Box Rate')),
                                  DataColumn(label: Text('Trade Rate')),
                                  DataColumn(label: Text('Units Saled')),
                                ],
                                rows: items
                                    .map(
                                      (item) => DataRow(
                                        cells: [
                                          DataCell(
                                            Text(item['brandName'].toString()),
                                          ),
                                          DataCell(
                                            Text(item['company'].toString()),
                                          ),
                                          DataCell(
                                            Text(item['boxRate'].toString()),
                                          ),
                                          DataCell(
                                            Text(item['tradeRate'].toString()),
                                          ),
                                          DataCell(
                                            Text(item['unitsSaled'].toString()),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
