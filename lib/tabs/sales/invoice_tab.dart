import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_keeper/database_helper.dart';
import 'package:records_keeper/tabs/shops/shop.dart';
import 'view_invoices_tab.dart';

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
  String company;
  double rate;
  int unit;
  double amount;

  InvoiceItem({
    required this.description,
    required this.company,
    required this.rate,
    required this.unit,
    this.amount = 0,
  }) {
    amount = rate * unit;
  }

  static InvoiceItem fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'],
      company: map['company'],
      rate: map['rate'],
      unit: map['unit'],
    );
  }
}

class InvoiceTab extends StatefulWidget {
  final Invoice? invoiceToEdit;
  const InvoiceTab({super.key, this.invoiceToEdit});

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
  final TextEditingController _productSearchController =
      TextEditingController();
  List<Product> _products = [];

  // Initialize with empty list
  final List<InvoiceItem> _items = [];

  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _editingInvoiceId;

  @override
  void initState() {
    super.initState();
    _loadShops().then((_) {
      if (widget.invoiceToEdit != null) {
        _initializeForEdit(widget.invoiceToEdit!);
      }
    });
    _loadProducts();
    if (widget.invoiceToEdit == null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _generateInvoiceNumber();
      _discountController.text = '0';
    }
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
    final invoiceNumber =
        'INV-${timestamp.toString().substring(timestamp.toString().length - 6)}';
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

  void _initializeForEdit(Invoice invoice) {
    _editingInvoiceId = invoice.id;
    _invoiceNumberController.text = invoice.invoiceNumber;
    _dateController.text = DateFormat('dd/MM/yyyy').format(invoice.date);
    _selectedDate = invoice.date;
    _discountController.text = invoice.discount.toString();
    _items.clear();
    _items.addAll(
      invoice.items.map(
        (item) => InvoiceItem(
          description: item.description,
          company: item.company,
          rate: item.rate,
          unit: item.unit,
          amount: item.amount,
        ),
      ),
    );
    // Set selected shop
    final shop = _shops.firstWhere(
      (s) => s.code == invoice.shopCode,
      orElse: () => Shop(
        code: invoice.shopCode,
        name: invoice.shopName,
        ownerName: invoice.ownerName,
        category: invoice.category,
        address: invoice.address,
        area: '',
        phone: '',
      ),
    );
    setState(() {
      _selectedShop = shop;
    });
  }

  Widget _buildShopAutocomplete(double scale) {
    return Autocomplete<Shop>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _shops;
        }
        return _shops.where((shop) {
          return shop.name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ) ||
              shop.code.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
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
          style: TextStyle(fontSize: 12 * scale, color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Search shop...',
            hintStyle: TextStyle(fontSize: 12 * scale, color: Colors.grey),
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
            'Address: ${_selectedShop!.address ?? 'N/A'}',
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProductAutocomplete(double scale) {
    return Autocomplete<Product>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _products;
        }
        return _products.where((product) {
          return product.brand.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ) ||
              product.company.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
        });
      },
      displayStringForOption: (Product product) =>
          '${product.company} - ${product.brand}',
      onSelected: (Product product) {
        setState(() {
          _isSearchingProduct = false;
          // Check if product already exists in items (match by brand, company, and rate)
          final existingItemIndex = _items.indexWhere(
            (item) =>
                item.description == product.brand &&
                item.company == product.company &&
                item.rate == product.salePrice,
          );
          if (existingItemIndex != -1) {
            // Increment unit if product already exists
            _items[existingItemIndex].unit++;
            _items[existingItemIndex].amount =
                _items[existingItemIndex].rate * _items[existingItemIndex].unit;
          } else {
            // Add new item if product doesn't exist
            _items.add(
              InvoiceItem(
                description: product.brand,
                company: product.company,
                rate: product.salePrice, // Use sale price instead of ctn rate
                unit: 1,
              ),
            );
          }
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        Future.delayed(Duration.zero, () => focusNode.requestFocus());

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(fontSize: 12 * scale, color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Search product...',
            hintStyle: TextStyle(fontSize: 12 * scale, color: Colors.grey),
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
          _buildTableCell('No.', flex: 1, isHeader: true, scale: scale),
          _buildTableCell('Description', flex: 3, isHeader: true, scale: scale),
          _buildTableCell('Rate', flex: 1, isHeader: true, scale: scale),
          _buildTableCell('Unit', flex: 1, isHeader: true, scale: scale),
          _buildTableCell('Price', flex: 1, isHeader: true, scale: scale),
          _buildTableCell(
            '',
            flex: 1,
            isHeader: true,
            scale: scale,
            isLast: true,
          ), // For actions
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    int flex = 1,
    bool isHeader = false,
    required double scale,
    bool isLast = false,
    TextAlign align = TextAlign.left,
    bool isNumeric = false,
  }) {
    final indianFormat = NumberFormat.decimalPattern('en_IN');
    String displayText = text;
    if (isNumeric) {
      final number = double.tryParse(text.replaceAll(',', ''));
      if (number != null) {
        displayText = indianFormat.format(number);
      }
    }
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          border: Border(
            right: !isLast
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Text(
          displayText,
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
          _buildTableCell(item.description, flex: 3, scale: scale),
          _buildTableCell(
            item.rate.toStringAsFixed(2),
            flex: 1,
            scale: scale,
            align: TextAlign.right,
            isNumeric: true,
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
            flex: 1,
            scale: scale,
            align: TextAlign.right,
            isNumeric: true,
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
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
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
                  style: TextStyle(fontSize: 11 * scale, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.edit, size: 12 * scale, color: Colors.grey.shade400),
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
    final indianFormat = NumberFormat.decimalPattern('en_IN');
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
              indianFormat.format(subtotal),
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
              indianFormat.format(total),
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

  Widget _buildInvoice(BuildContext context, double scale) {
    // Calculate height for each section
    final double headerHeight = 80 * scale; // Logo, invoice number, date
    final double shopDetailsHeight = _selectedShop != null
        ? 80 * scale
        : 40 * scale; // Shop details section
    final double itemHeaderHeight = 40 * scale; // Item details header
    final double itemRowHeight = 32 * scale; // Height per item row
    final double minItemsHeight =
        3 * itemRowHeight; // Minimum height for 3 items
    final double itemsHeight = _items.length > 3
        ? _items.length * itemRowHeight
        : minItemsHeight; // Actual items height
    final double totalsSectionHeight = 100 * scale; // Totals section
    final double signatureSectionHeight = 60 * scale; // Signature section
    final double paddingHeight = 48 * scale; // Total padding (12 * 4)

    // Calculate total height
    final double totalHeight =
        headerHeight +
        shopDetailsHeight +
        itemHeaderHeight +
        itemsHeight +
        totalsSectionHeight +
        signatureSectionHeight +
        paddingHeight;

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
                  'assets/logo.png',
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
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8 * scale,
                                ),
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
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8 * scale,
                                ),
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
              InkWell(
                onTap: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
                child: Text(
                  _selectedShop != null ? _selectedShop!.name : 'Add Shop',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8 * scale),
                  child: _buildShopAutocomplete(scale),
                ),
              if (_selectedShop != null) ...[
                SizedBox(height: 8 * scale),
                _buildShopDetails(scale),
              ],
            ],
          ),
          SizedBox(height: 8 * scale),

          // Add Item Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isSearchingProduct = true;
                  });
                },
                child: Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              if (_isSearchingProduct)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8 * scale),
                  child: _buildProductAutocomplete(scale),
                ),
            ],
          ),
          SizedBox(height: 8 * scale),

          // Items Table
          Expanded(
            child: Column(
              children: [
                _buildTableHeader(scale),
                Column(
                  children: [
                    ..._items.asMap().entries.map((entry) {
                      return _buildTableRow(entry.value, entry.key, scale);
                    }),
                    if (_items.length < 3) ...[
                      ...List.generate(
                        3 - _items.length,
                        (index) => Container(
                          height: 32 * scale,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(color: Colors.grey.shade300),
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                _buildTotalsSection(scale),
                SizedBox(height: 8 * scale),
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
      // Validate available_stock for each item
      List<String> insufficientStock = [];
      for (final item in _items) {
        Product? product;
        try {
          product = _products.firstWhere(
            (p) => p.brand == item.description && p.company == item.company,
          );
        } catch (_) {
          product = null;
        }
        if (product != null) {
          final available =
              await DatabaseHelper.instance.getAvailableStock(product.id) ?? 0;
          // If editing, add back the previous units for this item (since they will be replaced)
          int previousUnits = 0;
          if (_editingInvoiceId != null) {
            final prevInvoiceMap = await DatabaseHelper.instance.getInvoice(
              _editingInvoiceId!,
            );
            if (prevInvoiceMap != null) {
              final prevItems = (prevInvoiceMap['items'] as List)
                  .map((i) => InvoiceItem.fromMap(i))
                  .toList();
              final prevItem = prevItems.firstWhere(
                (i) =>
                    i.description == item.description &&
                    i.company == item.company,
                orElse: () =>
                    InvoiceItem(description: '', company: '', rate: 0, unit: 0),
              );
              previousUnits = prevItem.unit;
            }
          }
          final effectiveAvailable = available + previousUnits;
          if (item.unit > effectiveAvailable) {
            insufficientStock.add(
              '${product.company} - ${product.brand} (Available: $effectiveAvailable, Requested: ${item.unit})',
            );
          }
        }
      }
      if (insufficientStock.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Insufficient stock for:\n${insufficientStock.join('\n')}',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // If editing, fetch previous invoice items for stock adjustment
      Map<String, int> previousUnits = {};
      if (_editingInvoiceId != null) {
        final prevInvoiceMap = await DatabaseHelper.instance.getInvoice(
          _editingInvoiceId!,
        );
        if (prevInvoiceMap != null) {
          final prevItems = (prevInvoiceMap['items'] as List)
              .map((item) => InvoiceItem.fromMap(item))
              .toList();
          for (final item in prevItems) {
            previousUnits['${item.description}|${item.company}'] = item.unit;
          }
        }
      }

      final invoice = {
        'id':
            _editingInvoiceId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'invoiceNumber': _invoiceNumberController.text,
        'date': _selectedDate,
        'shopName': _selectedShop!.name,
        'shopCode': _selectedShop!.code,
        'ownerName': _selectedShop!.ownerName,
        'category': _selectedShop!.category,
        'address': _selectedShop!.address,
        'items': _items
            .map(
              (item) => {
                'description': item.description,
                'rate': item.rate,
                'unit': item.unit,
                'amount': item.amount,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'generated': widget.invoiceToEdit?.generated ?? 0,
      };

      // If editing, adjust available_stock for each product
      if (_editingInvoiceId != null) {
        assert(_editingInvoiceId != null && _editingInvoiceId is String, 'Editing invoice but _editingInvoiceId is null or not a String');
        invoice['id'] = _editingInvoiceId.toString();
        debugPrint('Updating invoice with map: $invoice');
        debugPrint('Type of invoice[\'id\'] before update: ${invoice['id'].runtimeType}');
        await DatabaseHelper.instance.updateInvoice(invoice);
      } else {
        await DatabaseHelper.instance.insertInvoice(invoice);
      }

      // Decrement available_stock for each product (for new invoices)
      if (_editingInvoiceId == null) {
        for (final item in _items) {
          Product? product;
          try {
            product = _products.firstWhere(
              (p) => p.brand == item.description && p.company == item.company,
            );
          } catch (_) {
            product = null;
          }
          if (product != null) {
            await DatabaseHelper.instance.decrementAvailableStock(
              product.id,
              item.unit.toDouble(),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingInvoiceId != null
                  ? 'Invoice updated successfully'
                  : 'Invoice saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear form
      _clearForm();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
                  // Remove fixed width and centering for full screen usage
                  final double scale = (maxWidth / 350).clamp(1.0, 1.25);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: maxWidth,
                          child: _buildInvoice(context, scale),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 240,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _saveInvoice();
                            },
                            icon: const Icon(Icons.save),
                            label: Text(_editingInvoiceId != null ? 'Update Invoice' : 'Create Invoice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
