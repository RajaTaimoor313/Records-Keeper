import 'package:flutter/material.dart';
import 'dart:math' as math;

class RealisationTab extends StatefulWidget {
  const RealisationTab({super.key});

  @override
  State<RealisationTab> createState() => _RealisationTabState();
}

class _RealisationTabState extends State<RealisationTab> {
  bool _isLoading = true;
  List<RealisationItem> _items = [];
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
    setState(() {
      _items = [];
      _isLoading = false;
    });
  }

  Future<void> _updateItem(RealisationItem item) async {
    setState(() {
      final idx = _items.indexWhere((e) => e.shopCode == item.shopCode);
      if (idx != -1) _items[idx] = item;
    });
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

  Widget _buildEditableCell(
    RealisationItem item,
    String value,
    String field, {
    TextAlign align = TextAlign.center,
  }) {
    final bool isEditable = field == 'realisation' || field == 'discount';
    return Container(
      height: 44,
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
                initialValue: value,
                textAlign: align,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
                keyboardType: TextInputType.number,
                onChanged: (newValue) {
                  final updatedItem = item.copyWith(
                    realisation: field == 'realisation' ? int.tryParse(newValue) ?? 0 : item.realisation,
                    discount: field == 'discount' ? int.tryParse(newValue) ?? 0 : item.discount,
                  );
                  _updateItem(updatedItem);
                },
              ),
            )
          : Center(
              child: Text(
                value,
                textAlign: align,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
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
                width: math.max(constraints.maxWidth, 700.0),
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
                          Expanded(flex: 2, child: _buildTableHeaderCell('Shop Code')),
                          Expanded(flex: 3, child: _buildTableHeaderCell('Shop Name')),
                          Expanded(flex: 4, child: _buildTableHeaderCell('Address')),
                          Expanded(flex: 2, child: _buildTableHeaderCell('Realisation')),
                          Expanded(flex: 2, child: _buildTableHeaderCell('Discount')),
                        ],
                      ),
                    ),
                    // Table Body
                    if (_items.isEmpty)
                      Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: const Text('No data available'),
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
                                Expanded(flex: 2, child: _buildEditableCell(item, item.shopCode, 'shopCode')),
                                Expanded(flex: 3, child: _buildEditableCell(item, item.shopName, 'shopName')),
                                Expanded(flex: 4, child: _buildEditableCell(item, item.address, 'address')),
                                Expanded(flex: 2, child: _buildEditableCell(item, item.realisation.toString(), 'realisation')),
                                Expanded(flex: 2, child: _buildEditableCell(item, item.discount.toString(), 'discount')),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTable(),
    );
  }
}

class RealisationItem {
  final String shopCode;
  final String shopName;
  final String address;
  final int realisation;
  final int discount;

  RealisationItem({
    required this.shopCode,
    required this.shopName,
    required this.address,
    required this.realisation,
    required this.discount,
  });

  RealisationItem copyWith({
    String? shopCode,
    String? shopName,
    String? address,
    int? realisation,
    int? discount,
  }) {
    return RealisationItem(
      shopCode: shopCode ?? this.shopCode,
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      realisation: realisation ?? this.realisation,
      discount: discount ?? this.discount,
    );
  }
} 