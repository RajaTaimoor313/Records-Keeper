import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:intl/intl.dart';

class RealisationTab extends StatefulWidget {
  const RealisationTab({super.key});

  @override
  State<RealisationTab> createState() => _RealisationTabState();
}

class _RealisationTabState extends State<RealisationTab> {
  final List<RealisationFormRow> _rows = [];
  List<Map<String, dynamic>> _shopSuggestions = [];
  bool _isLoading = false;
  double _totalRealisation = 0;
  double _totalDiscount = 0;

  OverlayEntry? _suggestionOverlay;
  final LayerLink _layerLink = LayerLink();
  RealisationFormRow? _activeRow;
  String? _activeField;
  final GlobalKey _tableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadShopSuggestions();
    _addNewRow();
  }

  @override
  void dispose() {
    _removeSuggestionOverlay();
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadShopSuggestions() async {
    final db = await DatabaseHelper.instance.database;
    final shops = await db.query('shops');
    setState(() {
      _shopSuggestions = shops;
    });
  }

  void _addNewRow() {
    setState(() {
      final row = RealisationFormRow();
      row.addListener(_onRowFieldChanged);
      _rows.add(row);
    });
  }

  void _onRowFieldChanged(RealisationFormRow row, String field) {
    if (field == 'realisation' || field == 'discount') {
      _updateTotals();
    }
    if (field == 'code' || field == 'name' || field == 'address') {
      if (row.isLocked) {
        _removeSuggestionOverlay();
        return;
      }
      _showSuggestionOverlay(row, field);
    }
  }

  void _removeSuggestionOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
    _activeRow = null;
    _activeField = null;
  }

  void _showSuggestionOverlay(RealisationFormRow row, String field) {
    if (row.isLocked) {
      _removeSuggestionOverlay();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (row.isLocked) {
        _removeSuggestionOverlay();
        return;
      }
      _removeSuggestionOverlay();
      if (!mounted) return;
      final text = row.getController(field).text;
      if (text.isEmpty) return;
      final suggestions = _shopSuggestions.where((shop) {
        final value =
            (field == 'code'
                    ? shop['code']
                    : field == 'name'
                    ? shop['name']
                    : shop['address'])
                as String?;
        return value?.toLowerCase().contains(text.toLowerCase()) ?? false;
      }).toList();
      if (suggestions.isEmpty) return;
      final renderBox =
          row.getFieldKey(field).currentContext?.findRenderObject()
              as RenderBox?;
      final overlay = Overlay.of(context);
      if (renderBox == null) return;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      _activeRow = row;
      _activeField = field;
      _suggestionOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: position.dx,
          top: position.dy + size.height,
          width: size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final shop = suggestions[index];
                return ListTile(
                  title: Text(
                    shop[field == 'code'
                            ? 'code'
                            : field == 'name'
                            ? 'name'
                            : 'address']
                        as String,
                  ),
                  dense: true,
                  onTap: () {
                    _handleShopSelection(row, shop);
                    _removeSuggestionOverlay();
                  },
                );
              },
            ),
          ),
        ),
      );
      overlay.insert(_suggestionOverlay!);
    });
  }

  void _handleShopSelection(RealisationFormRow row, Map<String, dynamic> shop) async {
    setState(() {
      row.shopCode.text = shop['code'] as String;
      row.shopName.text = shop['name'] as String;
      row.address.text = shop['address'] as String? ?? '';
      row.isLocked = true;
      row.balanceHint = null;
    });
    final db = await DatabaseHelper.instance.database;
    final sumResult = await db.rawQuery(
      'SELECT (SUM(debit) - SUM(credit)) as balance FROM ledger WHERE shopCode = ?',
      [row.shopCode.text],
    );
    final currentBalance = (sumResult.first['balance'] as num?)?.toDouble() ?? 0.0;
    setState(() {
      row.balanceHint = currentBalance;
    });
    _removeSuggestionOverlay();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _handleProceed() async {
    if (_rows.isEmpty) return;
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    try {
      await db.transaction((txn) async {
        await txn.insert('income', {
          'date': dateStr,
          'category': 'Sales & Recovery',
          'details': 'Recovery',
          'amount': _totalRealisation,
        });
        for (var row in _rows) {
          if (row.shopCode.text.isNotEmpty && row.realisation.text.isNotEmpty) {
            final realisation = double.tryParse(row.realisation.text) ?? 0;
            if (realisation > 0) {
              final balanceResult = await txn.query(
                'ledger',
                columns: ['balance'],
                where: 'shopCode = ?',
                whereArgs: [row.shopCode.text],
                orderBy: 'id DESC',
                limit: 1,
              );
              final currentBalance = balanceResult.isNotEmpty
                  ? (balanceResult.first['balance'] as double?) ?? 0
                  : 0;
              await txn.insert('ledger', {
                'shopCode': row.shopCode.text,
                'shopName': row.shopName.text,
                'date': dateStr,
                'details': 'Recovery',
                'debit': 0,
                'credit': realisation,
                'balance': currentBalance - realisation,
              });
            }
          }
        }
      });
      setState(() {
        for (var row in _rows) {
          row.dispose();
        }
        _rows.clear();
        _addNewRow();
        _totalRealisation = 0;
        _totalDiscount = 0;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateTotals() {
    double realisation = 0;
    double discount = 0;
    for (var row in _rows) {
      realisation += double.tryParse(row.realisation.text) ?? 0;
      discount += double.tryParse(row.discount.text) ?? 0;
    }
    setState(() {
      _totalRealisation = realisation;
      _totalDiscount = discount;
    });
  }

  Widget _buildTableHeaderCell(
    String text, {
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInputCell(
    RealisationFormRow row,
    TextEditingController controller,
    String field,
  ) {
    final bool isEditable =
        !row.isLocked || field == 'realisation' || field == 'discount';
    String? hintText;
    TextStyle? hintStyle;
    if (field == 'realisation' && row.balanceHint != null) {
      final formatter = NumberFormat.decimalPattern('en_IN');
      hintText = formatter.format(row.balanceHint!.round());
      hintStyle = const TextStyle(color: Colors.grey);
    }
    return CompositedTransformTarget(
      link: field == _activeField && row == _activeRow
          ? _layerLink
          : LayerLink(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isEditable ? Colors.white : Colors.grey.shade100,
        ),
        child: Center(
          child: TextField(
            key: row.getFieldKey(field),
            controller: controller,
            enabled: isEditable,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: hintText,
              hintStyle: hintStyle,
            ),
            style: TextStyle(
              color: isEditable ? Colors.black87 : Colors.grey.shade700,
              fontSize: 13,
            ),
            keyboardType: field == 'realisation' || field == 'discount'
                ? TextInputType.number
                : TextInputType.text,
            onChanged: (value) {
              _onRowFieldChanged(row, field);
            },
            onTap: () {
              if (isEditable &&
                  (field == 'code' || field == 'name' || field == 'address')) {
                _showSuggestionOverlay(row, field);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.deepPurple.shade50,
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildTableHeaderCell('Shop Code')),
          Expanded(flex: 3, child: _buildTableHeaderCell('Shop Name')),
          Expanded(flex: 4, child: _buildTableHeaderCell('Address')),
          Expanded(flex: 2, child: _buildTableHeaderCell('Realisation')),
          Expanded(flex: 2, child: _buildTableHeaderCell('Discount')),
          SizedBox(width: 80, child: _buildTableHeaderCell('Actions')),
        ],
      ),
    );
  }

  Widget _buildTableRow(RealisationFormRow row) {
    int rowIndex = _rows.indexOf(row);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildInputCell(row, row.shopCode, 'code')),
          Expanded(flex: 3, child: _buildInputCell(row, row.shopName, 'name')),
          Expanded(
            flex: 4,
            child: _buildInputCell(row, row.address, 'address'),
          ),
          Expanded(
            flex: 2,
            child: _buildInputCell(row, row.realisation, 'realisation'),
          ),
          Expanded(
            flex: 2,
            child: _buildInputCell(row, row.discount, 'discount'),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit',
                  onPressed: row.isLocked
                      ? () {
                          setState(() {
                            row.isLocked = false;
                          });
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: 'Delete',
                  onPressed: () {
                    setState(() {
                      _rows.removeAt(rowIndex);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFooter() {
    return Container(
      color: Colors.deepPurple.shade50,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const Expanded(
            flex: 9,
            child: Text(
              'Total',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _totalRealisation.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _totalDiscount.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _removeSuggestionOverlay,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Realisation Form',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleProceed,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                  label: const Text(
                    'Proceed',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              key: _tableKey,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTableHeader(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _rows.length,
                    itemBuilder: (context, index) =>
                        _buildTableRow(_rows[index]),
                  ),
                  _buildTableFooter(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _addNewRow,
                icon: const Icon(Icons.add),
                label: const Text('Add Row'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RealisationFormRow {
  final TextEditingController shopCode = TextEditingController();
  final TextEditingController shopName = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController realisation = TextEditingController();
  final TextEditingController discount = TextEditingController();
  bool isLocked = false;
  double? balanceHint;
  final Map<String, GlobalKey> _fieldKeys = {
    'code': GlobalKey(),
    'name': GlobalKey(),
    'address': GlobalKey(),
    'realisation': GlobalKey(),
    'discount': GlobalKey(),
  };
  void addListener(void Function(RealisationFormRow, String) listener) {
    shopCode.addListener(() => listener(this, 'code'));
    shopName.addListener(() => listener(this, 'name'));
    address.addListener(() => listener(this, 'address'));
    realisation.addListener(() => listener(this, 'realisation'));
    discount.addListener(() => listener(this, 'discount'));
  }

  TextEditingController getController(String field) {
    switch (field) {
      case 'code':
        return shopCode;
      case 'name':
        return shopName;
      case 'address':
        return address;
      case 'realisation':
        return realisation;
      case 'discount':
        return discount;
      default:
        throw Exception('Invalid field');
    }
  }

  GlobalKey getFieldKey(String field) => _fieldKeys[field]!;
  void dispose() {
    shopCode.dispose();
    shopName.dispose();
    address.dispose();
    realisation.dispose();
    discount.dispose();
  }
}
