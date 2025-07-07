import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:records_keeper/tabs/sales/load_form.dart'; // For LoadFormItem

class LoadFormDetailScreen extends StatelessWidget {
  const LoadFormDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyItem =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final data = jsonDecode(historyItem['data']);
    final List<LoadFormItem> items = (data['items'] as List)
        .map((item) => LoadFormItem.fromMap(item))
        .toList();
    final date = DateTime.parse(data['date']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Load Form from ${date.toLocal().toString().split(' ')[0]}',
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${date.toLocal()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Load Form Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildItemsTable(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(List<LoadFormItem> items) {
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'Brand Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Issue',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Return',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Sale',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Sale Return',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: [
            ...items.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item.brandName)),
                  DataCell(Text(item.units.toString())),
                  DataCell(Text(item.returnQty.toString())),
                  DataCell(Text(item.sale.toString())),
                  DataCell(Text(item.saledReturn.toString())),
                ],
              );
            }),
            // Total row
            DataRow(
              color: MaterialStateProperty.all(Colors.deepPurple.shade50),
              cells: [
                const DataCell(
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataCell(
                  Text(
                    totalUnits.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalReturn.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalSale.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalSaledReturn.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
