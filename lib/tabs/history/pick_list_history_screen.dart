import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:haider_traders/database_helper.dart';
import 'package:haider_traders/tabs/sales/pick_list_tab.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:haider_traders/tabs/sales/pick_list_detail_screen.dart';

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
                      final Map<String, dynamic> notesMap = data['notes'] != null ? Map<String, dynamic>.from(data['notes']) : {};
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Pick List from ${date.toLocal().toString().split(' ')[0]}'),
                            content: SizedBox(
                              width: 700,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PickListDetailTable(items: items),
                                    const SizedBox(height: 16),
                                    if (notesMap.isNotEmpty) ...[
                                      const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ...notesMap.entries.map((e) => Text('Notes of ${e.key}: ${e.value}')),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
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
                              IconButton(
                                icon: const Icon(
                                  Icons.print,
                                  color: Colors.deepPurple,
                                ),
                                tooltip: 'Print',
                                onPressed: () {
                                  _printPickListHistory(
                                    items: items,
                                    date: date,
                                    manpower: data['manpower'],
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
                                  'Bill Amount',
                                  totalBillAmount,
                                  formatter,
                                ),
                                _buildTotalItem('Cash', totalCash, formatter),
                                _buildTotalItem(
                                  'Credit',
                                  totalCredit,
                                  formatter,
                                ),
                                _buildTotalItem(
                                  'Discount',
                                  totalDiscount,
                                  formatter,
                                ),
                                _buildTotalItem(
                                  'Return',
                                  totalReturn,
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

  void _printPickListHistory({
    required List<PickListItem> items,
    required DateTime date,
    required List<dynamic>? manpower,
  }) async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await DefaultAssetBundle.of(
        context,
      ).load('assets/logo.png')).buffer.asUint8List(),
    );
    final numberFormat = NumberFormat('#,##0', 'en_US');
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');
    String formatNumber(num value) {
      if (value % 1 == 0) {
        return numberFormat.format(value);
      } else {
        return moneyFormat.format(value);
      }
    }

    final String dateStr = DateFormat('dd-MM-yyyy').format(date);
    final String day = DateFormat('EEEE').format(date);
    String supplier = '';
    String orderBooker = '';
    if (manpower != null) {
      supplier = manpower
          .where((mp) => mp['type'] == 'Supplier')
          .map((mp) => mp['name'])
          .join(', ');
      orderBooker = manpower
          .where((mp) => mp['type'] == 'Order Booker')
          .map((mp) => mp['name'])
          .join(', ');
    }
    final double totalBillAmount = items.fold(
      0.0,
      (sum, item) => sum + item.billAmount,
    );
    final double totalCash = items.fold(0.0, (sum, item) => sum + item.cash);
    final double totalCredit = items.fold(
      0.0,
      (sum, item) => sum + item.credit,
    );
    final double totalDiscount = items.fold(
      0.0,
      (sum, item) => sum + item.discount,
    );
    final double totalReturn = items.fold(
      0.0,
      (sum, item) => sum + item.return_,
    );
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
                  'Pick List',
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
                    _buildInfoRow('Supplier:', supplier),
                    _buildInfoRow('Order Booker:', orderBooker),
                    _buildInfoRow(
                      'Total Bill Amount:',
                      formatNumber(totalBillAmount),
                    ),
                    _buildInfoRow('Total Credit:', formatNumber(totalCredit)),
                    _buildInfoRow(
                      'Total Discount:',
                      formatNumber(totalDiscount),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Date:', dateStr),
                    _buildInfoRow('Day:', day),
                    _buildInfoRow('Total Cash:', formatNumber(totalCash)),
                    _buildInfoRow('Total Return:', formatNumber(totalReturn)),
                    _buildInfoRow('Total Pages:', '1'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: [
                'Invoice No.',
                'Shop',
                'Bill Amount',
                'Cash',
                'Credit',
                'Discount',
                'Return',
              ],
              data: items
                  .map(
                    (item) => [
                      (item.invoiceNumber ?? '').replaceAll('\n', ' '),
                      (item.shopName).replaceAll('\n', ' '),
                      formatNumber(item.billAmount),
                      formatNumber(item.cash),
                      formatNumber(item.credit),
                      formatNumber(item.discount),
                      formatNumber(item.return_),
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
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
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
      name: 'PickListHistory_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
