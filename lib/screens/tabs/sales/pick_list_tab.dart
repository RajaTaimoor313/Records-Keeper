import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../database_helper.dart';

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

  Widget _buildTableHeaderCell(String text, {TextAlign align = TextAlign.center}) {
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
    String value,
    {TextAlign align = TextAlign.center,
    bool isNumeric = false,
    bool isEditable = false,
    bool isPaymentType = false,
    Function(String)? onChanged,
    String? hintText}
  ) {
    // For Recovery field, show empty string if value is "0.00"
    final displayValue = (isNumeric && double.tryParse(value) == 0) ? '' : value;

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
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
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
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
                onChanged: onChanged,
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
              ? Border(
                  left: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                )
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
                                  onPressed: () {},
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
                  // Table
                  Expanded(
                    child: _buildTable(),
                  ),
                ],
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
                        Expanded(flex: 1, child: _buildTableHeaderCell('No.')),
                        Expanded(flex: 2, child: _buildTableHeaderCell('Code', align: TextAlign.left)),
                        Expanded(flex: 3, child: _buildTableHeaderCell('Shop', align: TextAlign.left)),
                        Expanded(flex: 3, child: _buildTableHeaderCell('Owner Name', align: TextAlign.left)),
                        Expanded(flex: 2, child: _buildTableHeaderCell('Bill Amount')),
                        Expanded(flex: 2, child: _buildTableHeaderCell('Cash/Credit')),
                        Expanded(flex: 2, child: _buildTableHeaderCell('Recovery')),
                      ],
                    ),
                    // Table Body
                    if (_items.isEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
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
                      Expanded(
                        child: ListView.builder(
                          controller: _verticalScrollController,
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: index.isEven ? Colors.white : Colors.grey.shade50,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildTableCell(
                                      (index + 1).toString(),
                                      isNumeric: true,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildTableCell(
                                      item.code,
                                      align: TextAlign.left,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildTableCell(
                                      item.shopName,
                                      align: TextAlign.left,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildTableCell(
                                      item.ownerName,
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
                                      item.paymentType,
                                      isEditable: true,
                                      isPaymentType: true,
                                      onChanged: (value) {
                                        final updatedItem = item.copyWith(paymentType: value);
                                        _updateItem(updatedItem);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _buildTableCell(
                                      item.recovery.toStringAsFixed(2),
                                      isNumeric: true,
                                      isEditable: true,
                                      onChanged: (value) {
                                        final recovery = double.tryParse(value) ?? 0.0;
                                        final updatedItem = item.copyWith(recovery: recovery);
                                        _updateItem(updatedItem);
                                      },
                                    ),
                                  ),
                                ],
                              ),
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
}

class PickListItem {
  final int? id;
  final String code;
  final String shopName;
  final String ownerName;
  final double billAmount;
  final String paymentType;
  final double recovery;

  PickListItem({
    this.id,
    required this.code,
    required this.shopName,
    required this.ownerName,
    required this.billAmount,
    required this.paymentType,
    required this.recovery,
  });

  factory PickListItem.fromMap(Map<String, dynamic> map) {
    return PickListItem(
      id: map['id'] as int?,
      code: map['code'] as String,
      shopName: map['shopName'] as String,
      ownerName: map['ownerName'] as String,
      billAmount: map['billAmount'] as double,
      paymentType: map['paymentType'] as String? ?? '',
      recovery: map['recovery'] as double? ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'shopName': shopName,
      'ownerName': ownerName,
      'billAmount': billAmount,
      'paymentType': paymentType,
      'recovery': recovery,
    };
  }

  PickListItem copyWith({
    int? id,
    String? code,
    String? shopName,
    String? ownerName,
    double? billAmount,
    String? paymentType,
    double? recovery,
  }) {
    return PickListItem(
      id: id ?? this.id,
      code: code ?? this.code,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      billAmount: billAmount ?? this.billAmount,
      paymentType: paymentType ?? this.paymentType,
      recovery: recovery ?? this.recovery,
    );
  }
} 