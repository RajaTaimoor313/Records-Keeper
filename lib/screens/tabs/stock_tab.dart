import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database_helper.dart';

class Product {
  final String company;
  final String brand;
  final double ctnRate;
  final double boxRate;
  final int ctnPacking;
  final int boxPacking;
  final int unitsPacking;

  Product({
    required this.company,
    required this.brand,
    required this.ctnRate,
    required this.boxRate,
    required this.ctnPacking,
    required this.boxPacking,
    required this.unitsPacking,
  });

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'brand': brand,
      'ctnRate': ctnRate,
      'boxRate': boxRate,
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
                company: record['company'],
                brand: record['brand'],
                ctnRate: record['ctnRate'],
                boxRate: record['boxRate'],
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
    _formKey.currentState?.reset();
    _companyController.clear();
    _brandController.clear();
    _ctnRateController.clear();
    _boxRateController.clear();
    _ctnPackingController.clear();
    _boxPackingController.clear();
    _unitsPackingController.clear();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final product = Product(
          company: _companyController.text.trim(),
          brand: _brandController.text.trim(),
          ctnRate: double.parse(_ctnRateController.text),
          boxRate: double.parse(_boxRateController.text),
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
                offset: Offset(0, 2),
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
                    style: TextStyle(
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
                              padding: EdgeInsets.symmetric(horizontal: 16),
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
                                  SizedBox(width: 8),
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
                      SizedBox(width: 12),
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
                              padding: EdgeInsets.symmetric(horizontal: 16),
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
                                  SizedBox(width: 8),
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
            duration: Duration(milliseconds: 300),
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
                labelStyle: TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                prefixIcon: Icon(Icons.business, color: Colors.deepPurple),
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
            SizedBox(height: 16),

            // Brand Field
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand',
                labelStyle: TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                prefixIcon: Icon(
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
            SizedBox(height: 16),

            // Invoice Rate Section
            Text(
              'Invoice Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ctnRateController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'CTN Rate',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter CTN rate';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid rate';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _boxRateController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Box Rate',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter box rate';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid rate';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Packing Section
            Text(
              'Packing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ctnPackingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'CTN',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
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
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _boxPackingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Box',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.inventory_2,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter box';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitsPackingController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Units',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
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
            SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text(
                      'Save Product',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: Icon(Icons.refresh),
                  label: Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: BorderSide(color: Colors.deepPurple),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
      return Center(
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
                  constraints: BoxConstraints(minWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.deepPurple,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.deepPurple.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => _filterRecords(),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Sort by',
                                labelStyle: TextStyle(color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
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
                                  borderSide: BorderSide(
                                    color: Colors.deepPurple,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
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
                                  hint: Text('Sort...'),
                                  style: TextStyle(
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
                          SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(
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
                      SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Header Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth:
                                800, // Minimum width before scrolling starts
                          ),
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                              verticalInside: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                              top: BorderSide(color: Colors.grey.shade300),
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const <int, TableColumnWidth>{
                              0: FlexColumnWidth(2), // Company
                              1: FlexColumnWidth(2), // Brand
                              2: FlexColumnWidth(2), // Invoice Rate (spans 2)
                              3: FlexColumnWidth(3), // Packing (spans 3)
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50.withOpacity(
                                    0.7,
                                  ),
                                ),
                                children: [
                                  // Company - spans 2 rows
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.fill,
                                    child: Container(
                                      height: 88,
                                      padding: EdgeInsets.all(8),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Company',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple.shade700,
                                          fontSize: 13.5,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Brand - spans 2 rows
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.fill,
                                    child: Container(
                                      height: 88,
                                      padding: EdgeInsets.all(8),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Brand',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple.shade700,
                                          fontSize: 13.5,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Invoice Rate header
                                  TableCell(
                                    child: Container(
                                      height: 48,
                                      padding: EdgeInsets.all(8),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Invoice Rate',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple.shade700,
                                          fontSize: 13.5,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Packing header
                                  TableCell(
                                    child: Container(
                                      height: 48,
                                      padding: EdgeInsets.all(8),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Packing',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepPurple.shade700,
                                          fontSize: 13.5,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50.withOpacity(
                                    0.5,
                                  ),
                                ),
                                children: [
                                  // Empty cells for Company and Brand (spanned)
                                  TableCell(child: Container()),
                                  TableCell(child: Container()),
                                  // Invoice Rate sub-headers
                                  TableCell(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            padding: EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'CTN',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors.deepPurple.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            padding: EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Box',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors.deepPurple.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Packing sub-headers
                                  TableCell(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            padding: EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'CTN',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors.deepPurple.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            padding: EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Box',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors.deepPurple.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            padding: EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Units',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    Colors.deepPurple.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
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
                      // Data rows
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: 800, // Match header table minimum width
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredRecords.length,
                            itemBuilder: (context, index) {
                              final product = filteredRecords[index];
                              final isEven = index % 2 == 0;

                              return Container(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? Colors.grey.shade50
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Table(
                                  columnWidths: const <int, TableColumnWidth>{
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(2),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(3),
                                  },
                                  children: [
                                    TableRow(
                                      children: [
                                        TableCell(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              product.company,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              product.brand,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 12,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Rs. ${product.ctnRate.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 12,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Rs. ${product.boxRate.toStringAsFixed(2)}',
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
                                  ],
                                ),
                              );
                            },
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
}
