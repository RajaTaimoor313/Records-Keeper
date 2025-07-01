import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'stock_tab.dart';

class ViewProductsTab extends StatefulWidget {
  const ViewProductsTab({super.key});

  @override
  State<ViewProductsTab> createState() => _ViewProductsTabState();
}

class _ViewProductsTabState extends State<ViewProductsTab> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  List<Product> productRecords = [];
  List<Product> filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
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
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterRecords() {
    setState(() {
      filteredRecords = productRecords.where((product) {
        final searchText = searchController.text.toLowerCase();
        return product.company.toLowerCase().contains(searchText) ||
            product.brand.toLowerCase().contains(searchText);
      }).toList();
    });
  }

  void _showEditProductDialog(Product product) {
    final companyController = TextEditingController(text: product.company);
    final brandController = TextEditingController(text: product.brand);
    final ctnRateController = TextEditingController(text: product.ctnRate.toString());
    final boxRateController = TextEditingController(text: product.boxRate.toString());
    final salePriceController = TextEditingController(text: product.salePrice.toString());
    final ctnPackingController = TextEditingController(text: product.ctnPacking.toString());
    final boxPackingController = TextEditingController(text: product.boxPacking.toString());
    final unitsPackingController = TextEditingController(text: product.unitsPacking.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                TextField(
                  controller: ctnRateController,
                  decoration: const InputDecoration(labelText: 'CTN Rate'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: boxRateController,
                  decoration: const InputDecoration(labelText: 'Box Rate'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: salePriceController,
                  decoration: const InputDecoration(labelText: 'Sale Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: ctnPackingController,
                  decoration: const InputDecoration(labelText: 'CTN Packing'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: boxPackingController,
                  decoration: const InputDecoration(labelText: 'Box Packing'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: unitsPackingController,
                  decoration: const InputDecoration(labelText: 'Units Packing'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedProduct = Product(
                  id: product.id,
                  company: companyController.text.trim(),
                  brand: brandController.text.trim(),
                  ctnRate: double.tryParse(ctnRateController.text) ?? 0.0,
                  boxRate: double.tryParse(boxRateController.text) ?? 0.0,
                  salePrice: double.tryParse(salePriceController.text) ?? 0.0,
                  ctnPacking: int.tryParse(ctnPackingController.text) ?? 0,
                  boxPacking: int.tryParse(boxPackingController.text) ?? 0,
                  unitsPacking: int.tryParse(unitsPackingController.text) ?? 0,
                );
                await DatabaseHelper.instance.updateProduct(updatedProduct.toMap());
                Navigator.of(context).pop();
                _loadProducts();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text(
                'Product List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Total: ${filteredRecords.length}',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by company or brand...',
              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
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
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => _filterRecords(),
          ),
        ),
        if (isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          )
        else
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
                          'Try adjusting your search',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                            verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                            top: BorderSide(color: Colors.grey.shade300, width: 1),
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            left: BorderSide(color: Colors.grey.shade300, width: 1),
                            right: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          headingRowColor: MaterialStateProperty.all(
                            Colors.deepPurple.shade50,
                          ),
                          dataRowColor: MaterialStateProperty.resolveWith(
                            (states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.deepPurple.shade100;
                              }
                              return null;
                            },
                          ),
                          headingRowHeight: 80,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 80,
                          columnSpacing: 24,
                          horizontalMargin: 24,
                          showCheckboxColumn: false,
                          columns: [
                            const DataColumn(
                              label: Text(
                                '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Company',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Brand',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Trade Rate',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Invoice Rate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                                      height: 1.0,
                                      color: Colors.grey.shade300,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: const [
                                        Text(
                                          'CTN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        SizedBox(width: 84),
                                        Text(
                                          'Box',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Packing',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                                      height: 1.0,
                                      color: Colors.grey.shade300,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: const [
                                        Text(
                                          'CTN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                        Text(
                                          'Box',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                        Text(
                                          'Units',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Icon(Icons.edit, color: Colors.deepPurple),
                            ),
                          ],
                          rows: filteredRecords.asMap().entries.map((entry) {
                            final index = entry.key;
                            final product = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.company,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.brand,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'Rs. ${product.salePrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        'Rs. ${product.ctnRate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Rs. ${product.boxRate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        '${product.ctnPacking}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '${product.boxPacking}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '${product.unitsPacking}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                    tooltip: 'Edit Product',
                                    onPressed: () => _showEditProductDialog(product),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
} 