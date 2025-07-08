import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:records_keeper/database_helper.dart';

class Product {
  final String id;
  final String company;
  final String brand;
  final String brandCategory;
  final double ctnRate;
  final double boxRate;
  final double salePrice;
  final int ctnPacking;
  final int boxPacking;
  final int unitsPacking;

  Product({
    required this.id,
    required this.company,
    required this.brand,
    required this.brandCategory,
    required this.ctnRate,
    required this.boxRate,
    required this.salePrice,
    required this.ctnPacking,
    required this.boxPacking,
    required this.unitsPacking,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'brand': brand,
      'brandCategory': brandCategory,
      'ctnRate': ctnRate,
      'boxRate': boxRate,
      'salePrice': salePrice,
      'ctnPacking': ctnPacking,
      'boxPacking': boxPacking,
      'unitsPacking': unitsPacking,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      company: map['company'],
      brand: map['brand'],
      brandCategory: map['brandCategory'] ?? '',
      ctnRate: map['ctnRate'],
      boxRate: map['boxRate'],
      salePrice: map['salePrice'],
      ctnPacking: map['ctnPacking'],
      boxPacking: map['boxPacking'],
      unitsPacking: map['unitsPacking'],
    );
  }
}

class StockReportTab extends StatefulWidget {
  const StockReportTab({super.key});

  @override
  State<StockReportTab> createState() => _StockReportTabState();
}

class _StockReportTabState extends State<StockReportTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productIdController = TextEditingController();
  late TextEditingController _searchController;

  // Opening Stock Controllers
  final TextEditingController _openingStockCtnController =
      TextEditingController();
  final TextEditingController _openingStockUnitsController =
      TextEditingController();
  final TextEditingController _openingStockTotalController =
      TextEditingController();
  final TextEditingController _openingStockValueController =
      TextEditingController();

  // Received Stock Controllers
  final TextEditingController _receivedStockCtnController =
      TextEditingController();
  final TextEditingController _receivedStockUnitsController =
      TextEditingController();
  final TextEditingController _receivedStockTotalController =
      TextEditingController();
  final TextEditingController _receivedStockValueController =
      TextEditingController();

  // Total Stock Controllers
  final TextEditingController _totalStockCtnController =
      TextEditingController();
  final TextEditingController _totalStockUnitsController =
      TextEditingController();
  final TextEditingController _totalStockTotalController =
      TextEditingController();
  final TextEditingController _totalStockValueController =
      TextEditingController();

  // Closing Stock Controllers
  final TextEditingController _closingStockCtnController =
      TextEditingController();
  final TextEditingController _closingStockUnitsController =
      TextEditingController();
  final TextEditingController _closingStockTotalController =
      TextEditingController();
  final TextEditingController _closingStockValueController =
      TextEditingController();

  // Sale Controllers
  final TextEditingController _saleCtnController = TextEditingController();
  final TextEditingController _saleUnitsController = TextEditingController();
  final TextEditingController _saleTotalController = TextEditingController();
  final TextEditingController _saleValueController = TextEditingController();

  final TextEditingController _brandCategoryController = TextEditingController();

  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _openingStockCtnController.dispose();
    _openingStockUnitsController.dispose();
    _openingStockTotalController.dispose();
    _openingStockValueController.dispose();
    _receivedStockCtnController.dispose();
    _receivedStockUnitsController.dispose();
    _receivedStockTotalController.dispose();
    _receivedStockValueController.dispose();
    _totalStockCtnController.dispose();
    _totalStockUnitsController.dispose();
    _totalStockTotalController.dispose();
    _totalStockValueController.dispose();
    _closingStockCtnController.dispose();
    _closingStockUnitsController.dispose();
    _closingStockTotalController.dispose();
    _closingStockValueController.dispose();
    _saleCtnController.dispose();
    _saleUnitsController.dispose();
    _saleTotalController.dispose();
    _saleValueController.dispose();
    _brandCategoryController.dispose();
    super.dispose();
  }

  void _resetStockFields() {
    _openingStockCtnController.clear();
    _openingStockUnitsController.clear();
    _openingStockTotalController.clear();
    _openingStockValueController.clear();
    _receivedStockCtnController.clear();
    _receivedStockUnitsController.clear();
    _receivedStockTotalController.clear();
    _receivedStockValueController.clear();
    _totalStockCtnController.clear();
    _totalStockUnitsController.clear();
    _totalStockTotalController.clear();
    _totalStockValueController.clear();
    _closingStockCtnController.clear();
    _closingStockUnitsController.clear();
    _closingStockTotalController.clear();
    _closingStockValueController.clear();
    _saleCtnController.text = '0';
    _saleUnitsController.text = '0';
    _saleTotalController.text = '0.00';
    _saleValueController.text = '0.00';
  }

  Future<void> _loadLatestStockRecord(String productId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final records = await db.query(
        'stock_records',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'date DESC',
        limit: 1,
      );

      if (records.isNotEmpty) {
        final record = records.first;
        setState(() {
          // Load Opening Stock
          _openingStockCtnController.text = record['opening_stock_ctn']
              .toString();
          _openingStockUnitsController.text = record['opening_stock_units']
              .toString();
          _openingStockTotalController.text = record['opening_stock_total']
              .toString();
          _openingStockValueController.text = record['opening_stock_value']
              .toString();

          // Load Received Stock
          _receivedStockCtnController.text = record['received_ctn'].toString();
          _receivedStockUnitsController.text = record['received_units']
              .toString();
          _receivedStockTotalController.text = record['received_total']
              .toString();
          _receivedStockValueController.text = record['received_value']
              .toString();

          // Load Total Stock
          _totalStockCtnController.text = record['total_stock_ctn'].toString();
          _totalStockUnitsController.text = record['total_stock_units']
              .toString();
          _totalStockTotalController.text = record['total_stock_total']
              .toString();
          _totalStockValueController.text = record['total_stock_value']
              .toString();

          // Load Closing Stock
          _closingStockCtnController.text = record['closing_stock_ctn']
              .toString();
          _closingStockUnitsController.text = record['closing_stock_units']
              .toString();
          _closingStockTotalController.text = record['closing_stock_total']
              .toString();
          _closingStockValueController.text = record['closing_stock_value']
              .toString();

          // Load Sale
          _saleCtnController.text = record['sale_ctn'].toString();
          _saleUnitsController.text = record['sale_units'].toString();
          _saleTotalController.text = record['sale_total'].toString();
          _saleValueController.text = record['sale_value'].toString();
        });
      } else {
        _resetStockFields();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stock record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _resetStockFields();
    }
  }

  void _calculateOpeningStock() {
    if (_selectedProduct == null) return;

    final ctn = int.tryParse(_openingStockCtnController.text) ?? 0;
    final units = int.tryParse(_openingStockUnitsController.text) ?? 0;

    // Calculate total boxes
    final totalUnits = (ctn * _selectedProduct!.boxPacking) + units;
    _openingStockTotalController.text = totalUnits.toString();

    // Calculate value: Total × Box Invoice Rate
    final value = totalUnits * _selectedProduct!.boxRate;
    _openingStockValueController.text = value.toStringAsFixed(2);

    // Recalculate total stock when opening stock changes
    _calculateTotalStock();
  }

  void _calculateReceivedStock() {
    if (_selectedProduct == null) return;

    final ctn = int.tryParse(_receivedStockCtnController.text) ?? 0;
    final units = int.tryParse(_receivedStockUnitsController.text) ?? 0;

    // Calculate total boxes
    final totalUnits = (ctn * _selectedProduct!.boxPacking) + units;
    _receivedStockTotalController.text = totalUnits.toString();

    // Calculate value: Total × Box Invoice Rate
    final value = totalUnits * _selectedProduct!.boxRate;
    _receivedStockValueController.text = value.toStringAsFixed(2);

    // Recalculate total stock when received stock changes
    _calculateTotalStock();
  }

  void _calculateTotalStock() {
    if (_selectedProduct == null) return;

    // Get opening stock values
    final openingCtn = int.tryParse(_openingStockCtnController.text) ?? 0;
    final openingUnits = int.tryParse(_openingStockUnitsController.text) ?? 0;
    final openingStockTotal =
        double.tryParse(_openingStockTotalController.text) ?? 0;
    final openingStockValue =
        double.tryParse(_openingStockValueController.text) ?? 0;

    // Get received stock values
    final receivedCtn = int.tryParse(_receivedStockCtnController.text) ?? 0;
    final receivedUnits = int.tryParse(_receivedStockUnitsController.text) ?? 0;
    final receivedStockTotal =
        double.tryParse(_receivedStockTotalController.text) ?? 0;
    final receivedStockValue =
        double.tryParse(_receivedStockValueController.text) ?? 0;

    // Calculate total CTN and Boxes
    final totalCtn = openingCtn + receivedCtn;
    final totalUnits = openingUnits + receivedUnits;

    // Calculate total and value
    final totalStockTotal = openingStockTotal + receivedStockTotal;
    final totalStockValue = openingStockValue + receivedStockValue;

    // Update CTN and Boxes fields
    _totalStockCtnController.text = totalCtn.toString();
    _totalStockUnitsController.text = totalUnits.toString();

    // Update Total and Value fields
    _totalStockTotalController.text = totalStockTotal.toStringAsFixed(2);
    _totalStockValueController.text = totalStockValue.toStringAsFixed(2);

    // Recalculate sale when total stock changes
    _onSaleChanged();
  }

  void _onSaleChanged() {
    if (_selectedProduct == null) return;

    // Get Total Stock values
    final totalStockCtn = int.tryParse(_totalStockCtnController.text) ?? 0;
    final totalStockUnits = int.tryParse(_totalStockUnitsController.text) ?? 0;
    final totalStockTotal =
        double.tryParse(_totalStockTotalController.text) ?? 0;
    final totalStockValue =
        double.tryParse(_totalStockValueController.text) ?? 0;

    // Get Sale CTN and Boxes from user input
    final saleCtn = int.tryParse(_saleCtnController.text) ?? 0;
    final saleUnits = int.tryParse(_saleUnitsController.text) ?? 0;

    // Calculate Sale Total and Value
    final saleTotal = (saleCtn * _selectedProduct!.boxPacking) + saleUnits;
    _saleTotalController.text = saleTotal.toStringAsFixed(2);
    // Calculate value: Total × Box Invoice Rate
    final saleValue = saleTotal * _selectedProduct!.boxRate;
    _saleValueController.text = saleValue.toStringAsFixed(2);

    // Calculate Closing Stock
    _closingStockCtnController.text = (totalStockCtn - saleCtn).toString();
    _closingStockUnitsController.text = (totalStockUnits - saleUnits)
        .toString();
    _closingStockTotalController.text = (totalStockTotal - saleTotal)
        .toStringAsFixed(2);
    _closingStockValueController.text = (totalStockValue - saleValue)
        .toStringAsFixed(2);
  }

  Future<void> _saveStockRecord() async {
    if (_selectedProduct == null) return;

    try {
      final db = await DatabaseHelper.instance.database;

      // Prepare the record
      final record = {
        'product_id': _selectedProduct!.id,
        'date': DateTime.now().toIso8601String(),
        'opening_stock_ctn': int.tryParse(_openingStockCtnController.text) ?? 0,
        'opening_stock_units':
            int.tryParse(_openingStockUnitsController.text) ?? 0,
        'opening_stock_total':
            double.tryParse(_openingStockTotalController.text) ?? 0,
        'opening_stock_value':
            double.tryParse(_openingStockValueController.text) ?? 0,
        'received_ctn': int.tryParse(_receivedStockCtnController.text) ?? 0,
        'received_units': int.tryParse(_receivedStockUnitsController.text) ?? 0,
        'received_total':
            double.tryParse(_receivedStockTotalController.text) ?? 0,
        'received_value':
            double.tryParse(_receivedStockValueController.text) ?? 0,
        'total_stock_ctn': int.tryParse(_totalStockCtnController.text) ?? 0,
        'total_stock_units': int.tryParse(_totalStockUnitsController.text) ?? 0,
        'total_stock_total':
            double.tryParse(_totalStockTotalController.text) ?? 0,
        'total_stock_value':
            double.tryParse(_totalStockValueController.text) ?? 0,
        'closing_stock_ctn': int.tryParse(_closingStockCtnController.text) ?? 0,
        'closing_stock_units':
            int.tryParse(_closingStockUnitsController.text) ?? 0,
        'closing_stock_total':
            double.tryParse(_closingStockTotalController.text) ?? 0,
        'closing_stock_value':
            double.tryParse(_closingStockValueController.text) ?? 0,
        'sale_ctn': int.tryParse(_saleCtnController.text) ?? 0,
        'sale_units': int.tryParse(_saleUnitsController.text) ?? 0,
        'sale_total': double.tryParse(_saleTotalController.text) ?? 0,
        'sale_value': double.tryParse(_saleValueController.text) ?? 0,
      };

      // Insert the record
      await db.insert('stock_records', record);

      // If new stock is received, reset available_stock for this product
      if ((double.tryParse(_receivedStockTotalController.text) ?? 0) > 0 &&
          _selectedProduct != null) {
        await DatabaseHelper.instance.setAvailableStock(
          _selectedProduct!.id,
          double.tryParse(_totalStockTotalController.text) ?? 0,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset the form
      _resetStockFields();
      _searchController.clear();
      setState(() {
        _selectedProduct = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving stock record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      _productIdController.text = product.id;
    });
    _loadLatestStockRecord(product.id);
  }

  Widget _buildStockCategory(String title, {bool isEditable = false}) {
    // Determine which controllers to use based on the category
    late TextEditingController ctnController;
    late TextEditingController unitsController;
    late TextEditingController totalController;
    late TextEditingController valueController;
    void Function()? onChanged;

    switch (title) {
      case 'Opening Stock':
        ctnController = _openingStockCtnController;
        unitsController = _openingStockUnitsController;
        totalController = _openingStockTotalController;
        valueController = _openingStockValueController;
        onChanged = _calculateOpeningStock;
        break;
      case 'Received':
        ctnController = _receivedStockCtnController;
        unitsController = _receivedStockUnitsController;
        totalController = _receivedStockTotalController;
        valueController = _receivedStockValueController;
        onChanged = _calculateReceivedStock;
        isEditable = true;
        break;
      case 'Total Stock':
        ctnController = _totalStockCtnController;
        unitsController = _totalStockUnitsController;
        totalController = _totalStockTotalController;
        valueController = _totalStockValueController;
        isEditable = false;
        break;
      case 'Closing Stock':
        ctnController = _closingStockCtnController;
        unitsController = _closingStockUnitsController;
        totalController = _closingStockTotalController;
        valueController = _closingStockValueController;
        isEditable = false;
        break;
      case 'Sale':
        ctnController = _saleCtnController;
        unitsController = _saleUnitsController;
        totalController = _saleTotalController;
        valueController = _saleValueController;
        onChanged = _onSaleChanged;
        isEditable = true;
        break;
      default:
        ctnController = TextEditingController();
        unitsController = TextEditingController();
        totalController = TextEditingController();
        valueController = TextEditingController();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ctnController,
                    enabled: isEditable && _selectedProduct != null,
                    decoration: InputDecoration(
                      labelText: 'CTN',
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onChanged?.call(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: unitsController,
                    enabled: isEditable && _selectedProduct != null,
                    decoration: InputDecoration(
                      labelText: 'Box',
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onChanged?.call(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: totalController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Total',
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: valueController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Value',
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Add Stock',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),

              // Product Search
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const [];
                  }

                  final db = await DatabaseHelper.instance.database;
                  final searchTerm = textEditingValue.text.toUpperCase();

                  final results = await db.query(
                    'products',
                    where: 'id LIKE ? OR company LIKE ? OR brand LIKE ?',
                    whereArgs: [
                      '%$searchTerm%',
                      '%$searchTerm%',
                      '%$searchTerm%',
                    ],
                  );

                  return results.map((map) => Product.fromMap(map)).toList();
                },
                displayStringForOption: (Product product) {
                  return '${product.company} - ${product.brand}';
                },
                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController controller,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      if (_searchController != controller) {
                        _searchController = controller;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Search Product',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      );
                    },
                onSelected: _onProductSelected,
                optionsViewBuilder:
                    (
                      BuildContext context,
                      AutocompleteOnSelected<Product> onSelected,
                      Iterable<Product> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            width: MediaQuery.of(context).size.width - 64,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Product product = options.elementAt(
                                  index,
                                );
                                return ListTile(
                                  title: Text(
                                    '${product.company} - ${product.brand}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Box Rate: Rs. ${product.boxRate.toStringAsFixed(2)} | Trade Rate: Rs. ${product.salePrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onTap: () {
                                    onSelected(product);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
              ),
              const SizedBox(height: 24),

              // Product Details
              if (_selectedProduct != null) ...[
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trade Rate: Rs. ${_selectedProduct!.salePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Company: ${_selectedProduct!.company}'),
                                  const SizedBox(height: 4),
                                  Text('Brand: ${_selectedProduct!.brand}'),
                                  const SizedBox(height: 4),
                                  Text('Brand Category: ${_selectedProduct!.brandCategory}'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Invoice Rate:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'CTN Rate: ${_selectedProduct!.ctnRate}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Box Rate: ${_selectedProduct!.boxRate}',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Packing:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('CTN: ${_selectedProduct!.ctnPacking}'),
                                  const SizedBox(height: 4),
                                  Text('Box: ${_selectedProduct!.boxPacking}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Box: ${_selectedProduct!.unitsPacking}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Stock Categories
                _buildStockCategory('Opening Stock', isEditable: true),
                _buildStockCategory('Received'),
                _buildStockCategory('Total Stock'),
                _buildStockCategory('Closing Stock'),
                _buildStockCategory('Sale'),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _selectedProduct != null
                        ? _saveStockRecord
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
