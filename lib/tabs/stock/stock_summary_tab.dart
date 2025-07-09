import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_keeper/database_helper.dart';

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
    }
    totalStockTotal = openingStockTotal + receivedTotal;
    closingStockTotal =
        totalStockTotal - saleTotal; // saleTotal is 0 by default
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
  String? _selectedBrandId; // Track selected brand for row highlight

  @override
  void initState() {
    super.initState();
    _rolloverIfNeededAndLoadData();
  }

  Future<void> _rolloverIfNeededAndLoadData() async {
    setState(() {
      _isLoading = true;
    });
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.ensureAppMetadataTable();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final lastRollover = await dbHelper.getAppMetadata('last_rollover_date');
    if (lastRollover != todayStr) {
      // Perform rollover for all products
      final db = await dbHelper.database;
      final products = await db.query('products');
      for (final product in products) {
        // Get latest stock record for this product
        final records = await db.query(
          'stock_records',
          where: 'product_id = ?',
          whereArgs: [product['id']],
          orderBy: 'date DESC',
          limit: 1,
        );
        if (records.isNotEmpty) {
          final latest = records.first;
          // Only copy closing_stock_total to opening_stock_total
          final closingStockTotal = (latest['closing_stock_total'] as num).toInt();
          // Get boxPacking and boxRate from product
          final boxPacking = (product['boxPacking'] is int)
              ? product['boxPacking'] as int
              : int.tryParse(product['boxPacking'].toString()) ?? 0;
          final boxRate = product['boxRate'] is num
              ? (product['boxRate'] as num).toDouble()
              : double.tryParse(product['boxRate'].toString()) ?? 0.0;
          // Calculate CTN and Box for Opening Stock
          int openingStockCtn = 0;
          int openingStockUnits = 0;
          if (boxPacking > 0) {
            openingStockCtn = closingStockTotal ~/ boxPacking;
            openingStockUnits = closingStockTotal % boxPacking;
          } else {
            openingStockCtn = 0;
            openingStockUnits = closingStockTotal;
          }
          final openingStockValue = closingStockTotal * boxRate;
          await db.insert('stock_records', {
            'product_id': product['id'],
            'date': todayStr,
            'opening_stock_ctn': openingStockCtn,
            'opening_stock_units': openingStockUnits,
            'opening_stock_total': closingStockTotal,
            'opening_stock_value': openingStockValue,
            'received_ctn': 0,
            'received_units': 0,
            'received_total': 0,
            'received_value': 0,
            'total_stock_ctn': 0,
            'total_stock_units': 0,
            'total_stock_total': 0,
            'total_stock_value': 0,
            'sale_ctn': 0,
            'sale_units': 0,
            'sale_total': 0,
            'sale_value': 0,
            'saled_return_ctn': 0,
            'saled_return_units': 0,
            'saled_return_total': 0,
            'saled_return_value': 0,
            'closing_stock_ctn': 0,
            'closing_stock_units': 0,
            'closing_stock_total': 0,
            'closing_stock_value': 0,
          });
        }
      }
      await dbHelper.setAppMetadata('last_rollover_date', todayStr);
      // Reset available stock from total stock after rollover
      await dbHelper.resetAvailableStockFromTotalStock();
    }
    await _loadData();
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
          summaries.add(
            CompanyStockSummary(
              company: company,
              products: products,
              stockRecords: stockRecords,
            ),
          );
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

  Future<void> _updateAvailableStock() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get all products
      final products = await db.query('products');

      int updatedCount = 0;

      for (final product in products) {
        // Get the latest stock record for this product
        final records = await db.query(
          'stock_records',
          where: 'product_id = ?',
          whereArgs: [product['id']],
          orderBy: 'date DESC',
          limit: 1,
        );

        if (records.isNotEmpty) {
          final latestRecord = records.first;

          // Calculate total stock (opening + received)
          final openingStockTotal = (latestRecord['opening_stock_total'] as num)
              .toDouble();
          final receivedTotal = (latestRecord['received_total'] as num)
              .toDouble();
          final totalStock = openingStockTotal + receivedTotal;

          // Update the product's available_stock
          await db.update(
            'products',
            {'available_stock': totalStock},
            where: 'id = ?',
            whereArgs: [product['id']],
          );

          updatedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Available stock updated for $updatedCount products'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating available stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatIndianNumber(num value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );
    String formatted = formatter.format(value).trim();
    // Remove trailing .00, but keep decimals if nonzero
    if (formatted.endsWith('.00')) {
      formatted = formatted.substring(0, formatted.length - 3);
    } else if (formatted.contains('.')) {
      // Remove trailing zero if like .10 or .20, but keep .01, .02, etc.
      formatted = formatted.replaceFirst(RegExp(r'(\.\d*?[1-9])0+ 0?$'), r' ');
    }
    return formatted;
  }

  Widget _buildMainHeaderCell(String text, double columnSpan) {
    return Container(
      width: columnSpan * 120.0,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubHeaderCell(String text, [bool isBrand = false]) {
    return Container(
      width: isBrand ? 300.0 : 90.0,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget  _buildDataCell(
    String text, [
    bool isBrand = false,
    bool isBold = false,
  ]) {
    return Container(
      width: isBrand ? 300.0 : 90.0,
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
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getBrandValue(
    List<Map<String, dynamic>> records,
    dynamic productId,
    String field,
  ) {
    final record = records.firstWhere(
      (r) => r['product_id'].toString() == productId.toString(),
      orElse: () => {},
    );
    return record[field]?.toString() ?? '0';
  }

  double _getColumnTotal(CompanyStockSummary summary, String field) {
    double total = 0;

    for (final product in summary.products) {
      // Helper to parse values safely
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final boxPacking = product['boxPacking'] as int;

      if (field.startsWith('opening_stock_')) {
        final type = field.substring('opening_stock_'.length);
        if (type == 'ctn') {
          total += getVal('opening_stock_ctn');
        } else if (type == 'units') {
          total += getVal('opening_stock_units');
        } else if (type == 'total') {
          total += getVal('opening_stock_total');
        } else if (type == 'value') {
          total += getVal('opening_stock_value');
        }
      } else if (field.startsWith('received_')) {
        final type = field.substring('received_'.length);
        if (type == 'ctn') {
          total += getVal('received_ctn');
        } else if (type == 'units') {
          total += getVal('received_units');
        } else if (type == 'total') {
          total += getVal('received_total');
        } else if (type == 'value') {
          total += getVal('received_value');
        }
      } else if (field.startsWith('total_stock_')) {
        final type = field.substring('total_stock_'.length);
        if (type == 'ctn') {
          total += getVal('opening_stock_ctn') + getVal('received_ctn');
        } else if (type == 'units') {
          total += getVal('opening_stock_units') + getVal('received_units');
        } else if (type == 'total') {
          total += getVal('opening_stock_total') + getVal('received_total');
        } else if (type == 'value') {
          total += getVal('opening_stock_value') + getVal('received_value');
        }
      } else if (field.startsWith('sale_')) {
        final type = field.substring('sale_'.length);
        if (type == 'ctn') {
          final saleTotal = getVal('sale_total');
          if (saleTotal <= boxPacking) {
            total += 0; // No CTN if total <= box packing
          } else {
            total += saleTotal ~/ boxPacking; // Integer division for CTN
          }
        } else if (type == 'units') {
          final saleTotal = getVal('sale_total');
          if (saleTotal <= boxPacking) {
            total += saleTotal; // All boxes if total <= box packing
          } else {
            total += saleTotal % boxPacking; // Remainder for boxes
          }
        } else if (type == 'total') {
          total += getVal('sale_total');
        } else if (type == 'value') {
          total += getVal('sale_value');
        }
      } else if (field.startsWith('closing_stock_')) {
        final type = field.substring('closing_stock_'.length);
        if (type == 'ctn') {
          final totalStockCtn =
              getVal('opening_stock_ctn') + getVal('received_ctn');
          final saleTotal = getVal('sale_total');
          final saleCtn = saleTotal <= boxPacking ? 0 : saleTotal ~/ boxPacking;
          final saledReturnTotal = getVal('saled_return_total');
          final saledReturnCtn = saledReturnTotal <= boxPacking
              ? 0
              : saledReturnTotal ~/ boxPacking;
          final closingStockCtn = totalStockCtn - saleCtn + saledReturnCtn;
          total += closingStockCtn;
        } else if (type == 'units') {
          final totalStockUnits =
              getVal('opening_stock_units') + getVal('received_units');
          final saleTotal = getVal('sale_total');
          final saleBox = saleTotal <= boxPacking
              ? saleTotal
              : saleTotal % boxPacking;
          final saledReturnTotal = getVal('saled_return_total');
          final saledReturnBox = saledReturnTotal <= boxPacking
              ? saledReturnTotal
              : saledReturnTotal % boxPacking;
          final closingStockBox = totalStockUnits - saleBox + saledReturnBox;
          total += closingStockBox;
        } else if (type == 'total') {
          final totalStockTotal =
              getVal('opening_stock_total') + getVal('received_total');
          final saleTotal = getVal('sale_total');
          final saledReturnTotal = getVal('saled_return_total');
          total += totalStockTotal - saleTotal + saledReturnTotal;
        } else if (type == 'value') {
          final totalStockValue =
              getVal('opening_stock_value') + getVal('received_value');
          final saleValue = getVal('sale_value');
          final saledReturnValue = getVal('saled_return_value');
          total += totalStockValue - saleValue + saledReturnValue;
        }
      }
    }

    return total;
  }

  // Helper methods for Total row calculations using the same logic as individual rows
  double _calculateTotalStockCtn(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final totalStockTotal =
          getVal('opening_stock_total') + getVal('received_total');
      final boxPacking = product['boxPacking'] as int;
      if (boxPacking > 0) {
        if (totalStockTotal < boxPacking) {
          total += 0;
        } else {
          total += totalStockTotal ~/ boxPacking;
        }
      } else {
        total += 0;
      }
    }
    return total;
  }

  double _calculateTotalStockUnits(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final totalStockTotal =
          getVal('opening_stock_total') + getVal('received_total');
      final boxPacking = product['boxPacking'] as int;
      if (boxPacking > 0) {
        if (totalStockTotal < boxPacking) {
          total += totalStockTotal;
        } else {
          total += totalStockTotal % boxPacking;
        }
      } else {
        total += totalStockTotal;
      }
    }
    return total;
  }

  double _calculateTotalStockTotal(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      total += getVal('opening_stock_total') + getVal('received_total');
    }
    return total;
  }

  double _calculateTotalStockValue(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      total += getVal('opening_stock_value') + getVal('received_value');
    }
    return total;
  }

  double _calculateClosingStockCtn(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final totalStockTotal =
          getVal('opening_stock_total') + getVal('received_total');
      final saleTotal = getVal('sale_total');
      final saledReturnTotal = getVal('saled_return_total');
      final closingStockTotal = totalStockTotal - saleTotal + saledReturnTotal;
      final boxPacking = product['boxPacking'] as int;
      if (boxPacking > 0) {
        if (closingStockTotal < boxPacking) {
          total += 0;
        } else {
          total += closingStockTotal ~/ boxPacking;
        }
      } else {
        total += 0;
      }
    }
    return total;
  }

  double _calculateClosingStockUnits(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final totalStockTotal =
          getVal('opening_stock_total') + getVal('received_total');
      final saleTotal = getVal('sale_total');
      final saledReturnTotal = getVal('saled_return_total');
      final closingStockTotal = totalStockTotal - saleTotal + saledReturnTotal;
      final boxPacking = product['boxPacking'] as int;
      if (boxPacking > 0) {
        if (closingStockTotal < boxPacking) {
          total += closingStockTotal;
        } else {
          total += closingStockTotal % boxPacking;
        }
      } else {
        total += closingStockTotal;
      }
    }
    return total;
  }

  double _calculateClosingStockTotal(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final totalStockTotal =
          getVal('opening_stock_total') + getVal('received_total');
      final saleTotal = getVal('sale_total');
      final saledReturnTotal = getVal('saled_return_total');
      total += totalStockTotal - saleTotal + saledReturnTotal;
    }
    return total;
  }

  double _calculateClosingStockValue(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final totalStockTotal =
          getVal('opening_stock_total') + getVal('received_total');
      final saleTotal = getVal('sale_total');
      final saledReturnTotal = getVal('saled_return_total');
      final closingStockTotal = totalStockTotal - saleTotal + saledReturnTotal;
      final boxRate = product['boxRate'] is num
          ? (product['boxRate'] as num).toDouble()
          : double.tryParse(product['boxRate'].toString()) ?? 0.0;
      total += closingStockTotal * boxRate;
    }
    return total;
  }

  double _calculateSaleCtn(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final saleTotal = getVal('sale_total');
      final boxPacking = product['boxPacking'] as int;
      if (boxPacking > 0) {
        if (saleTotal < boxPacking) {
          total += 0;
        } else {
          total += saleTotal ~/ boxPacking;
        }
      } else {
        total += 0;
      }
    }
    return total;
  }

  double _calculateSaleUnits(CompanyStockSummary summary) {
    double total = 0;
    for (final product in summary.products) {
      double getVal(String fieldName) {
        return double.tryParse(
              _getBrandValue(summary.stockRecords, product['id'], fieldName),
            ) ??
            0.0;
      }

      final saleTotal = getVal('sale_total');
      final boxPacking = product['boxPacking'] as int;
      if (boxPacking > 0) {
        if (saleTotal < boxPacking) {
          total += saleTotal;
        } else {
          total += saleTotal % boxPacking;
        }
      } else {
        total += saleTotal;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_companySummaries.isEmpty) {
      return const Center(child: Text('No stock records found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _updateAvailableStock();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.update, size: 20),
                      label: const Text(
                        'Update Available Stock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stock Summary refreshed'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ..._companySummaries.map(
            (summary) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Header (only this is clickable)
                  InkWell(
                onTap: () {
                  setState(() {
                    if (_expandedCompanies.contains(summary.company)) {
                      _expandedCompanies.remove(summary.company);
                    } else {
                      _expandedCompanies.add(summary.company);
                    }
                  });
                },
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(8),
                      bottom: _expandedCompanies.contains(summary.company)
                          ? Radius.zero
                          : const Radius.circular(8),
                    ),
                    child: Container(
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
                  ),
                  // Detailed Table (if expanded) - NOT clickable
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
                                    Container(
                                      width: 40, // Just enough for 'No. '
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade100,
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: const Text(
                                        '#',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    _buildMainHeaderCell('Brands', 2.5),
                                    _buildMainHeaderCell('Invoice Rate', 1.5),
                                    _buildMainHeaderCell('Packing', 2.25),
                                    _buildMainHeaderCell('Opening Stock', 3),
                                    _buildMainHeaderCell('Received', 3),
                                    _buildMainHeaderCell('Total Stock', 3),
                                    _buildMainHeaderCell('Closing Stock', 3),
                                    _buildMainHeaderCell('Sale', 3),
                                  ],
                                ),
                              ),
                              // Sub Headers
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: const SizedBox.shrink(), // Empty for subheader
                                    ),
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
                              ...summary.products.asMap().entries.map((entry) {
                                final index = entry.key;
                                final product = entry.value;
                                // Helper to parse values safely
                                double getVal(String field) {
                                  return double.tryParse(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          field,
                                        ),
                                      ) ??
                                      0.0;
                                }

                                // Calculate Total Stock values
                                final totalStockTotal =
                                    getVal('opening_stock_total') +
                                    getVal('received_total');
                                final totalStockValue =
                                    getVal('opening_stock_value') +
                                    getVal('received_value');

                                // Get Sale values
                                getVal('sale_ctn');
                                getVal('sale_units');
                                final saleTotal = getVal('sale_total');
                                final saleValue = getVal('sale_value');

                                // Get Saled Return values
                                getVal('saled_return_ctn');
                                getVal('saled_return_units');
                                final saledReturnTotal = getVal(
                                  'saled_return_total',
                                );
                                getVal('saled_return_value');

                                // Calculate proper CTN and Box for Sale based on packing strategy
                                final boxPacking =
                                    (product['boxPacking'] is int)
                                    ? product['boxPacking'] as int
                                    : int.tryParse(
                                            product['boxPacking'].toString(),
                                          ) ??
                                          0;
                                int calculatedSaleCtn;
                                int calculatedSaleBox;

                                if (boxPacking > 0) {
                                  if (saleTotal < boxPacking) {
                                    calculatedSaleCtn = 0;
                                    calculatedSaleBox = saleTotal.toInt();
                                  } else {
                                    calculatedSaleCtn = saleTotal ~/ boxPacking;
                                    calculatedSaleBox =
                                        saleTotal.toInt() % boxPacking;
                                  }
                                } else {
                                  calculatedSaleCtn = 0;
                                  calculatedSaleBox = saleTotal.toInt();
                                }

                                // Calculate proper CTN and Box for Total Stock based on packing strategy
                                int calculatedTotalStockCtn;
                                int calculatedTotalStockBox;
                                if (boxPacking > 0) {
                                  if (totalStockTotal < boxPacking) {
                                    calculatedTotalStockCtn = 0;
                                    calculatedTotalStockBox = totalStockTotal
                                        .toInt();
                                  } else {
                                    calculatedTotalStockCtn =
                                        totalStockTotal ~/ boxPacking;
                                    calculatedTotalStockBox =
                                        totalStockTotal.toInt() % boxPacking;
                                  }
                                } else {
                                  calculatedTotalStockCtn = 0;
                                  calculatedTotalStockBox = totalStockTotal
                                      .toInt();
                                }

                                // Calculate proper CTN and Box for Saled Return based on packing strategy
                                // ... existing code ...
                                // Calculate Closing Stock (Total Stock - Sale + Saled Return)
                                final closingStockTotal =
                                    totalStockTotal -
                                    saleTotal +
                                    saledReturnTotal;
                                final closingStockValue =
                                    closingStockTotal *
                                    (product['boxRate'] is num
                                        ? (product['boxRate'] as num).toDouble()
                                        : double.tryParse(
                                                product['boxRate'].toString(),
                                              ) ??
                                              0.0);

                                // Calculate proper CTN and Box for Closing Stock based on packing strategy
                                int calculatedClosingStockCtn;
                                int calculatedClosingStockBox;
                                if (boxPacking > 0) {
                                  if (closingStockTotal < boxPacking) {
                                    calculatedClosingStockCtn = 0;
                                    calculatedClosingStockBox =
                                        closingStockTotal.toInt();
                                  } else {
                                    calculatedClosingStockCtn =
                                        closingStockTotal ~/ boxPacking;
                                    calculatedClosingStockBox =
                                        closingStockTotal.toInt() % boxPacking;
                                  }
                                } else {
                                  calculatedClosingStockCtn = 0;
                                  calculatedClosingStockBox = closingStockTotal
                                      .toInt();
                                }

                                return IntrinsicHeight(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedBrandId == product['id'].toString()) {
                                          _selectedBrandId = null; // Un-highlight if already selected
                                        } else {
                                          _selectedBrandId = product['id'].toString();
                                        }
                                      });
                                    },
                                    child: Container(
                                      color: _selectedBrandId == product['id'].toString()
                                          ? Colors.yellow.shade100 // Highlight color
                                          : null,
                                  child: Row(
                                    children: [
                                          Container(
                                            width: 40,
                                            padding: const EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              (index + 1).toString(),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Tooltip(
                                            message: product['brandCategory'] ?? '',
                                            child: _buildDataCell(product['brand'], true),
                                          ),
                                      // Invoice Rate
                                      _buildDataCell(_formatIndianNumber(product['ctnRate'])),
                                      _buildDataCell(_formatIndianNumber(product['boxRate'])),
                                      // Packing
                                      _buildDataCell(
                                        product['ctnPacking'].toString(),
                                      ),
                                      _buildDataCell(
                                        product['boxPacking'].toString(),
                                      ),
                                      _buildDataCell(
                                        product['unitsPacking'].toString(),
                                      ),
                                      // Opening Stock
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'opening_stock_ctn',
                                        ),
                                      ),
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'opening_stock_units',
                                        ),
                                      ),
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'opening_stock_total',
                                        ),
                                      ),
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'opening_stock_value',
                                        ),
                                      ),
                                      // Received
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'received_ctn',
                                        ),
                                      ),
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'received_units',
                                        ),
                                      ),
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'received_total',
                                        ),
                                      ),
                                      _buildDataCell(
                                        _getBrandValue(
                                          summary.stockRecords,
                                          product['id'],
                                          'received_value',
                                        ),
                                      ),
                                      // Total Stock (updated logic)
                                      _buildDataCell(
                                        calculatedTotalStockCtn.toString(),
                                      ),
                                      _buildDataCell(
                                        calculatedTotalStockBox.toString(),
                                      ),
                                      _buildDataCell(
                                        _formatIndianNumber(totalStockTotal),
                                      ),
                                      _buildDataCell(
                                        _formatIndianNumber(totalStockValue),
                                      ),
                                      // Closing Stock
                                      _buildDataCell(
                                        calculatedClosingStockCtn
                                            .toStringAsFixed(0),
                                      ),
                                      _buildDataCell(
                                        calculatedClosingStockBox
                                            .toStringAsFixed(0),
                                      ),
                                      _buildDataCell(
                                        _formatIndianNumber(closingStockTotal),
                                      ),
                                      _buildDataCell(
                                        _formatIndianNumber(closingStockValue),
                                      ),
                                      // Sale
                                      _buildDataCell(
                                        calculatedSaleCtn.toStringAsFixed(0),
                                      ),
                                      _buildDataCell(
                                        calculatedSaleBox.toStringAsFixed(0),
                                      ),
                                      _buildDataCell(
                                        _formatIndianNumber(saleTotal),
                                      ),
                                      _buildDataCell(
                                        _formatIndianNumber(saleValue),
                                      ),
                                    ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              // Total Row
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      padding: const EdgeInsets.all(8),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '•',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildDataCell('Total', true, true),
                                    // Empty cells for Invoice Rate
                                    _buildDataCell('', false, true),
                                    _buildDataCell('', false, true),
                                    // Empty cells for Packing
                                    _buildDataCell('', false, true),
                                    _buildDataCell('', false, true),
                                    _buildDataCell('', false, true),
                                    // Opening Stock totals
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'opening_stock_ctn',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'opening_stock_units',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'opening_stock_total',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'opening_stock_value',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    // Received totals
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'received_ctn',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'received_units',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'received_total',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(
                                          summary,
                                          'received_value',
                                        ),
                                      ),
                                      false,
                                      true,
                                    ),
                                    // Total Stock totals - calculate using the same logic as individual rows
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateTotalStockCtn(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateTotalStockUnits(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateTotalStockTotal(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateTotalStockValue(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    // Closing Stock totals - calculate using the same logic as individual rows
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateClosingStockCtn(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateClosingStockUnits(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateClosingStockTotal(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateClosingStockValue(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    // Sale totals - calculate using the same logic as individual rows
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateSaleCtn(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _calculateSaleUnits(summary),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(summary, 'sale_total'),
                                      ),
                                      false,
                                      true,
                                    ),
                                    _buildDataCell(
                                      _formatIndianNumber(
                                        _getColumnTotal(summary, 'sale_value'),
                                      ),
                                      false,
                                      true,
                                    ),
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
          ),
          // Add visually distinct Total card at the end
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: Colors.amber.shade100, // Visually distinct color
            child: InkWell(
              onTap: () {
                setState(() {
                  const totalKey = '__TOTAL__';
                  if (_expandedCompanies.contains(totalKey)) {
                    _expandedCompanies.remove(totalKey);
                  } else {
                    _expandedCompanies.add(totalKey);
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(8),
                        bottom: _expandedCompanies.contains('__TOTAL__')
                            ? Radius.zero
                            : const Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                        Icon(
                          _expandedCompanies.contains('__TOTAL__')
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  // Detailed Table (if expanded)
                  if (_expandedCompanies.contains('__TOTAL__'))
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Headers (remove Brands, Invoice Rate, Packing)
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  _buildMainHeaderCell('Opening Stock', 3),
                                  _buildMainHeaderCell('Received', 3),
                                  _buildMainHeaderCell('Total Stock', 3),
                                  _buildMainHeaderCell('Closing Stock', 3),
                                  _buildMainHeaderCell('Sale', 3),
                                ],
                              ),
                            ),
                            // Sub Headers (remove Brands, Invoice Rate, Packing)
                            IntrinsicHeight(
                              child: Row(
                                children: [
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
                            // Only one row: the grand total (remove Brands, Invoice Rate, Packing cells)
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Opening Stock totals
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'opening_stock_ctn'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'opening_stock_units'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'opening_stock_total'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'opening_stock_value'))), false, true),
                                  // Received totals
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'received_ctn'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'received_units'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'received_total'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'received_value'))), false, true),
                                  // Total Stock totals
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateTotalStockCtn(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateTotalStockUnits(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateTotalStockTotal(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateTotalStockValue(s))), false, true),
                                  // Closing Stock totals
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateClosingStockCtn(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateClosingStockUnits(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateClosingStockTotal(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateClosingStockValue(s))), false, true),
                                  // Sale totals
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateSaleCtn(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _calculateSaleUnits(s))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'sale_total'))), false, true),
                                  _buildDataCell(_formatIndianNumber(_companySummaries.fold(0.0, (sum, s) => sum + _getColumnTotal(s, 'sale_value'))), false, true),
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
          ),
        ],
      ),
    );
  }
}
