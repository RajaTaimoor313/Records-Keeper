import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:records_keeper/database_helper.dart';

class Product {
  final String id;
  final String company;
  final String brand;
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
      'ctnRate': ctnRate,
      'boxRate': boxRate,
      'salePrice': salePrice,
      'ctnPacking': ctnPacking,
      'boxPacking': boxPacking,
      'unitsPacking': unitsPacking,
    };
  }
}

class StockTab extends StatefulWidget {
  const StockTab({super.key});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  final _formKey = GlobalKey<FormState>();
  bool showForm = true;
  final TextEditingController searchController = TextEditingController();
  String? sortBy;
  bool isAscending = true;
  bool isLoading = true;
  List<Product> productRecords = [];
  List<Product> filteredRecords = [];

  // Form controllers
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _ctnRateController = TextEditingController();
  final TextEditingController _boxRateController = TextEditingController();
  final TextEditingController _ctnPackingController = TextEditingController();
  final TextEditingController _boxPackingController = TextEditingController();
  final TextEditingController _unitsPackingController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();

  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _ctnRateController.dispose();
    _boxRateController.dispose();
    _ctnPackingController.dispose();
    _boxPackingController.dispose();
    _unitsPackingController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final records = await DatabaseHelper.instance.getProducts();
      if (!mounted) return;
      setState(() {
        productRecords = records
            .map(
              (record) => Product(
                id: record['id'] as String,
                company: record['company'] as String,
                brand: record['brand'] as String,
                ctnRate: record['ctnRate'] as double,
                boxRate: record['boxRate'] as double,
                salePrice: record['salePrice'] as double,
                ctnPacking: record['ctnPacking'] as int,
                boxPacking: record['boxPacking'] as int,
                unitsPacking: record['unitsPacking'] as int,
              ),
            )
            .toList();
        filteredRecords = List.from(productRecords);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _resetForm() {
    _companyController.clear();
    _brandController.clear();
    _ctnRateController.clear();
    _boxRateController.clear();
    _salePriceController.clear();
    _ctnPackingController.clear();
    _boxPackingController.clear();
    _unitsPackingController.clear();
    _formKey.currentState?.reset();
  }

  void _calculateBoxRate() {
    if (_ctnRateController.text.isNotEmpty && _boxPackingController.text.isNotEmpty) {
      try {
        final ctnRate = double.parse(_ctnRateController.text);
        final boxPacking = int.parse(_boxPackingController.text);
        if (boxPacking > 0) {
          final boxRate = ctnRate / boxPacking;
          _boxRateController.text = boxRate.toStringAsFixed(2);
        }
      } catch (e) {
        _boxRateController.clear();
      }
    } else {
      _boxRateController.clear();
    }
  }

  String _generateProductId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String id;
    do {
      id = List.generate(5, (index) => chars[random.nextInt(chars.length)]).join();
    } while (productRecords.any((product) => product.id == id));
    return id;
  }

  void _populateForm(Product product) {
    _companyController.text = product.company;
    _brandController.text = product.brand;
    _ctnRateController.text = product.ctnRate.toString();
    _boxRateController.text = product.boxRate.toString();
    _salePriceController.text = product.salePrice.toString();
    _ctnPackingController.text = product.ctnPacking.toString();
    _boxPackingController.text = product.boxPacking.toString();
    _unitsPackingController.text = product.unitsPacking.toString();
    _editingProduct = product;
    setState(() {
      showForm = true;
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        _calculateBoxRate();
        
        final product = Product(
          id: _generateProductId(),
          company: _companyController.text.trim(),
          brand: _brandController.text.trim(),
          ctnRate: double.parse(_ctnRateController.text),
          boxRate: double.parse(_boxRateController.text),
          salePrice: double.parse(_salePriceController.text),
          ctnPacking: int.parse(_ctnPackingController.text),
          boxPacking: int.parse(_boxPackingController.text),
          unitsPacking: int.parse(_unitsPackingController.text),
        );

        await DatabaseHelper.instance.insertProduct(product.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _resetForm();
        _loadProducts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        _calculateBoxRate();
        final updatedProduct = Product(
          id: _editingProduct!.id,
          company: _companyController.text.trim(),
          brand: _brandController.text.trim(),
          ctnRate: double.parse(_ctnRateController.text),
          boxRate: double.parse(_boxRateController.text),
          salePrice: double.parse(_salePriceController.text),
          ctnPacking: int.parse(_ctnPackingController.text),
          boxPacking: int.parse(_boxPackingController.text),
          unitsPacking: int.parse(_unitsPackingController.text),
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        _editingProduct = null;
        _loadProducts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Add New Product',
            style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
        ),
        if (!showForm) _buildProductList(),
        if (showForm) Expanded(child: _buildAddForm()),
      ],
    );
  }

  Widget _buildProductList() {
    return Expanded(
      child: ListView.builder(
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          final product = filteredRecords[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text('${product.company} - ${product.brand}'),
              subtitle: Text('CTN Rate: Rs. ${product.ctnRate.toStringAsFixed(2)} | Box Rate: Rs. ${product.boxRate.toStringAsFixed(2)} | Sale Price: Rs. ${product.salePrice.toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                onPressed: () => _populateForm(product),
                tooltip: 'Edit Product',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Field
            TextFormField(
              controller: _companyController,
              decoration: InputDecoration(
                labelText: 'Company',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.business,
                  color: Colors.deepPurple,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Brand Field
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.branding_watermark,
                  color: Colors.deepPurple,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter brand name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Invoice Rate Section
            const Text(
              'Invoice Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ctnRateController,
                    decoration: InputDecoration(
                      labelText: 'CTN Rate',
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter CTN rate';
                      }
                      return null;
                    },
                    onChanged: (value) => _calculateBoxRate(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _boxRateController,
                    decoration: InputDecoration(
                      labelText: 'Box Rate',
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.calculate,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trade Rate Section
            const Text(
              'Trade Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _salePriceController,
              decoration: InputDecoration(
                labelText: 'Sale Price per Box',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Colors.deepPurple,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter sale price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Packing Section
            const Text(
              'Packing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ctnPackingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'CTN',
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.inventory,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter CTN';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _boxPackingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculateBoxRate(),
                    decoration: InputDecoration(
                      labelText: 'Box Packing',
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.inventory_2,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter box packing';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitsPackingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Units',
                      labelStyle: const TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.format_list_numbered,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter units';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _editingProduct == null ? _saveProduct : _updateProduct,
                    icon: Icon(_editingProduct == null ? Icons.save : Icons.edit, color: Colors.white),
                    label: Text(
                      _editingProduct == null ? 'Save Product' : 'Update Product',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
