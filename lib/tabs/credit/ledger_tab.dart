import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_keeper/database_helper.dart';
import 'dart:math';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;

class LedgerTab extends StatefulWidget {
  const LedgerTab({super.key});

  @override
  State<LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends State<LedgerTab> {
  List<Map<String, dynamic>> _shopBalances = [];
  final Map<String, List<Map<String, dynamic>>> _shopTransactions = {};
  final Map<String, bool> _expandedShops = {};
  bool _isLoading = true;

  // Add for search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShopBalances();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShopBalances() async {
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    final records = await dbInstance.rawQuery('''
      SELECT shopName, shopCode, 
             SUM(debit) as totalDebit, 
             SUM(credit) as totalCredit,
             (SUM(debit) - SUM(credit)) as balance
      FROM ledger 
      GROUP BY shopName, shopCode
      ORDER BY shopName
    ''');

    setState(() {
      _shopBalances = records;
      _isLoading = false;
    });
  }

  Future<void> _loadShopTransactions(String shopName, String? shopCode) async {
    final key = shopCode == null || shopCode.isEmpty ? shopName : '$shopName-$shopCode';

    if (_shopTransactions.containsKey(key)) return;

    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    List<Map<String, dynamic>> rawTransactions;
    if (shopCode == null || shopCode.isEmpty) {
      rawTransactions = await dbInstance.query(
        'ledger',
        where: 'shopName = ? AND (shopCode IS NULL OR shopCode = "")',
        whereArgs: [shopName],
        orderBy: 'date DESC',
      );
    } else {
      rawTransactions = await dbInstance.query(
        'ledger',
        where: 'shopName = ? AND shopCode = ?',
        whereArgs: [shopName, shopCode],
        orderBy: 'date DESC',
      );
    }

    final transactionsWithControllers = rawTransactions.map((txn) {
      final details = txn['details']?.toString() ?? '';
      return {
        'data': txn,
        'controller': TextEditingController(text: details),
        'notifier': ValueNotifier<String>(details),
      };
    }).toList();

    setState(() {
      _shopTransactions[key] = transactionsWithControllers;
    });
  }

  Future<void> _updateLedgerRecord(int id, Map<String, dynamic> updates) async {
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    if (updates.containsKey('debit') || updates.containsKey('credit')) {
      final record = await dbInstance.query(
        'ledger',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (record.isNotEmpty) {
        final currentRecord = record.first;
        final debit = updates['debit'] ?? currentRecord['debit'] ?? 0.0;
        final credit = updates['credit'] ?? currentRecord['credit'] ?? 0.0;
        updates['balance'] = (debit as double) - (credit as double);
      }
    }

    await dbInstance.update(
      'ledger',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );

    await _loadShopBalances();
  }

  void _toggleShopExpansion(String shopName, String? shopCode) {
    final key = shopCode == null || shopCode.isEmpty ? shopName : '$shopName-$shopCode';
    setState(() {
      _expandedShops[key] = !(_expandedShops[key] ?? false);
    });

    if (_expandedShops[key] == true) {
      _loadShopTransactions(shopName, shopCode);
    }
  }

  Future<void> _printLedgerTable({required bool includeZeroBalance}) async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );
    final numberFormat = NumberFormat('#,##0', 'en_US');
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');
    String formatNumber(num value) {
      if (value % 1 == 0) {
        return numberFormat.format(value);
      } else {
        return moneyFormat.format(value);
      }
    }
    final String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final String day = DateFormat('EEEE').format(DateTime.now());
    final filtered = includeZeroBalance
      ? _shopBalances
      : _shopBalances.where((row) {
          final balance = row['balance'] ?? 0.0;
          return balance != 0.0;
        }).toList();
    // Fetch all transactions for each party
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;
    List<List<Map<String, dynamic>>> allTransactions = [];
    for (final row in filtered) {
      final shopName = row['shopName'] ?? '';
      final shopCode = row['shopCode'] ?? '';
      List<Map<String, dynamic>> txns;
      if (shopCode == null || shopCode.toString().isEmpty) {
        txns = await dbInstance.query(
          'ledger',
          where: 'shopName = ? AND (shopCode IS NULL OR shopCode = "")',
          whereArgs: [shopName],
          orderBy: 'date ASC',
        );
      } else {
        txns = await dbInstance.query(
          'ledger',
          where: 'shopName = ? AND shopCode = ?',
          whereArgs: [shopName, shopCode],
          orderBy: 'date ASC',
        );
      }
      allTransactions.add(txns);
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.SizedBox(height: 50, width: 50, child: pw.Image(logo)),
                pw.Text(
                  'Ledger Report',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 10),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date $date ($day)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ...List.generate(filtered.length, (i) {
              final row = filtered[i];
              final txns = allTransactions[i];
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: pw.Text(
                      'Name: ${(row['shopName'] ?? '').toString()}    Code: ${(row['shopCode'] ?? '').toString()}    Balance: ${formatNumber(row['balance'] ?? 0)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  if (txns.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(left: 12, bottom: 8),
                      child: pw.Table.fromTextArray(
                        headers: ['No.', 'Date', 'Details', 'Debit', 'Credit'],
                        data: List.generate(txns.length, (j) => [
                          (j + 1).toString(),
                          _formatLedgerDate(txns[j]['date'], txns[j]['details']),
                          (txns[j]['details'] ?? '').toString(),
                          formatNumber(txns[j]['debit'] ?? 0),
                          formatNumber(txns[j]['credit'] ?? 0),
                        ]),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        cellStyle: pw.TextStyle(fontSize: 9),
                        cellAlignment: pw.Alignment.centerLeft,
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        border: pw.TableBorder.all(width: 0.5),
                        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      ),
                    ),
                ],
              );
            }),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ledger_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  String _formatLedgerDate(dynamic dateValue, dynamic details) {
    final dateStr = (dateValue ?? '').toString();
    if (dateStr.isEmpty) return '';
    // If details contains 'Opening Balance', show full date/time
    if ((details ?? '').toString().toLowerCase().contains('opening balance')) {
      return dateStr;
    }
    // Otherwise, show only yyyy-MM-dd
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return dateStr;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ledger',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View shop-wise credit ledger entries',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return _AddCustomValueDialog();
                            },
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        label: const Text(
                          'Add Custom Value',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadowColor: Colors.deepPurpleAccent,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.deepPurple, size: 28),
                        tooltip: 'Refresh',
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _shopTransactions.clear();
                            _expandedShops.clear();
                          });
                          _loadShopBalances();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.deepPurple, size: 28),
                        tooltip: 'Print',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Print Options'),
                                content: Text('Print Parties with Zero Balance?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _printLedgerTable(includeZeroBalance: true);
                                    },
                                    child: Text('Yes'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _printLedgerTable(includeZeroBalance: false);
                                    },
                                    child: Text('No'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by shop name or code...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _shopBalances.isEmpty
                        ? const Center(
                            child: Text(
                              'No ledger records found.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : (() {
                            final filteredShops = _shopBalances
                                .where((shop) {
                                  final name = (shop['shopName'] ?? '').toString().toLowerCase();
                                  final code = (shop['shopCode'] ?? '').toString().toLowerCase();
                                  return name.contains(_searchQuery) || code.contains(_searchQuery);
                                })
                                .toList();
                            return ListView.builder(
                              itemCount: filteredShops.length,
                              itemBuilder: (context, index) {
                                final shop = filteredShops[index];
                                final shopName = shop['shopName'] ?? '';
                                final shopCode = shop['shopCode'] ?? '';
                                final balance = shop['balance'] ?? 0.0;
                                final formattedBalance = NumberFormat.currency(
                                  locale: 'en_IN',
                                  symbol: 'Rs. ',
                                  decimalDigits: 2,
                                ).format(balance);
                                final key = (shopCode == null || shopCode.isEmpty) ? shopName : '$shopName-$shopCode';
                                final isExpanded = _expandedShops[key] ?? false;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ExpansionTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${index + 1}.',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          backgroundColor: Colors.deepPurple
                                              .withOpacity(0.1),
                                          child: Text(
                                            shopName.isNotEmpty
                                                ? shopName[0].toUpperCase()
                                                : 'S',
                                            style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      shopName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Code: $shopCode',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: balance >= 0
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        formattedBalance,
                                        style: TextStyle(
                                          color: balance >= 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    onExpansionChanged: (expanded) {
                                      _toggleShopExpansion(shopName, shopCode);
                                    },
                                    children: [
                                      if (isExpanded && _shopTransactions.containsKey(key))
                                        _buildTransactionList(_shopTransactions[key]!),
                                    ],
                                  ),
                                );
                              },
                            );
                          })(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    final formatCurrency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );

    Widget tableHeader = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: const [
          SizedBox(
            width: 40,
            child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 140,
            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 65,
            child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 65,
            child: Text(
              'Credit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8.0),
            child: Text(
              'Transaction History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 12),
          tableHeader,
          const Divider(),
          ...transactions.asMap().entries.expand((entry) {
            final index = entry.key;
            final txn = entry.value;
            final transaction = txn['data'] as Map<String, dynamic>;
            final controller = txn['controller'] as TextEditingController;
            final notifier = txn['notifier'] as ValueNotifier<String>;

            final debit = transaction['debit'] ?? 0.0;
            final credit = transaction['credit'] ?? 0.0;

            return [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                        child: Text('${index + 1}.'),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                        child: Text(
                          (transaction['date'] != null &&
                                  transaction['date'].toString().isNotEmpty)
                              ? DateFormat('yyyy-MM-dd').format(
                                  DateTime.tryParse(transaction['date']) ??
                                      DateTime.now(),
                                )
                              : '',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: notifier,
                              builder: (context, value, _) {
                                return TextFormField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  maxLines: null,
                                  onChanged: (val) {
                                    notifier.value = val;
                                  },
                                );
                              },
                            ),
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable: notifier,
                            builder: (context, value, _) {
                              final initial =
                                  transaction['details']?.toString() ?? '';
                              final changed = value != initial;

                              return changed
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(48, 36),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 0,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await _updateLedgerRecord(
                                            transaction['id'] as int,
                                            {'details': value},
                                          );
                                          controller.text = value;
                                          notifier.value = value;
                                        },
                                        child: const Text(
                                          'Save',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          formatCurrency.format(debit),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          formatCurrency.format(credit),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ];
          }),
        ],
      ),
    );
  }
}

class _AddCustomValueDialog extends StatefulWidget {
  @override
  State<_AddCustomValueDialog> createState() => _AddCustomValueDialogState();
}

class _AddCustomValueDialogState extends State<_AddCustomValueDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _debitController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  bool _isSaving = false;

  List<Map<String, dynamic>> _shops = [];
  List<String> _ledgerNames = [];
  Map<String, dynamic>? _selectedShopForAutocomplete;

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _fetchLedgerNames();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _detailsController.dispose();
    _debitController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  Future<void> _fetchShops() async {
    final shops = await DatabaseHelper.instance.getShops();
    setState(() {
      _shops = shops;
    });
  }

  Future<void> _fetchLedgerNames() async {
    final names = await DatabaseHelper.instance.getUniqueLedgerNames();
    setState(() {
      _ledgerNames = names;
    });
  }

  void _onNameChanged() {
    final input = _nameController.text.trim().toLowerCase();
    if (input.isEmpty) {
      setState(() {
        _selectedShopForAutocomplete = null;
      });
      return;
    }
    final matches = _shops.where((shop) {
      final shopName = (shop['name'] ?? '').toString().toLowerCase();
      return shopName.contains(input);
    }).toList();
    _ledgerNames.where((name) => name.toLowerCase().contains(input)).toList();
    setState(() {
// Keep free text entry
      _selectedShopForAutocomplete = matches.length == 1 && matches[0]['name'].toString().toLowerCase() == input ? matches[0] : null;
    });
  }

  String _generateCustomValueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    String randomPart = List.generate(4, (index) => chars[rand.nextInt(chars.length)]).join();
    return 'CV$randomPart';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;
    setState(() { _isSaving = true; });
    final isShop = _selectedShopForAutocomplete != null && _selectedShopForAutocomplete!.isNotEmpty;
    final shopName = isShop ? _selectedShopForAutocomplete!['name'] : _nameController.text.trim();
    String? shopCode;
    if (isShop) {
      shopCode = _selectedShopForAutocomplete!['code'];
    } else {
      shopCode = _generateCustomValueCode();
    }
    final details = _detailsController.text.trim();
    final debit = double.tryParse(_debitController.text.trim()) ?? 0.0;
    final credit = double.tryParse(_creditController.text.trim()) ?? 0.0;
    final date = _selectedDate != null ? _selectedDate!.toIso8601String().split('T')[0] : '';
    final balance = debit - credit;
    await DatabaseHelper.instance.insertLedger({
      'shopName': shopName,
      'shopCode': shopCode,
      'date': date,
      'details': details,
      'debit': debit,
      'credit': credit,
      'balance': balance,
    });
    setState(() { _isSaving = false; });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Add Custom Value',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Date Picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today, color: Colors.deepPurple),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            controller: TextEditingController(
                              text: _selectedDate == null
                                  ? ''
                                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                            ),
                            validator: (_) => _selectedDate == null ? 'Select a date' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Modern Autocomplete for Name
                      Autocomplete<_NameSuggestion>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final input = textEditingValue.text.trim().toLowerCase();
                          if (input.isEmpty) return const Iterable<_NameSuggestion>.empty();
                          final shopSuggestions = _shops
                              .where((shop) => (shop['name'] ?? '').toString().toLowerCase().contains(input))
                              .map((shop) => _NameSuggestion(shop['name'], isShop: true, shop: shop))
                              .toList();
                          final ledgerSuggestions = _ledgerNames
                              .where((name) => name.toLowerCase().contains(input))
                              .map((name) => _NameSuggestion(name, isShop: false))
                              .toList();
                          // Remove duplicates (shop names already in ledger)
                          final allNames = <String>{};
                          final suggestions = <_NameSuggestion>[];
                          for (final s in shopSuggestions + ledgerSuggestions) {
                            if (!allNames.contains(s.name.toLowerCase())) {
                              suggestions.add(s);
                              allNames.add(s.name.toLowerCase());
                            }
                          }
                          // Always allow free text entry
                          if (!allNames.contains(input)) {
                            suggestions.add(_NameSuggestion(textEditingValue.text, isShop: false));
                          }
                          return suggestions;
                        },
                        displayStringForOption: (option) => option.name,
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Do NOT assign _nameController.text = controller.text here!
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                            onChanged: (val) {
                              Future.microtask(() {
                                if (!mounted) return;
                                setState(() {
                                  final found = _shops.firstWhere(
                                    (shop) => (shop['name'] ?? '').toString().toLowerCase() == val.trim().toLowerCase(),
                                    orElse: () => <String, dynamic>{},
                                  );
                                  _selectedShopForAutocomplete = found.isNotEmpty ? found : null;
                                });
                              });
                            },
                          );
                        },
                        onSelected: (option) {
                          setState(() {
                            if (option.isShop) {
                              _selectedShopForAutocomplete = option.shop;
                              _nameController.text = option.name;
                            } else {
                              _selectedShopForAutocomplete = null;
                              _nameController.text = option.name;
                            }
                          });
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final shopOptions = options.where((o) => o.isShop).toList();
                          final ledgerOptions = options.where((o) => !o.isShop).toList();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 260, minWidth: 300),
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    if (shopOptions.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text('Shops', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                      ),
                                      ...shopOptions.map((option) => ListTile(
                                            leading: Icon(Icons.store, color: Colors.deepPurple),
                                            title: Text(option.name),
                                            subtitle: option.shop != null
                                                ? Text('Shop Code: ${option.shop!['code']}', style: TextStyle(color: Colors.deepPurple))
                                                : null,
                                            onTap: () => onSelected(option),
                                          )),
                                    ],
                                    if (ledgerOptions.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text('Other Names in Ledger', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                      ),
                                      ...ledgerOptions.map((option) => ListTile(
                                            leading: Icon(Icons.person_outline, color: Colors.grey[700]),
                                            title: Text(option.name),
                                            onTap: () => onSelected(option),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_selectedShopForAutocomplete != null && _selectedShopForAutocomplete!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, color: Colors.deepPurple),
                              const SizedBox(width: 8),
                              Text('Code: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(_selectedShopForAutocomplete!['code'] ?? '', style: TextStyle(color: Colors.deepPurple)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      // Details
                      TextFormField(
                        controller: _detailsController,
                        decoration: InputDecoration(
                          labelText: 'Details',
                          prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: 2,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter details' : null,
                      ),
                      const SizedBox(height: 18),
                      // Debit
                      TextFormField(
                        controller: _debitController,
                        decoration: InputDecoration(
                          labelText: 'Debit',
                          prefixIcon: Icon(Icons.arrow_downward, color: Colors.green),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      // Credit
                      TextFormField(
                        controller: _creditController,
                        decoration: InputDecoration(
                          labelText: 'Credit',
                          prefixIcon: Icon(Icons.arrow_upward, color: Colors.red),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.deepPurple),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameSuggestion {
  final String name;
  final bool isShop;
  final Map<String, dynamic>? shop;
  _NameSuggestion(this.name, {this.isShop = false, this.shop});
}
