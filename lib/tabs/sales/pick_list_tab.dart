import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:records_keeper/database_helper.dart';
import 'dart:convert';

import 'package:records_keeper/tabs/suppliers/supplier.dart';

class PickListTab extends StatefulWidget {
  const PickListTab({super.key});

  @override
  State<PickListTab> createState() => _PickListTabState();
}

class _PickListTabState extends State<PickListTab> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  bool _isLoading = true;
  List<PickListItem> _items = [];
  List<Supplier> _suppliers = [];
  final List<Supplier> _selectedManPowers = [];
  bool _showSupplierSearch = false;
  final TextEditingController _supplierSearchController =
      TextEditingController();
  final Map<int, TextEditingController> _noteControllers = {
    5000: TextEditingController(),
    1000: TextEditingController(),
    500: TextEditingController(),
    100: TextEditingController(),
    50: TextEditingController(),
    20: TextEditingController(),
    10: TextEditingController(),
  };
  String? _noteError;
  final List<Map<String, dynamic>> _pendingReturns = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _supplierSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await DatabaseHelper.instance.getPickListItems();
      setState(() {
        _items = items.map((item) => PickListItem.fromMap(item)).toList();
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

  Future<void> _updateItem(PickListItem item) async {
    try {
      await DatabaseHelper.instance.updatePickListItem(item.toMap());
      await _loadItems(); // Reload to ensure data consistency
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

  Future<void> _loadSuppliers() async {
    final supplierData = await DatabaseHelper.instance.getSuppliers();
    setState(() {
      _suppliers = supplierData.map((data) => Supplier.fromMap(data)).toList();
    });
  }

  Widget _buildTableHeaderCell(
    String text, {
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      height: 60,
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

  Widget _buildTableCell(
    String value, {
    TextAlign align = TextAlign.center,
    bool isNumeric = false,
    bool isEditable = false,
    bool isPaymentType = false,
    Function(String)? onChanged,
    Function(String)? onFieldSubmitted,
    String? hintText,
  }) {
    String displayValue = value;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 0,
    );

    if (isNumeric) {
      final number = double.tryParse(value) ?? 0.0;
      if (number == 0) {
        displayValue = '';
      } else {
        displayValue = formatter.format(number);
      }
    }

    if (isPaymentType) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 120),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPaymentTypeOption(
                      label: 'Cash',
                      isSelected: value == 'Cash',
                      onTap: () {
                        if (onChanged != null) {
                          onChanged('Cash');
                        }
                      },
                      isFirst: true,
                    ),
                    _buildPaymentTypeOption(
                      label: 'Credit',
                      isSelected: value == 'Credit',
                      onTap: () {
                        if (onChanged != null) {
                          onChanged('Credit');
                        }
                      },
                      isFirst: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: isEditable ? Colors.white : Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Center(
        child: isEditable
            ? TextFormField(
                initialValue: displayValue,
                textAlign: align,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                onChanged: onChanged,
                onFieldSubmitted: onFieldSubmitted,
              )
            : Text(
                displayValue,
                textAlign: align,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: isNumeric ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isFirst,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
          border: !isFirst
              ? Border(left: BorderSide(color: Colors.grey.shade300, width: 1))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
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
              child: SingleChildScrollView(
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
                                      'Pick List',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage your pick list items',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
                                        Icons.receipt_long_rounded,
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
                                    'Pick List',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your pick list items',
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
                                      try {
                                        // Update Load Form for all pending returns
                                        for (final ret in _pendingReturns) {
                                          await DatabaseHelper.instance
                                              .updateLoadFormItemReturn(
                                                ret['brandName'] as String,
                                                ret['units'] as int,
                                              );
                                        }
                                        _pendingReturns.clear();

                                        // Recalculate all sales in Load Form to ensure consistency
                                        await DatabaseHelper.instance
                                            .recalculateAllLoadFormSales();

                                        // Insert ledger records for credit
                                        for (final item in _items) {
                                          if ((item.credit) > 0) {
                                            await DatabaseHelper.instance
                                                .insertLedger({
                                                  'shopName': item.shopName,
                                                  'shopCode': item.code,
                                                  'date': DateTime.now()
                                                      .toIso8601String()
                                                      .split('T')[0],
                                                  'details': '',
                                                  'debit': item
                                                      .credit, // Credit value from Pick List goes to Debit in Ledger
                                                  'credit': 0,
                                                  'balance': null,
                                                });
                                          }
                                        }

                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Returns processed successfully and Load Form updated',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }

                                        _showNoteDialog();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error processing returns: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
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
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                    ),
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
                                          Icons.receipt_long_rounded,
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
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showSupplierSearch = !_showSupplierSearch;
                          _supplierSearchController.clear();
                        });
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Man Power'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_showSupplierSearch &&
                        _selectedManPowers.length < _suppliers.length)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Autocomplete<Supplier>(
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return _suppliers;
                                  }
                                  return _suppliers.where(
                                    (Supplier s) =>
                                        s.name.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ) ||
                                        s.phone.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ) ||
                                        s.address.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase(),
                                        ),
                                  );
                                },
                            displayStringForOption: (Supplier s) => s.name,
                            fieldViewBuilder:
                                (
                                  context,
                                  controller,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  _supplierSearchController.text =
                                      controller.text;
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Search Man Power',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.search),
                                    ),
                                  );
                                },
                            onSelected: (Supplier s) {
                              setState(() {
                                if (!_selectedManPowers.any(
                                  (mp) => mp.id == s.id,
                                )) {
                                  _selectedManPowers.add(s);
                                }
                                _showSupplierSearch = false;
                                _supplierSearchController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    if (_selectedManPowers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _selectedManPowers
                              .map(
                                (mp) => Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${mp.type}: ${mp.name}, Date: ${DateTime.now().toString().split(' ')[0]}, Day: ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][DateTime.now().weekday - 1]}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        setState(() {
                                          _selectedManPowers.removeWhere(
                                            (x) => x.id == mp.id,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Table
                    _buildTable(),
                  ],
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
                width: math.max(constraints.maxWidth, 850.0),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTableHeaderCell(
                            'Invoice No.',
                            align: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildTableHeaderCell(
                            'Shop',
                            align: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildTableHeaderCell('Bill Amount'),
                        ),
                        Expanded(flex: 2, child: _buildTableHeaderCell('Cash')),
                        Expanded(
                          flex: 2,
                          child: _buildTableHeaderCell('Credit'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildTableHeaderCell('Discount'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildTableHeaderCell('Return'),
                        ),
                      ],
                    ),
                    // Table Body
                    if (_items.isEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No pick list items found',
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    item.invoiceNumber ?? '',
                                    align: TextAlign.left,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    item.shopName,
                                    align: TextAlign.left,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    item.billAmount.toStringAsFixed(2),
                                    isNumeric: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    item.cash.toStringAsFixed(2),
                                    isNumeric: true,
                                    isEditable: true,
                                    onChanged: (value) {
                                      final cash =
                                          double.tryParse(value) ?? 0.0;
                                      final updatedItem = item.copyWith(
                                        cash: cash,
                                      );
                                      _updateItem(updatedItem);
                                    },
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    item.credit.toStringAsFixed(2),
                                    isNumeric: true,
                                    isEditable: true,
                                    onChanged: (value) {
                                      final credit =
                                          double.tryParse(value) ?? 0.0;
                                      final updatedItem = item.copyWith(
                                        credit: credit,
                                      );
                                      _updateItem(updatedItem);
                                    },
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    (item.discount).toStringAsFixed(2),
                                    isNumeric: true,
                                    isEditable: true,
                                    onChanged: (value) {
                                      final discount =
                                          double.tryParse(value) ?? 0.0;
                                      final updatedItem = item.copyWith(
                                        discount: discount,
                                      );
                                      _updateItem(updatedItem);
                                    },
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildTableCell(
                                    (item.return_).toStringAsFixed(2),
                                    isNumeric: true,
                                    isEditable: true,
                                    onChanged: (value) {
                                      final returnValue =
                                          double.tryParse(value) ?? 0.0;
                                      final updatedItem = item.copyWith(
                                        return_: returnValue,
                                      );
                                      _updateItem(updatedItem);
                                    },
                                    onFieldSubmitted: (value) {
                                      final returnValue =
                                          double.tryParse(value) ?? 0.0;
                                      final updatedItem = item.copyWith(
                                        return_: returnValue,
                                      );
                                      _updateItem(updatedItem);
                                      _handleReturn(updatedItem, returnValue);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (_items.isNotEmpty)
                      Container(
                        color: Colors.deepPurple.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.decimalPattern('en_IN').format(
                                  _items.fold(
                                    0.0,
                                    (sum, item) => sum + (item.billAmount),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.decimalPattern('en_IN').format(
                                  _items.fold(
                                    0.0,
                                    (sum, item) => sum + (item.cash),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.decimalPattern('en_IN').format(
                                  _items.fold(
                                    0.0,
                                    (sum, item) => sum + (item.credit),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.decimalPattern('en_IN').format(
                                  _items.fold(
                                    0.0,
                                    (sum, item) => sum + (item.discount),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                NumberFormat.decimalPattern('en_IN').format(
                                  _items.fold(
                                    0.0,
                                    (sum, item) => sum + (item.return_),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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

  void _showNoteDialog() {
    _noteError = null;
    _noteControllers.forEach((key, controller) => controller.text = '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double total = 0;
            _noteControllers.forEach((denom, controller) {
              final count = int.tryParse(controller.text) ?? 0;
              total += denom * count;
            });
            final cashSum = _items.fold(0.0, (sum, item) => sum + (item.cash));
            final matched = total == cashSum;
            return AlertDialog(
              title: const Text('Enter Notes Count'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._noteControllers.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: TextField(
                        controller: entry.value,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Notes of ${entry.key}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setState(() {
                            double t = 0;
                            _noteControllers.forEach((denom, c) {
                              final count = int.tryParse(c.text) ?? 0;
                              t += denom * count;
                            });
                            if (t != cashSum) {
                              _noteError = 'Values are not Matched';
                            } else {
                              _noteError = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: Rs. ${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Pick List Cash: Rs. ${cashSum.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_noteError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _noteError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: matched
                      ? () async {
                          Navigator.of(context).pop();
                          // Insert income record
                          await DatabaseHelper.instance.insertIncome({
                            'date': DateTime.now().toIso8601String().split(
                              'T',
                            )[0],
                            'category': 'Sales & Recovery',
                            'details': 'Sale',
                            'amount': cashSum,
                          });
                          await _showPickListPrintPreview();

                          // Save to history
                          final notes = <String, String>{};
                          _noteControllers.forEach((key, value) {
                            if (value.text.isNotEmpty) {
                              notes[key.toString()] = value.text;
                            }
                          });
                          final historyData = {
                            'items': _items.map((e) => e.toMap()).toList(),
                            'manpower': _selectedManPowers
                                .map((e) => e.toMap())
                                .toList(),
                            'notes': notes,
                            'date': DateTime.now().toIso8601String(),
                          };
                          await DatabaseHelper.instance.addPickListHistory(
                            DateTime.now().toIso8601String().split('T')[0],
                            jsonEncode(historyData),
                          );

                          // Clear form
                          await DatabaseHelper.instance.clearPickList();
                          if (mounted) {
                            setState(() {
                              _items.clear();
                              _selectedManPowers.clear();
                              _noteControllers.forEach(
                                (key, value) => value.clear(),
                              );
                            });
                          }
                          await _loadItems(); // Refresh the list

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pick List saved to history and form cleared.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPickListPrintPreview() async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );

    final numberFormat = NumberFormat('#,##0', 'en_US');
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');

    // Calculate totals
    final double totalBillAmount = _items.fold(
      0.0,
      (sum, item) => sum + item.billAmount,
    );
    final double totalCash = _items.fold(0.0, (sum, item) => sum + item.cash);
    final double totalCredit = _items.fold(
      0.0,
      (sum, item) => sum + item.credit,
    );
    final double totalDiscount = _items.fold(
      0.0,
      (sum, item) => sum + item.discount,
    );
    final double totalReturn = _items.fold(
      0.0,
      (sum, item) => sum + item.return_,
    );

    String formatNumber(num value) {
      if (value % 1 == 0) {
        return numberFormat.format(value);
      } else {
        return moneyFormat.format(value);
      }
    }

    final String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final String day = DateFormat('EEEE').format(DateTime.now());

    final supplier = _selectedManPowers
        .where((mp) => mp.type == 'Supplier')
        .map((mp) => mp.name)
        .join(', ');
    final orderBooker = _selectedManPowers
        .where((mp) => mp.type == 'Order Booker')
        .map((mp) => mp.name)
        .join(', ');

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
                pw.SizedBox(width: 10), // For spacing
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
                    _buildInfoRow('Date:', date),
                    _buildInfoRow('Day:', day),
                    _buildInfoRow('Total Cash:', formatNumber(totalCash)),
                    _buildInfoRow('Total Return:', formatNumber(totalReturn)),
                    _buildInfoRow('Total Pages:', '1'), // Placeholder
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
              data: _items
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
      name: 'PickList_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

  Future<void> _handleReturn(PickListItem item, double returnValue) async {
    if (returnValue <= 0) return;

    // Get the invoice details
    final invoice = await DatabaseHelper.instance.getInvoiceByNumber(
      item.invoiceNumber ?? '',
    );
    if (invoice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final List<Map<String, dynamic>> invoiceItems =
          List<Map<String, dynamic>>.from(
            (jsonDecode(invoice['items'] as String) as List)
                .map(
                  (item) => {
                    'brandName': item['description'] as String,
                    'units': item['unit'] as int,
                    'rate': item['rate'] as double,
                  },
                )
                .toList(),
          );

      final total = invoice['total'] as double;

      if ((returnValue - total).abs() < 0.01) {
        // Using abs() to handle floating point comparison
        // Full return - store all products as pending returns
        for (final invoiceItem in invoiceItems) {
          _pendingReturns.add({
            'brandName': invoiceItem['brandName'],
            'units': invoiceItem['units'],
          });
        }
        // Show the invoice
        if (mounted) {
          final returnedProducts = invoiceItems
              .map((item) => {...item, 'units': item['units']})
              .toList();
          _showInvoiceDialog(
            invoice,
            isFullReturn: true,
            returnedProducts: returnedProducts,
          );
        }
      } else {
        // Partial return - show product selection dialog
        if (mounted) {
          await _showReturnProductDialog(invoice, returnValue);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing return: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReturnProductDialog(
    Map<String, dynamic> invoice,
    double returnValue,
  ) async {
    final List<Map<String, dynamic>> invoiceItems =
        List<Map<String, dynamic>>.from(
          (jsonDecode(invoice['items'] as String) as List)
              .map(
                (item) => {
                  'brandName': item['description'] as String,
                  'units': item['unit'] as int,
                  'rate': item['rate'] as double,
                  'maxUnits':
                      item['unit'] as int, // Store original units as max limit
                },
              )
              .toList(),
        );

    final selectedProducts = <Map<String, dynamic>>[];
    final unitControllers = <int, TextEditingController>{};
    double remainingReturnValue = returnValue;

    for (var i = 0; i < invoiceItems.length; i++) {
      unitControllers[i] = TextEditingController();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Products to Return'),
              content: SizedBox(
                width: 800, // Increased width for better visibility
                height: 600, // Fixed height for better visibility
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Return Amount: Rs. ${returnValue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Remaining: Rs. ${remainingReturnValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: remainingReturnValue < 0
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Select')),
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Original Units')),
                            DataColumn(label: Text('Rate')),
                            DataColumn(label: Text('Return Units')),
                            DataColumn(label: Text('Return Value')),
                            DataColumn(label: Text('Max Return Value')),
                          ],
                          rows: List<DataRow>.generate(invoiceItems.length, (
                            index,
                          ) {
                            final item = invoiceItems[index];
                            final controller = unitControllers[index]!;
                            final isSelected = selectedProducts.contains(item);
                            final returnUnits =
                                int.tryParse(controller.text) ?? 0;
                            final returnValue =
                                returnUnits * (item['rate'] as double);
                            final maxReturnValue =
                                (item['maxUnits'] as int) *
                                (item['rate'] as double);

                            return DataRow(
                              cells: [
                                DataCell(
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedProducts.add(item);
                                        } else {
                                          selectedProducts.remove(item);
                                          controller.clear();
                                          _recalculateRemainingValue(
                                            returnValue,
                                            selectedProducts,
                                            unitControllers,
                                            invoiceItems,
                                            (value) =>
                                                remainingReturnValue = value,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                                DataCell(Text(item['brandName'] as String)),
                                DataCell(
                                  Text((item['maxUnits'] as int).toString()),
                                ),
                                DataCell(
                                  Text((item['rate'] as double).toString()),
                                ),
                                DataCell(
                                  isSelected
                                      ? TextField(
                                          controller: controller,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                          ),
                                          onChanged: (value) {
                                            final units =
                                                int.tryParse(value) ?? 0;
                                            if (units >
                                                (item['maxUnits'] as int)) {
                                              controller.text = item['maxUnits']
                                                  .toString();
                                            }
                                            setState(() {
                                              _recalculateRemainingValue(
                                                returnValue,
                                                selectedProducts,
                                                unitControllers,
                                                invoiceItems,
                                                (value) =>
                                                    remainingReturnValue =
                                                        value,
                                              );
                                            });
                                          },
                                        )
                                      : const Text(''),
                                ),
                                DataCell(
                                  Text(
                                    isSelected && returnUnits > 0
                                        ? returnValue.toStringAsFixed(2)
                                        : '',
                                  ),
                                ),
                                DataCell(
                                  Text(maxReturnValue.toStringAsFixed(2)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedProducts.isNotEmpty &&
                          selectedProducts.any((item) {
                            final idx = invoiceItems.indexOf(item);
                            final units =
                                int.tryParse(unitControllers[idx]!.text) ?? 0;
                            return units > 0;
                          })
                      ? () async {
                          // Store selected products as pending returns
                          for (var i = 0; i < invoiceItems.length; i++) {
                            final item = invoiceItems[i];
                            if (selectedProducts.contains(item)) {
                              final returnUnits =
                                  int.tryParse(unitControllers[i]!.text) ?? 0;
                              if (returnUnits > 0) {
                                _pendingReturns.add({
                                  'brandName': item['brandName'],
                                  'units': returnUnits,
                                });
                              }
                            }
                          }
                          if (mounted) {
                            // Build returnedProducts list
                            final returnedProducts = <Map<String, dynamic>>[];
                            for (var i = 0; i < invoiceItems.length; i++) {
                              if (selectedProducts.contains(invoiceItems[i])) {
                                final returnUnits =
                                    int.tryParse(unitControllers[i]!.text) ?? 0;
                                if (returnUnits > 0) {
                                  returnedProducts.add({
                                    ...invoiceItems[i],
                                    'units': returnUnits,
                                  });
                                }
                              }
                            }
                            Navigator.of(context).pop();
                            _showInvoiceDialog(
                              invoice,
                              isFullReturn: false,
                              returnedProducts: returnedProducts,
                            );
                          }
                        }
                      : null,
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recalculateRemainingValue(
    double totalReturnValue,
    List<Map<String, dynamic>> selectedProducts,
    Map<int, TextEditingController> unitControllers,
    List<Map<String, dynamic>> invoiceItems,
    Function(double) updateRemaining,
  ) {
    double currentTotal = 0;
    for (var i = 0; i < invoiceItems.length; i++) {
      if (selectedProducts.contains(invoiceItems[i])) {
        final returnUnits = int.tryParse(unitControllers[i]!.text) ?? 0;
        currentTotal += returnUnits * (invoiceItems[i]['rate'] as double);
      }
    }
    updateRemaining(totalReturnValue - currentTotal);
  }

  Future<void> _showInvoiceDialog(
    Map<String, dynamic> invoice, {
    required bool isFullReturn,
    List<Map<String, dynamic>>? returnedProducts,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isFullReturn
                ? 'Full Return - Invoice Details'
                : 'Partial Return - Invoice Details',
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Invoice #: ${invoice['invoiceNumber']}'),
                  Text('Shop: ${invoice['shopName']}'),
                  Text('Date: ${invoice['date']}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Products:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...((returnedProducts ??
                          List<Map<String, dynamic>>.from(
                            jsonDecode(invoice['items'] as String),
                          ))
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${item['brandName']} - ${item['units']} units @ Rs.${item['rate']}',
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                  Text('Total: Rs.${invoice['total']}'),
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
  }
}

class PickListItem {
  final int? id;
  final String code;
  final String shopName;
  final String ownerName;
  final double billAmount;
  final double recovery;
  final double discount;
  final double return_;
  final double cash;
  final double credit;
  final String? invoiceNumber;

  PickListItem({
    this.id,
    required this.code,
    required this.shopName,
    required this.ownerName,
    required this.billAmount,
    required this.recovery,
    required this.discount,
    required this.return_,
    required this.cash,
    required this.credit,
    this.invoiceNumber,
  });

  factory PickListItem.fromMap(Map<String, dynamic> map) {
    return PickListItem(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      billAmount: (map['billAmount'] as num?)?.toDouble() ?? 0.0,
      recovery: (map['recovery'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      return_: (map['return'] as num?)?.toDouble() ?? 0.0,
      cash: (map['cash'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      invoiceNumber: map['invoiceNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'shopName': shopName,
      'ownerName': ownerName,
      'billAmount': billAmount,
      'recovery': recovery,
      'discount': discount,
      'return': return_,
      'cash': cash,
      'credit': credit,
      'invoiceNumber': invoiceNumber,
    };
  }

  PickListItem copyWith({
    int? id,
    String? code,
    String? shopName,
    String? ownerName,
    double? billAmount,
    double? recovery,
    double? discount,
    double? return_,
    double? cash,
    double? credit,
    String? invoiceNumber,
  }) {
    return PickListItem(
      id: id ?? this.id,
      code: code ?? this.code,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      billAmount: billAmount ?? this.billAmount,
      recovery: recovery ?? this.recovery,
      discount: discount ?? this.discount,
      return_: return_ ?? this.return_,
      cash: cash ?? this.cash,
      credit: credit ?? this.credit,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }
}
