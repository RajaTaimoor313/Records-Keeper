import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../database_helper.dart';
import 'dart:math' as math;

class LoadFormTab extends StatefulWidget {
  const LoadFormTab({super.key});

  @override
  State<LoadFormTab> createState() => _LoadFormTabState();
}

class _LoadFormTabState extends State<LoadFormTab> {
  bool _isLoading = true;
  List<LoadFormItem> _items = [];
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await DatabaseHelper.instance.getLoadFormItems();
      setState(() {
        _items = items.map((item) => LoadFormItem.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recalculateAllSales() async {
    // Use the database helper method to recalculate all sales
    await DatabaseHelper.instance.recalculateAllLoadFormSales();
    
    // Reload items to reflect the updated values
    final items = await DatabaseHelper.instance.getLoadFormItems();
    setState(() {
      _items = items.map((item) => LoadFormItem.fromMap(item)).toList();
    });
  }

  Future<void> _updateItem(LoadFormItem item) async {
    try {
      await DatabaseHelper.instance.updateLoadFormItem(item.toMap());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateSale(LoadFormItem item, String returnQty) async {
    final returnVal = int.tryParse(returnQty) ?? 0;
    final saleVal = item.units - returnVal;

    final updatedItem = item.copyWith(
      returnQty: returnVal,
      sale: saleVal,
    );
    
    // Update state to show immediate change
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    });

    // Persist changes to the database
    await _updateItem(updatedItem);
  }

  Future<void> _showLoadFormPrintPreview() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Load Form', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('No.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Brand Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Units', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Return', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Sale', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Saled Return', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Text((index + 1).toString()),
                        pw.Text(item.brandName),
                        pw.Text(item.units.toString()),
                        pw.Text(item.returnQty.toString()),
                        pw.Text(item.sale.toString()),
                        pw.Text(item.saledReturn.toString()),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'LoadForm_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Widget _buildTableHeaderCell(String text, {TextAlign align = TextAlign.center}) {
    return Container(
      height: 60, // Fixed height for header cells
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableCell(
    LoadFormItem item,
    String value,
    String field,
    {TextAlign align = TextAlign.center}
  ) {
    final bool isEditable = !['no', 'brandName', 'units', 'sale'].contains(field);
    final displayValue = isEditable ? item.getDisplayValue(field) : value;

    return Container(
      height: 44, // Fixed height for data cells
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: isEditable ? Colors.white : Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: isEditable
          ? Center(
              child: TextFormField(
                initialValue: displayValue,
                textAlign: align,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
                onChanged: (newValue) {
                  if (field == 'returnQty') {
                    _calculateSale(item, newValue);
                  } else {
                    final updatedItem = item.copyWith(
                      issue: field == 'issue' ? int.tryParse(newValue) ?? 0 : item.issue,
                      saledReturn: field == 'saledReturn' ? int.tryParse(newValue) ?? 0 : item.saledReturn,
                    );
                    _updateItem(updatedItem);
                  }
                },
              ),
            )
          : Center(
              child: Text(
                field == 'sale' ? item.sale.toString() : displayValue,
                textAlign: align,
                style: TextStyle(
                  color: field == 'sale' ? Colors.deepPurple.shade700 : Colors.black87,
                  fontSize: 13,
                  fontWeight: field == 'brandName' || field == 'sale' ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
    );
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _horizontalScrollController,
              child: SizedBox(
                width: math.max(constraints.maxWidth, 650.0), // Minimum width with scroll
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: _buildTableHeaderCell('No.')),
                          Expanded(flex: 3, child: _buildTableHeaderCell('Brand Name')),
                          Expanded(flex: 1, child: _buildTableHeaderCell('Units')),
                          Expanded(flex: 1, child: _buildTableHeaderCell('Return')),
                          Expanded(flex: 1, child: _buildTableHeaderCell('Sale')),
                          Expanded(flex: 1, child: _buildTableHeaderCell('Saled Return')),
                        ],
                      ),
                    ),
                    // Table Body
                    if (_items.isEmpty)
                      Container(
                        height: 200, // Reduced empty state height
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48, // Reduced icon size
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generate some invoices to see items here',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: _verticalScrollController,
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildEditableCell(
                                    item,
                                    (index + 1).toString(),
                                    'no',
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _buildEditableCell(
                                    item,
                                    item.brandName,
                                    'brandName',
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _buildEditableCell(
                                    item,
                                    item.units.toString(),
                                    'units',
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _buildEditableCell(
                                    item,
                                    '',
                                    'returnQty',
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _buildEditableCell(
                                    item,
                                    '',
                                    'sale',
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: _buildEditableCell(
                                    item,
                                    '',
                                    'saledReturn',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Mobile layout
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Load Form',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your inventory items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      // First recalculate all sales in the database
                                      await DatabaseHelper.instance.recalculateAllLoadFormSales();
                                      // Then refresh the data
                                      await _loadItems();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Load Form refreshed and sales recalculated'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        // Update stock records with sale data from Load Form
                                        await DatabaseHelper.instance.updateStockRecordsFromLoadForm();
                                        
                                        // New functionality: show print preview
                                        await _showLoadFormPrintPreview();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Stock Summary has been updated successfully.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error updating Stock Summary: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    label: const Text(
                                      'Generate',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_rounded,
                                          color: Colors.deepPurple.shade400,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Total Items: ${_items.length}',
                                          style: TextStyle(
                                            color: Colors.deepPurple.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        
                        // Desktop layout
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Load Form',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage your inventory items',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    // First recalculate all sales in the database
                                    await DatabaseHelper.instance.recalculateAllLoadFormSales();
                                    // Then refresh the data
                                    await _loadItems();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Load Form refreshed and sales recalculated'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      // Update stock records with sale data from Load Form
                                      await DatabaseHelper.instance.updateStockRecordsFromLoadForm();
                                      
                                      // New functionality: show print preview
                                      await _showLoadFormPrintPreview();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Stock Summary has been updated successfully.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error updating Stock Summary: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 20),
                                  label: const Text(
                                    'Generate',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_rounded,
                                        color: Colors.deepPurple.shade400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total Items: ${_items.length}',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Table
                  Expanded(
                    child: _buildTable(),
                  ),
                ],
              ),
            ),
    );
  }
}

class LoadFormItem {
  final int id;
  final String brandName;
  final int units;
  final int issue;
  final int returnQty;
  final int sale;
  final int saledReturn;

  LoadFormItem({
    required this.id,
    required this.brandName,
    required this.units,
    required this.issue,
    required this.returnQty,
    required this.sale,
    required this.saledReturn,
  });

  factory LoadFormItem.fromMap(Map<String, dynamic> map) {
    final units = map['units'] ?? 0;
    final returnQty = map['returnQty'] ?? 0;
    final calculatedSale = units - returnQty;
    
    return LoadFormItem(
      id: map['id'],
      brandName: map['brandName'],
      units: units,
      issue: map['issue'] ?? 0,
      returnQty: returnQty,
      sale: calculatedSale, // Auto-calculate sale as units - returnQty
      saledReturn: map['saledReturn'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brandName': brandName,
      'units': units,
      'issue': issue,
      'returnQty': returnQty,
      'sale': sale,
      'saledReturn': saledReturn,
    };
  }

  LoadFormItem copyWith({
    int? id,
    String? brandName,
    int? units,
    int? issue,
    int? returnQty,
    int? sale,
    int? saledReturn,
  }) {
    return LoadFormItem(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      units: units ?? this.units,
      issue: issue ?? this.issue,
      returnQty: returnQty ?? this.returnQty,
      sale: sale ?? this.sale,
      saledReturn: saledReturn ?? this.saledReturn,
    );
  }

  String getDisplayValue(String field) {
    switch (field) {
      case 'issue':
        return issue.toString();
      case 'returnQty':
        return returnQty.toString();
      case 'sale':
        return sale.toString();
      case 'saledReturn':
        return saledReturn.toString();
      default:
        return '';
    }
  }
} 