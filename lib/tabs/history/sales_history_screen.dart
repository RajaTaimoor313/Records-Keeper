import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:haider_traders/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:haider_traders/tabs/reports/sale_report.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DatabaseHelper.instance.getSalesHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sales history found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save data from Secondary Sale Summary to see it here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          } else {
            final history = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final data = jsonDecode(item['data']);
                final date = DateTime.parse(item['date']);
                final List<Map<String, dynamic>> items = (data['items'] as List)
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();

                int totalUnits = 0;

                for (var item in items) {
                  final units = item['sale'] as int? ?? 0;
                  totalUnits += units;
                  // Calculate amount and profit based on load form data
                  // This will be detailed in the Secondary Sale Summary
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SaleReport(selectedDate: date.toIso8601String().split('T')[0]),
                        ),
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
                                'Sales from ${date.toLocal().toString().split(' ')[0]}',
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
                              IconButton(
                                icon: const Icon(
                                  Icons.print,
                                  color: Colors.deepPurple,
                                ),
                                tooltip: 'Print',
                                onPressed: () {
                                  _printSalesHistory(
                                    items: items,
                                    date: date,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTotalItem(
                                  'Total Units',
                                  totalUnits.toDouble(),
                                  formatter,
                                ),
                                _buildTotalItem(
                                  'Total Items',
                                  items.length.toDouble(),
                                  formatter,
                                ),
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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

  void _printSalesHistory({
    required List<Map<String, dynamic>> items,
    required DateTime date,
  }) async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await DefaultAssetBundle.of(
        context,
      ).load('assets/logo.png')).buffer.asUint8List(),
    );

    final String dateStr = DateFormat('dd-MM-yyyy').format(date);
    final String day = DateFormat('EEEE').format(date);

    int totalUnits = 0;
    for (var item in items) {
      totalUnits += (item['sale'] as int? ?? 0);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.SizedBox(height: 50, width: 50, child: pw.Image(logo)),
                pw.Text(
                  'Sales History',
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 10),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Date:', dateStr),
                    _buildInfoRow('Day:', day),
                    _buildInfoRow('Total Items:', items.length.toString()),
                    _buildInfoRow('Total Units:', totalUnits.toString()),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Total Pages:', '1'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: [
                'Brand Name',
                'Units',
                'Sale',
                'Return',
              ],
              data: items
                  .map(
                    (item) => [
                      (item['brandName'] ?? '').toString().replaceAll('\n', ' '),
                      (item['units'] ?? 0).toString(),
                      (item['sale'] ?? 0).toString(),
                      (item['returnQty'] ?? 0).toString(),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.center,
              cellStyle: pw.TextStyle(lineSpacing: 0, fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              border: pw.TableBorder.all(),
              cellHeight: 20,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 2,
              ),
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SalesHistory_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildInfoRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 16),
          pw.Text(value),
        ],
      ),
    );
  }
}

 