import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database_helper.dart';
import 'dart:math';

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

  // Replace trade rate controllers with sale price controller
  final TextEditingController _salePriceController = TextEditingController();

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
      setState(() {
        productRecords = records
            .map(
              (record) => Product(
                id: record['id'] ?? '',
                company: record['company'],
                brand: record['brand'],
                ctnRate: record['ctnRate'],
                boxRate: record['boxRate'],
                salePrice: record['salePrice'],
                ctnPacking: record['ctnPacking'],
                boxPacking: record['boxPacking'],
                unitsPacking: record['unitsPacking'],
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
    }
  }

  void _filterRecords() {
    setState(() {
      filteredRecords = productRecords.where((product) {
        final searchText = searchController.text.toLowerCase();
        return product.company.toLowerCase().contains(searchText) ||
            product.brand.toLowerCase().contains(searchText) ||
            product.ctnRate.toString().contains(searchText) ||
            product.boxRate.toString().contains(searchText);
      }).toList();
    });
  }

  void _sortRecords(String sortCriteria) {
    if (sortBy == sortCriteria) {
      setState(() {
        isAscending = !isAscending;
      });
    } else {
      setState(() {
        sortBy = sortCriteria;
        isAscending = true;
      });
    }

    setState(() {
      switch (sortCriteria) {
        case 'Company':
          filteredRecords.sort(
            (a, b) => isAscending
                ? a.company.compareTo(b.company)
                : b.company.compareTo(a.company),
          );
          break;
        case 'Brand':
          filteredRecords.sort(
            (a, b) => isAscending
                ? a.brand.compareTo(b.brand)
                : b.brand.compareTo(a.brand),
          );
          break;
        case 'Invoice Rate (CTN)':
          filteredRecords.sort(
            (a, b) => isAscending
                ? a.ctnRate.compareTo(b.ctnRate)
                : b.ctnRate.compareTo(a.ctnRate),
          );
          break;
        case 'Invoice Rate (Box)':
          filteredRecords.sort(
            (a, b) => isAscending
                ? a.boxRate.compareTo(b.boxRate)
                : b.boxRate.compareTo(a.boxRate),
          );
          break;
      }
    });
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Calculate box rate one final time before saving
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showForm ? 'Add New Product' : 'Product List',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: showForm
                              ? Colors.grey.shade200
                              : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (!showForm) {
                                setState(() {
                                  showForm = true;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: !showForm
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Product',
                                    style: TextStyle(
                                      color: !showForm
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: !showForm
                              ? Colors.grey.shade200
                              : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (showForm) {
                                setState(() {
                                  showForm = false;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    color: showForm
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View Products',
                                    style: TextStyle(
                                      color: showForm
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showForm ? _buildAddForm() : _buildDataView(),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
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
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                prefixIcon: const Icon(Icons.business, color: Colors.deepPurple),
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
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
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
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.deepPurple),
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
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.calculate, color: Colors.deepPurple),
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
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.deepPurple),
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
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.inventory_2, color: Colors.deepPurple),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter box packing';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
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
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Save Product',
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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

  Widget _buildDataView() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Loading products...',
              style: TextStyle(color: Colors.deepPurple, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          width: double.infinity,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.deepPurple,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.deepPurple),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.deepPurple,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) => _filterRecords(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Sort by',
                                labelStyle: const TextStyle(color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.deepPurple.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.deepPurple,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.sort,
                                  color: Colors.deepPurple,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: sortBy,
                                  isDense: true,
                                  isExpanded: true,
                                  hint: const Text('Sort...'),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                  items:
                                      [
                                        'Company',
                                        'Brand',
                                        'Invoice Rate (CTN)',
                                        'Invoice Rate (Box)',
                                      ].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(value),
                                              if (sortBy == value)
                                                Icon(
                                                  isAscending
                                                      ? Icons.arrow_upward
                                                      : Icons.arrow_downward,
                                                  size: 16,
                                                  color: Colors.deepPurple,
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      _sortRecords(newValue);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.deepPurple,
                              ),
                              onPressed: () {
                                setState(() {
                                  sortBy = null;
                                  searchController.clear();
                                });
                                _loadProducts();
                              },
                              tooltip: 'Refresh Data',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_list_rounded,
                              color: Colors.deepPurple.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Product List',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple.shade700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${filteredRecords.length} Products',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Header Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 800,
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              verticalInside: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            columnWidths: const <int, TableColumnWidth>{
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(4),
                              4: FlexColumnWidth(6),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50.withOpacity(0.7),
                                ),
                                children: [
                                  _buildHeaderCell('ID', true),
                                  _buildHeaderCell('Company', true),
                                  _buildHeaderCell('Brand', true),
                                  _buildHeaderCell('Invoice Rate', false),
                                  _buildHeaderCell('Packing', false),
                                ],
                              ),
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50.withOpacity(0.5),
                                ),
                                children: [
                                  TableCell(child: Container()),
                                  TableCell(child: Container()),
                                  TableCell(child: Container()),
                                  _buildSubHeaderRow(['CTN', 'Box']),
                                  _buildSubHeaderRow(['CTN', 'Box', 'Units']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Data rows
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 800,
                            child: SingleChildScrollView(
                              child: Column(
                                children: List.generate(
                                  filteredRecords.length,
                                  (index) => _buildDataRow(filteredRecords[index], index % 2 == 0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, bool isSpanned) {
    return TableCell(
      verticalAlignment: isSpanned ? TableCellVerticalAlignment.fill : TableCellVerticalAlignment.middle,
      child: Container(
        height: isSpanned ? 88 : 48,
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple.shade700,
            fontSize: 13.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeaderRow(List<String> items) {
    return TableCell(
      child: Row(
        children: items.map((item) {
          final isLast = item == items.last;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataRow(Product product, bool isEven) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: isEven ? Colors.grey.shade50 : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Handle row tap if needed
            },
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(4),
                4: FlexColumnWidth(6),
              },
              children: [
                TableRow(
                  children: [
                    _buildDataCell(product.id, isId: true),
                    _buildDataCell(product.company),
                    _buildDataCell(product.brand),
                    _buildInvoiceRateCell(product.ctnRate, product.boxRate, product.salePrice),
                    _buildPackingCell(product.ctnPacking, product.boxPacking, product.unitsPacking),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isId = false}) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            color: isId ? Colors.deepPurple.shade700 : Colors.grey.shade800,
            fontSize: 13,
            height: 1.4,
            fontWeight: isId ? FontWeight.w600 : null,
            letterSpacing: isId ? 0.5 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRateCell(double ctnRate, double boxRate, double salePrice) {
    return TableCell(
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    'Invoice: Rs. ${ctnRate.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sale: Rs. ${salePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'Rs. ${boxRate.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackingCell(int ctn, int box, int units) {
    return TableCell(
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              alignment: Alignment.center,
              child: Text(
                '$ctn',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              alignment: Alignment.center,
              child: Text(
                '$box',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              alignment: Alignment.center,
              child: Text(
                '$units',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
