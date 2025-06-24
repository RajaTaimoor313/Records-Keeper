import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:records_keeper/tabs/sales/pick_list_tab.dart'; // For PickListItem
import 'package:records_keeper/tabs/suppliers/supplier.dart'; // For Supplier
import 'package:intl/intl.dart';

class PickListDetailScreen extends StatelessWidget {
  const PickListDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyItem = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final data = jsonDecode(historyItem['data']);
    final List<PickListItem> items = (data['items'] as List)
        .map((item) => PickListItem.fromMap(item))
        .toList();
    final List<Supplier> manPower = (data['manpower'] as List)
        .map((item) => Supplier.fromMap(item))
        .toList();
    final Map<String, String> notes = Map<String, String>.from(data['notes']);
    final date = DateTime.parse(data['date']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pick List from ${date.toLocal().toString().split(' ')[0]}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${date.toLocal()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Man Power:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...manPower.map((s) => Text('${s.type}: ${s.name}')),
            const SizedBox(height: 16),
            const Text('Pick List Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildItemsTable(items),
            ),
            const SizedBox(height: 16),
            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...notes.entries.map((e) => Text('Notes of ${e.key}: ${e.value}')),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(List<PickListItem> items) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );

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
            DataColumn(label: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Bill Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Cash', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Return', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            ...items.map((item) {
              return DataRow(cells: [
                DataCell(Text(item.shopName)),
                DataCell(Text(formatter.format(item.billAmount))),
                DataCell(Text(formatter.format(item.cash))),
                DataCell(Text(formatter.format(item.credit))),
                DataCell(Text(formatter.format(item.discount))),
                DataCell(Text(formatter.format(item.return_))),
              ]);
            }),
            // Total row
            DataRow(
              color: MaterialStateProperty.all(Colors.deepPurple.shade50),
              cells: [
                const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatter.format(totalBillAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatter.format(totalCash), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatter.format(totalCredit), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatter.format(totalDiscount), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatter.format(totalReturn), style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 