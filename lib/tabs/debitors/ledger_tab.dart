import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:haider_traders/database_helper.dart';
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
                        headers: ['No.', 'Date', 'Details', 'Debit', 'Credit', 'Balance'],
                        data: List.generate(txns.length, (j) {
                          num runningBalance = 0;
                          for (int k = 0; k <= j; k++) {
                            final debit = (txns[k]['debit'] ?? 0) as num;
                            final credit = (txns[k]['credit'] ?? 0) as num;
                            if (k == 0) {
                              runningBalance = debit - credit;
                            } else {
                              runningBalance += debit - credit;
                            }
                          }
                          return [
                            (j + 1).toString(),
                            _formatLedgerDate(txns[j]['date'], txns[j]['details']),
                            (txns[j]['details'] ?? '').toString(),
                            formatNumber(txns[j]['debit'] ?? 0),
                            formatNumber(txns[j]['credit'] ?? 0),
                            formatNumber(runningBalance),
                          ];
                        }),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        cellStyle: pw.TextStyle(fontSize: 9),
                        cellAlignment: pw.Alignment.center,
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        border: pw.TableBorder.all(width: 0.5),
                        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(16),
                          1: const pw.FixedColumnWidth(40),
                        },
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
    if ((details ?? '').toString().toLowerCase().contains('opening balance')) {
      return dateStr;
    }
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return dateStr;
  }


  @override
  Widget build(BuildContext context) {
    final totalDebtors = _shopBalances.fold<double>(0.0, (sum, shop) => sum + (shop['balance'] ?? 0.0));
    final formattedTotalDebtors = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2).format(totalDebtors);
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
                  Card(
                    color: Colors.deepPurple.shade50,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Colors.deepPurple, size: 32),
                          const SizedBox(width: 16),
                          Text(
                            'Total Debtors',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formattedTotalDebtors,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
          SizedBox(
            width: 80,
            child: Text(
              'Balance',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    num runningBalance = 0.0;

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

            final debit = (transaction['debit'] ?? 0.0) as num;
            final credit = (transaction['credit'] ?? 0.0) as num;

            if (index == 0) {
              runningBalance = debit - credit;
            } else {
              runningBalance += debit - credit;
            }

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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                        child: Text(transaction['details']?.toString() ?? ''),
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
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          formatCurrency.format(runningBalance),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: runningBalance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
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
  List<Map<String, dynamic>> _customDebitors = [];
  String? _selectedShopCode;

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _fetchLedgerNames();
    _fetchCustomDebitors();
    _nameController.addListener(() {
      final input = _nameController.text.trim();
      final matchShop = _shops.any((shop) => shop['name'] == input);
      final matchCustom = _customDebitors.any((debitor) => debitor['name'] == input);
      if (!matchShop && !matchCustom) {
        _selectedShopCode = null;
      } else {
        final custom = _customDebitors.firstWhere(
          (debitor) => debitor['name'] == input,
          orElse: () => <String, dynamic>{},
        );
        if (custom.isNotEmpty) {
          _selectedShopCode = custom['code'];
        }
      }
    });
  }

  @override
  void dispose() {
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
    setState(() {
    });
  }

  Future<void> _fetchCustomDebitors() async {
    final debitors = await DatabaseHelper.instance.getCustomDebitors();
    setState(() {
      _customDebitors = debitors;
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
    final shopNameRaw = _nameController.text.trim();
    final shopName = shopNameRaw.isNotEmpty ? shopNameRaw : 'Unknown';
    String shopCode = _selectedShopCode ?? '';
    if (shopCode.isEmpty) {
      shopCode = _generateCustomValueCode();
      await DatabaseHelper.instance.insertCustomDebitor({'name': shopName, 'code': shopCode});
      await _fetchCustomDebitors();
    }
    final details = _detailsController.text.trim();
    final debit = double.tryParse(_debitController.text.trim()) ?? 0.0;
    final credit = double.tryParse(_creditController.text.trim()) ?? 0.0;
    final date = _selectedDate != null ? _selectedDate!.toIso8601String().split('T')[0] : '';
    await DatabaseHelper.instance.insertLedger({
      'shopName': shopName,
      'shopCode': shopCode,
      'date': date,
      'details': details,
      'debit': debit,
      'credit': credit,
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
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          final allNames = [
                            ..._shops.map((s) => s['name'] as String),
                            ..._customDebitors.map((d) => d['name'] as String),
                          ];
                          return allNames.where((name) =>
                            name.toLowerCase().contains(textEditingValue.text.toLowerCase())
                          );
                        },
                        onSelected: (String selection) {
                          _nameController.text = selection;
                          final shop = _shops.firstWhere(
                            (s) => s['name'] == selection,
                            orElse: () => <String, dynamic>{},
                          );
                          if (shop.isNotEmpty) {
                            _selectedShopCode = shop['code'];
                            return;
                          }
                          final custom = _customDebitors.firstWhere(
                            (d) => d['name'] == selection,
                            orElse: () => <String, dynamic>{},
                          );
                          if (custom.isNotEmpty) {
                            _selectedShopCode = custom['code'];
                          }
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          controller.text = _nameController.text;
                          controller.selection = _nameController.selection;
                          _nameController.addListener(() {
                            if (controller.text != _nameController.text) {
                              controller.text = _nameController.text;
                              controller.selection = _nameController.selection;
                            }
                          });
                          controller.addListener(() {
                            if (_nameController.text != controller.text) {
                              _nameController.text = controller.text;
                              _nameController.selection = controller.selection;
                            }
                          });
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
                          );
                        },
                      ),
                      const SizedBox(height: 18),
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
