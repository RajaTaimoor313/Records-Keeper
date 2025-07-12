import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SaleReport extends StatefulWidget {
  final String? selectedDate;
  
  const SaleReport({super.key, this.selectedDate});

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
    final targetDate = widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      loadFormHistory = history.where((entry) => entry['date'] == targetDate).toList();
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
    final targetDate = widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = widget.selectedDate == null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Secondary Sale Summary${isToday ? '' : ' - $targetDate'}'),
        // actions: [
        //   if (isToday && loadFormHistory.isNotEmpty)
        //     IconButton(
        //       icon: const Icon(Icons.save),
        //       tooltip: 'Save to History',
        //       onPressed: () => _saveToHistory(),
        //     ),
        // ],
      ),
              body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : loadFormHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isToday ? 'No data for today.' : 'No data for $targetDate',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add items to the Load Form to see data here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
              : ListView.builder(
                  itemCount: loadFormHistory.length,
                  itemBuilder: (context, idx) {
                    final entry = loadFormHistory[idx];
                    final data = entry['data'];
                    return FutureBuilder<List<Map<String, dynamic>>>(
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
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
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
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
