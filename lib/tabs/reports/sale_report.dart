import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

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
    final indianFormat = NumberFormat.decimalPattern('en_IN');
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
                              child: Builder(
                                builder: (context) {
                                  // Calculate rows and totals
                                  int totalUnits = 0;
                                  double totalAmount = 0;
                                  double totalProfit = 0;
                                  final dataRows = items.map((item) {
                                    final boxRate = double.tryParse(item['boxRate'].toString()) ?? 0;
                                    final tradeRate = double.tryParse(item['tradeRate'].toString()) ?? 0;
                                    final unitsSaled = int.tryParse(item['unitsSaled'].toString()) ?? 0;
                                    final amount = tradeRate * unitsSaled;
                                    final profit = amount - (boxRate * unitsSaled);
                                    totalUnits += unitsSaled;
                                    totalAmount += amount;
                                    totalProfit += profit;
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item['brandName'].toString())),
                                        DataCell(Text(item['company'].toString())),
                                        DataCell(Text(indianFormat.format(boxRate))),
                                        DataCell(Text(indianFormat.format(tradeRate))),
                                        DataCell(Text(indianFormat.format(unitsSaled))),
                                        DataCell(Text(indianFormat.format(amount.round()))),
                                        DataCell(Text(indianFormat.format(profit.round()))),
                                      ],
                                    );
                                  }).toList();
                                  // Add totals row
                                  dataRows.add(
                                    DataRow(
                                      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                        return Colors.grey[200];
                                      }),
                                      cells: [
                                        const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                        const DataCell(Text('')),
                                        const DataCell(Text('')),
                                        const DataCell(Text('')),
                                        DataCell(Text(indianFormat.format(totalUnits), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(indianFormat.format(totalAmount.round()), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(indianFormat.format(totalProfit.round()), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                  return DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Brand Name')),
                                      DataColumn(label: Text('Company Name')),
                                      DataColumn(label: Text('Box Rate')),
                                      DataColumn(label: Text('Trade Rate')),
                                      DataColumn(label: Text('Units Sale')),
                                      DataColumn(label: Text('Amount')),
                                      DataColumn(label: Text('Profit')),
                                    ],
                                    rows: dataRows,
                                  );
                                },
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
