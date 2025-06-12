import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database_helper.dart';
import '../../../models/shop.dart';

class Product {
  final String id;
  final String company;
  final String brand;
  final double ctnRate;
  final double boxRate;
  final int ctnPacking;
  final int boxPacking;
  final int unitsPacking;
  final double salePrice;

  Product({
    required this.id,
    required this.company,
    required this.brand,
    required this.ctnRate,
    required this.boxRate,
    required this.ctnPacking,
    required this.boxPacking,
    required this.unitsPacking,
    required this.salePrice,
  });

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      company: map['company'],
      brand: map['brand'],
      ctnRate: map['ctnRate'],
      boxRate: map['boxRate'],
      ctnPacking: map['ctnPacking'],
      boxPacking: map['boxPacking'],
      unitsPacking: map['unitsPacking'],
      salePrice: map['salePrice'],
    );
  }
}

class InvoiceItem {
  String description;
  double rate;
  int unit;
  double amount;

  InvoiceItem({
    required this.description,
    required this.rate,
    required this.unit,
    this.amount = 0,
  }) {
    amount = rate * unit;
  }
}

class InvoiceTab extends StatefulWidget {
  const InvoiceTab({super.key});

  @override
  State<InvoiceTab> createState() => _InvoiceTabState();
}

class _InvoiceTabState extends State<InvoiceTab> {
  final _formKey = GlobalKey<FormState>();
  Shop? _selectedShop;
  List<Shop> _shops = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSearchingProduct = false;
  final TextEditingController _shopSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  List<Product> _products = [];

  // Initialize with empty list
  final List<InvoiceItem> _items = [];

  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadShops();
    _loadProducts();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _generateInvoiceNumber();
    _discountController.text = '0';
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dateController.dispose();
    _discountController.dispose();
    _shopSearchController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get discount => double.tryParse(_discountController.text) ?? 0;
  double get total => subtotal - discount;

  Future<void> _loadShops() async {
    try {
      final shopsData = await DatabaseHelper.instance.getShops();
      setState(() {
        _shops = shopsData.map((data) => Shop.fromMap(data)).toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadProducts() async {
    try {
      final productsData = await DatabaseHelper.instance.getProducts();
      setState(() {
        _products = productsData.map((data) => Product.fromMap(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateInvoiceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final invoiceNumber = 'INV-${timestamp.toString().substring(timestamp.toString().length - 6)}';
    _invoiceNumberController.text = invoiceNumber;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  Widget _buildShopSelection(double scale) {
    if (_isSearching) {
      return Expanded(
        child: SizedBox(
          height: 24 * scale,
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: TextTheme(
                titleMedium: TextStyle(fontSize: 12 * scale),
                bodySmall: TextStyle(fontSize: 10 * scale),
              ),
            ),
            child: _buildShopAutocomplete(scale),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedShop != null)
          Text(
            _selectedShop!.name,
            style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.black87,
            ),
          ),
        SizedBox(width: 8 * scale),
        InkWell(
          onTap: () {
            setState(() {
              _isSearching = true;
            });
          },
          child: Icon(
            Icons.search,
            size: 16 * scale,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildShopAutocomplete(double scale) {
    return Autocomplete<Shop>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _shops;
        }
        return _shops.where((shop) {
          return shop.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                 shop.code.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      displayStringForOption: (Shop shop) => shop.name,
      onSelected: (Shop shop) {
        setState(() {
          _selectedShop = shop;
          _isSearching = false;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        Future.delayed(Duration.zero, () => focusNode.requestFocus());
        
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: 12 * scale,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Search shop...',
            hintStyle: TextStyle(
              fontSize: 12 * scale,
              color: Colors.grey,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 8 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.close, size: 16 * scale),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                });
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 24 * scale,
                minHeight: 24 * scale,
              ),
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: 24 * scale,
              minHeight: 24 * scale,
            ),
          ),
          onFieldSubmitted: (value) {
            if (value.isEmpty) {
              setState(() {
                _isSearching = false;
              });
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200 * scale,
                maxWidth: 200 * scale,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final Shop shop = options.elementAt(index);
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    title: Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Code: ${shop.code}',
                      style: TextStyle(
                        fontSize: 10 * scale,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () {
                      onSelected(shop);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopDetails(double scale) {
    if (_selectedShop == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'Owner: ${_selectedShop!.ownerName}',
            style: TextStyle(fontSize: 12 * scale),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            'Category: ${_selectedShop!.category}',
            style: TextStyle(fontSize: 12 * scale),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProductSelection(double scale) {
    if (_isSearchingProduct) {
      return Expanded(
        child: SizedBox(
          height: 24 * scale,
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: TextTheme(
                titleMedium: TextStyle(fontSize: 12 * scale),
                bodySmall: TextStyle(fontSize: 10 * scale),
              ),
            ),
            child: _buildProductAutocomplete(scale),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _isSearchingProduct = true;
        });
      },
      child: Icon(
        Icons.search,
        size: 16 * scale,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildProductAutocomplete(double scale) {
    return Autocomplete<Product>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _products;
        }
        return _products.where((product) {
          return product.brand.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                 product.company.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      displayStringForOption: (Product product) => '${product.company} - ${product.brand}',
      onSelected: (Product product) {
        setState(() {
          _isSearchingProduct = false;
          // Check if product already exists in items
          final existingItemIndex = _items.indexWhere((item) => item.description == product.brand);
          if (existingItemIndex != -1) {
            // Increment unit if product already exists
            _items[existingItemIndex].unit++;
            _items[existingItemIndex].amount = _items[existingItemIndex].rate * _items[existingItemIndex].unit;
          } else {
            // Add new item if product doesn't exist
            _items.add(InvoiceItem(
              description: product.brand,
              rate: product.salePrice, // Use sale price instead of ctn rate
              unit: 1,
            ));
          }
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        Future.delayed(Duration.zero, () => focusNode.requestFocus());
        
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: 12 * scale,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Search product...',
            hintStyle: TextStyle(
              fontSize: 12 * scale,
              color: Colors.grey,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 8 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4 * scale),
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.close, size: 16 * scale),
              onPressed: () {
                setState(() {
                  _isSearchingProduct = false;
                });
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 24 * scale,
                minHeight: 24 * scale,
              ),
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: 24 * scale,
              minHeight: 24 * scale,
            ),
          ),
          onFieldSubmitted: (value) {
            if (value.isEmpty) {
              setState(() {
                _isSearchingProduct = false;
              });
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200 * scale,
                maxWidth: 200 * scale,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final Product product = options.elementAt(index);
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    title: Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Company: ${product.company}',
                      style: TextStyle(
                        fontSize: 10 * scale,
                        color: Colors.grey.shade600,
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
    );
  }

  Widget _buildTableHeader(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4 * scale),
          topRight: Radius.circular(4 * scale),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell('', flex: 1, isHeader: true, scale: scale),
          _buildTableCell('Description', flex: 3, isHeader: true, scale: scale),
          _buildTableCell('Rate', flex: 2, isHeader: true, scale: scale),
          _buildTableCell('Unit', isHeader: true, scale: scale),
          _buildTableCell('Price', flex: 2, isHeader: true, scale: scale),
          _buildTableCell('', flex: 1, isHeader: true, scale: scale, isLast: true), // For actions
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {
    int flex = 1,
    bool isHeader = false,
    required double scale,
    bool isLast = false,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          border: Border(
            right: !isLast ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.deepPurple : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTableRow(InvoiceItem item, int index, double scale) {
    final isEven = index % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(
            (index + 1).toString(),
            flex: 1,
            scale: scale,
            align: TextAlign.center,
          ),
          _buildTableCell(
            item.description,
            flex: 3,
            scale: scale,
          ),
          _buildTableCell(
            item.rate.toStringAsFixed(2),
            flex: 2,
            scale: scale,
            align: TextAlign.right,
          ),
          _buildEditableCell(
            text: item.unit.toString(),
            flex: 1,
            scale: scale,
            align: TextAlign.right,
            onTap: () => _editItemUnit(index),
          ),
          _buildTableCell(
            item.amount.toStringAsFixed(2),
            flex: 2,
            scale: scale,
            align: TextAlign.right,
          ),
          Expanded(
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 16 * scale,
                color: Colors.red.shade400,
              ),
              onPressed: () => _deleteItem(index),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 24 * scale,
                minHeight: 24 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell({
    required String text,
    required int flex,
    required double scale,
    required VoidCallback onTap,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 4 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: align == TextAlign.right 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: align,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.edit,
                size: 12 * scale,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editItemUnit(int index) async {
    final item = _items[index];
    final TextEditingController controller = TextEditingController(
      text: item.unit.toString(),
    );
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Unit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Unit',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newUnit = int.tryParse(result);
      if (newUnit != null) {
        setState(() {
          _items[index].unit = newUnit;
          _items[index].amount = item.rate * newUnit;
        });
      }
    }
  }

  void _deleteItem(int index) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed ?? false) {
        setState(() {
          _items.removeAt(index);
        });
      }
    });
  }

  Widget _buildTotalsSection(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Subtotal:',
              style: TextStyle(
                fontSize: 10 * scale,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              subtotal.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 10 * scale,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Discount:',
              style: TextStyle(
                fontSize: 10 * scale,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(width: 12 * scale),
            SizedBox(
              width: 60 * scale,
              height: 20 * scale,
              child: TextFormField(
                controller: _discountController,
                style: TextStyle(fontSize: 10 * scale),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6 * scale,
                    vertical: 6 * scale,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4 * scale),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4 * scale),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4 * scale),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Total:',
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              total.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureSection(double scale) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20 * scale,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              Text(
                'Customer Signature',
                style: TextStyle(fontSize: 8 * scale),
              ),
            ],
          ),
        ),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20 * scale,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              Text(
                'Authorized Signature',
                style: TextStyle(fontSize: 8 * scale),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoice(BuildContext context, double scale) {
    // Calculate height based on number of items
    final double baseHeight = 421 * scale; // Height for 3 items
    final double itemHeight = 32 * scale; // Height per additional item
    final int extraItems = _items.length > 3 ? _items.length - 3 : 0;
    final double totalHeight = baseHeight + (extraItems * itemHeight);

    return Container(
      width: 297 * scale,
      height: totalHeight,
      padding: EdgeInsets.all(12.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Logo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2 * scale),
                child: Image.asset(
                  'assets/logo.jpg',
                  width: 40 * scale,
                  height: 40 * scale,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceNumberController,
                              readOnly: true,
                              style: TextStyle(fontSize: 12 * scale),
                              decoration: InputDecoration(
                                labelText: 'Invoice #',
                                labelStyle: TextStyle(fontSize: 12 * scale),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8 * scale),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: _selectDate,
                              style: TextStyle(fontSize: 12 * scale),
                              decoration: InputDecoration(
                                labelText: 'Date',
                                labelStyle: TextStyle(fontSize: 12 * scale),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8 * scale),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),

          // Shop Details Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shop Details',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  _buildShopSelection(scale),
                ],
              ),
              if (_selectedShop != null) ...[
                SizedBox(height: 8 * scale),
                _buildShopDetails(scale),
              ],
            ],
          ),
          SizedBox(height: 8 * scale),

          // Item Details Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item Details',
                style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              _buildProductSelection(scale),
            ],
          ),
          SizedBox(height: 8 * scale),

          // Items Table
          Expanded(
            child: Column(
              children: [
                _buildTableHeader(scale),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ..._items.asMap().entries.map((entry) {
                          return _buildTableRow(entry.value, entry.key, scale);
                        }),
                        if (_items.length < 3) ...[
                          ...List.generate(3 - _items.length, (index) => 
                            Container(
                              height: 32 * scale,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey.shade300),
                                  right: BorderSide(color: Colors.grey.shade300),
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            )
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildTotalsSection(scale),
                SizedBox(height: 8 * scale),
                _buildSignatureSection(scale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInvoice() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate shop selection and items
    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the invoice'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final invoice = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'invoiceNumber': _invoiceNumberController.text,
        'date': _selectedDate,
        'shopName': _selectedShop!.name,
        'items': _items.map((item) => {
          'description': item.description,
          'rate': item.rate,
          'unit': item.unit,
          'amount': item.amount,
        }).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
      };

      // Save invoice
      await DatabaseHelper.instance.insertInvoice(invoice);

      // Add items to load form
      for (final item in _items) {
        await DatabaseHelper.instance.insertLoadFormItem({
          'brandName': item.description,
          'units': item.unit,
        });
      }

      // Add or update pick list item
      await DatabaseHelper.instance.insertOrUpdatePickListItem({
        'code': _selectedShop!.code,
        'shopName': _selectedShop!.name,
        'ownerName': _selectedShop!.ownerName,
        'billAmount': total,
        'paymentType': '', // Will be editable in pick list
        'recovery': 0, // Will be editable in pick list
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear form
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedShop = null;
      _items.clear();
      _discountController.text = '0';
      _generateInvoiceNumber();
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    });
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
          : Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxWidth = constraints.maxWidth;
                  final int invoicesPerRow = (maxWidth / 350).floor().clamp(1, 2);
                  final double availableWidth = maxWidth - 32;
                  final double scale = ((availableWidth / invoicesPerRow) / 297).clamp(0.5, 1.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildInvoice(context, scale),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _saveInvoice();
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Generate Invoice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
} 