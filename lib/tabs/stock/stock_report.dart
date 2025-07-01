import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';

class StockReport extends StatefulWidget {
  const StockReport({super.key});

  @override
  State<StockReport> createState() => _StockReportState();
}

class _StockReportState extends State<StockReport> {
  bool isLoading = true;
  List<Map<String, dynamic>> products = [];
  Map<String, Map<String, dynamic>> latestStock = {};
  Map<String, double> availableStock = {};
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final prodList = await db.query('products');
    final stockMap = <String, Map<String, dynamic>>{};
    final availMap = <String, double>{};
    for (final prod in prodList) {
      final stock = await db.query('stock_records', where: 'product_id = ?', whereArgs: [prod['id']], orderBy: 'date DESC', limit: 1);
      if (stock.isNotEmpty) stockMap[prod['id'].toString()] = stock.first;
      final avail = prod['available_stock'];
      availMap[prod['id'].toString()] = (avail is num) ? avail.toDouble() : double.tryParse(avail.toString()) ?? 0.0;
    }
    setState(() {
      products = prodList;
      latestStock = stockMap;
      availableStock = availMap;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchText.isEmpty) return products;
    return products.where((prod) {
      final brand = (prod['brand'] ?? '').toString().toLowerCase();
      final company = (prod['company'] ?? '').toString().toLowerCase();
      return brand.contains(_searchText.toLowerCase()) || company.contains(_searchText.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stock Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by brand or company...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchText = val),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1000,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('No.')),
                              DataColumn(label: Text('Brand')),
                              DataColumn(label: Text('Company')),
                              DataColumn(label: Text('Available Stock')),
                              DataColumn(label: Text('Trade Rate')),
                              DataColumn(label: Text('Box Rate')),
                              DataColumn(label: Text('Packing')),
                            ],
                            rows: List.generate(_filteredProducts.length, (i) {
                              final prod = _filteredProducts[i];
                              final avail = availableStock[prod['id'].toString()] ?? 0;
                              return DataRow(cells: [
                                DataCell(Text((i + 1).toString())),
                                DataCell(Text(prod['brand'] ?? '')),
                                DataCell(Text(prod['company'] ?? '')),
                                DataCell(Text(avail.toStringAsFixed(2))),
                                DataCell(Text(prod['salePrice'].toString())),
                                DataCell(Text(prod['boxRate'].toString())),
                                DataCell(Text(prod['boxPacking'].toString())),
                              ]);
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 