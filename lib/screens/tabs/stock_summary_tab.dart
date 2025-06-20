import 'package:flutter/material.dart';
import '../../database_helper.dart';
import 'package:intl/intl.dart';

class CompanyStockSummary {
  final String company;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> stockRecords;
  double openingStockTotal = 0;
  double receivedTotal = 0;
  double totalStockTotal = 0;
  double closingStockTotal = 0;
  double saleTotal = 0;

  CompanyStockSummary({
    required this.company,
    required this.products,
    required this.stockRecords,
  }) {
    _calculateTotals();
  }

  void _calculateTotals() {
    for (final record in stockRecords) {
      openingStockTotal += (record['opening_stock_value'] as num).toDouble();
      receivedTotal += (record['received_value'] as num).toDouble();
      totalStockTotal += (record['total_stock_value'] as num).toDouble();
      closingStockTotal += (record['closing_stock_value'] as num).toDouble();
      saleTotal += (record['sale_value'] as num).toDouble();
    }
  }
}

class StockSummaryTab extends StatefulWidget {
  const StockSummaryTab({super.key});

  @override
  State<StockSummaryTab> createState() => _StockSummaryTabState();
}

class _StockSummaryTabState extends State<StockSummaryTab> {
  bool _isLoading = true;
  List<CompanyStockSummary> _companySummaries = [];
  final Set<String> _expandedCompanies = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Get all companies
      final companies = await db.query(
        'products',
        columns: ['DISTINCT company'],
        orderBy: 'company ASC',
      );

      // Get data for each company
      final summaries = <CompanyStockSummary>[];
      for (final companyRow in companies) {
        final company = companyRow['company'] as String;

        // Get all products for this company
        final products = await db.query(
          'products',
          where: 'company = ?',
          whereArgs: [company],
          orderBy: 'brand ASC',
        );

        // Get all stock records for this company's products
        final stockRecords = <Map<String, dynamic>>[];
        for (final product in products) {
          final records = await db.query(
            'stock_records',
            where: 'product_id = ?',
            whereArgs: [product['id']],
            orderBy: 'date DESC',
            limit: 1, // Get only the latest record for each product
          );
          if (records.isNotEmpty) {
            stockRecords.addAll(records);
          }
        }

        if (stockRecords.isNotEmpty) {
          summaries.add(CompanyStockSummary(
            company: company,
            products: products,
            stockRecords: stockRecords,
          ));
        }
      }

      setState(() {
        _companySummaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stock summary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatIndianNumber(double value) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);
    return formatter.format(value).trim();
  }

  String _getTotalValue(List<Map<String, dynamic>> records, String field) {
    final total = records.fold<double>(
      0,
      (sum, record) => sum + (double.tryParse(record[field]?.toString() ?? '0') ?? 0),
    );
    return _formatIndianNumber(total);
  }

  Widget _buildMainHeaderCell(String text, int columnSpan) {
    return Container(
      width: columnSpan * 120.0,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubHeaderCell(String text, [bool isBrand = false]) {
    return Container(
      width: isBrand ? 240.0 : 120.0,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, [bool isBrand = false, bool isBold = false]) {
    return Container(
      width: isBrand ? 240.0 : 120.0,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          overflow: isBrand ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        textAlign: isBrand ? TextAlign.left : TextAlign.right,
      ),
    );
  }

  String _getBrandValue(List<Map<String, dynamic>> records, dynamic productId, String field) {
    final record = records.firstWhere(
      (r) => r['product_id'].toString() == productId.toString(),
      orElse: () => {field: '0'},
    );
    return record[field]?.toString() ?? '0';
  }

  double _getColumnTotal(CompanyStockSummary summary, String field) {
    double total = 0;
    for (final product in summary.products) {
      final value = double.tryParse(_getBrandValue(summary.stockRecords, product['id'], field)) ?? 0;
      total += value;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_companySummaries.isEmpty) {
      return const Center(
        child: Text('No stock records found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Stock Summary',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ..._companySummaries.map((summary) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_expandedCompanies.contains(summary.company)) {
                    _expandedCompanies.remove(summary.company);
                  } else {
                    _expandedCompanies.add(summary.company);
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(8),
                        bottom: _expandedCompanies.contains(summary.company) 
                            ? Radius.zero 
                            : const Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.company,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        Icon(
                          _expandedCompanies.contains(summary.company)
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                  // Detailed Table (if expanded)
                  if (_expandedCompanies.contains(summary.company))
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Headers
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  _buildMainHeaderCell('Brands', 2),
                                  _buildMainHeaderCell('Invoice Rate', 2),
                                  _buildMainHeaderCell('Packing', 3),
                                  _buildMainHeaderCell('Opening Stock', 4),
                                  _buildMainHeaderCell('Received', 4),
                                  _buildMainHeaderCell('Total Stock', 4),
                                  _buildMainHeaderCell('Closing Stock', 4),
                                  _buildMainHeaderCell('Sale', 4),
                                ],
                              ),
                            ),
                            // Sub Headers
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  _buildSubHeaderCell('', true), // Brands
                                  // Invoice Rate
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  // Packing
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  _buildSubHeaderCell('Units'),
                                  // Opening Stock
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  _buildSubHeaderCell('Total'),
                                  _buildSubHeaderCell('Value'),
                                  // Received
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  _buildSubHeaderCell('Total'),
                                  _buildSubHeaderCell('Value'),
                                  // Total Stock
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  _buildSubHeaderCell('Total'),
                                  _buildSubHeaderCell('Value'),
                                  // Closing Stock
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  _buildSubHeaderCell('Total'),
                                  _buildSubHeaderCell('Value'),
                                  // Sale
                                  _buildSubHeaderCell('CTN'),
                                  _buildSubHeaderCell('Box'),
                                  _buildSubHeaderCell('Total'),
                                  _buildSubHeaderCell('Value'),
                                ],
                              ),
                            ),
                            // Data Rows
                            ...summary.products.map((product) => IntrinsicHeight(
                              child: Row(
                                children: [
                                  _buildDataCell(product['brand'], true),
                                  // Invoice Rate
                                  _buildDataCell(product['ctnRate'].toString()),
                                  _buildDataCell(product['boxRate'].toString()),
                                  // Packing
                                  _buildDataCell(product['ctnPacking'].toString()),
                                  _buildDataCell(product['boxPacking'].toString()),
                                  _buildDataCell(product['unitsPacking'].toString()),
                                  // Opening Stock
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'opening_stock_ctn')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'opening_stock_units')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'opening_stock_total')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'opening_stock_value')),
                                  // Received
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'received_ctn')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'received_units')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'received_total')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'received_value')),
                                  // Total Stock
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'total_stock_ctn')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'total_stock_units')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'total_stock_total')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'total_stock_value')),
                                  // Closing Stock
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'closing_stock_ctn')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'closing_stock_units')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'closing_stock_total')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'closing_stock_value')),
                                  // Sale
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'sale_ctn')),
                                  _buildDataCell(_getBrandValue(summary.stockRecords, product['id'], 'sale_units')),
                                  _buildDataCell('0.00'),
                                  _buildDataCell('0.00'),
                                ],
                              ),
                            )),
                            // Total Row
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  _buildDataCell('Total', true, true),
                                  // Empty cells for Invoice Rate
                                  _buildDataCell('', false, true),
                                  _buildDataCell('', false, true),
                                  // Empty cells for Packing
                                  _buildDataCell('', false, true),
                                  _buildDataCell('', false, true),
                                  _buildDataCell('', false, true),
                                  // Opening Stock totals
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'opening_stock_ctn')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'opening_stock_units')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'opening_stock_total')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'opening_stock_value')), false, true),
                                  // Received totals
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'received_ctn')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'received_units')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'received_total')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'received_value')), false, true),
                                  // Total Stock totals
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'total_stock_ctn')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'total_stock_units')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'total_stock_total')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'total_stock_value')), false, true),
                                  // Closing Stock totals
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'closing_stock_ctn')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'closing_stock_units')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'closing_stock_total')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'closing_stock_value')), false, true),
                                  // Sale totals
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'sale_ctn')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'sale_units')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'sale_total')), false, true),
                                  _buildDataCell(_formatIndianNumber(_getColumnTotal(summary, 'sale_value')), false, true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
} 