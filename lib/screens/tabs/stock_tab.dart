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

  // Form controllers
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _ctnRateController = TextEditingController();
  final TextEditingController _boxRateController = TextEditingController();
  final TextEditingController _ctnPackingController = TextEditingController();
  final TextEditingController _boxPackingController = TextEditingController();
  final TextEditingController _unitsPackingController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _brandController.dispose();
    _ctnRateController.dispose();
    _boxRateController.dispose();
    _ctnPackingController.dispose();
    _boxPackingController.dispose();
    _unitsPackingController.dispose();
    super.dispose();
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
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showForm = !showForm;
                      });
                    },
                    icon: Icon(
                      showForm ? Icons.view_list : Icons.add,
                      color: Colors.white,
                    ),
                    label: Text(
                      showForm ? 'View Products' : 'Add Product',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        if (showForm)
          Expanded(
            child: SingleChildScrollView(
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
                          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
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
                          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                        prefixIcon: Icon(Icons.branding_watermark, color: Colors.deepPurple),
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
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                                borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              prefixIcon: Icon(Icons.attach_money, color: Colors.deepPurple),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter CTN rate';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
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
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                                borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              prefixIcon: Icon(Icons.attach_money, color: Colors.deepPurple),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter box rate';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
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
                                borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              prefixIcon: Icon(Icons.inventory, color: Colors.deepPurple),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter CTN';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
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
                                borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              prefixIcon: Icon(Icons.inventory_2, color: Colors.deepPurple),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter box';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
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
                                borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              prefixIcon: Icon(Icons.format_list_numbered, color: Colors.deepPurple),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter units';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
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
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text('Product list view will be implemented here'),
            ),
          ),
      ],
    );
  }
} 