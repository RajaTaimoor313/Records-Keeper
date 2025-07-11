import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;

class CreditorsSummary extends StatefulWidget {
  const CreditorsSummary({super.key});

  @override
  State<CreditorsSummary> createState() => _CreditorsSummaryState();
}

class _CreditorsSummaryState extends State<CreditorsSummary> {
  List<Map<String, dynamic>> _creditors = [];
  bool _isLoading = true;
  final Set<int> _expandedItems = {};
  final Map<int, List<Map<String, dynamic>>> _transactionsByCreditorId = {};
  final Set<int> _loadingTransactions = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCreditors();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCreditors() async {
    final creditors = await DatabaseHelper.instance.getCreditors();
    setState(() {
      _creditors = creditors;
      _isLoading = false;
    });
  }

  Future<void> _loadTransactionsForCreditor(int creditorId) async {
    setState(() {
      _loadingTransactions.add(creditorId);
    });
    final txns = await DatabaseHelper.instance.getCreditorTransactions(
      creditorId,
    );
    setState(() {
      _transactionsByCreditorId[creditorId] = txns;
      _loadingTransactions.remove(creditorId);
    });
  }

  Future<void> _refreshCreditors() async {
    setState(() {
      _isLoading = true;
      _expandedItems.clear();
      _transactionsByCreditorId.clear();
    });
    await _loadCreditors();
  }

  Future<void> _printCreditorsTable({required bool includeZeroBalance}) async {
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
        ? _creditors
        : _creditors.where((row) {
            final balance = row['balance'] ?? 0.0;
            return balance != 0.0;
          }).toList();
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;
    List<List<Map<String, dynamic>>> allTransactions = [];
    for (final row in filtered) {
      final creditorId = row['id'] as int;
      final txns = await dbInstance.query(
        'creditor_transactions',
        where: 'creditor_id = ?',
        whereArgs: [creditorId],
        orderBy: 'date ASC',
      );
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
                  'Creditors Report',
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
                      'Name: ${(row['company'] ?? '').toString()}    Person: ${(row['person'] ?? '').toString()}    Concern: ${(row['concern'] ?? '').toString()}    Balance: ${formatNumber(row['balance'] ?? 0)}',
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
                            _formatDate(txns[j]['date']),
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
      name: 'Creditors_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  String _formatDate(dynamic dateValue) {
    final dateStr = (dateValue ?? '').toString();
    if (dateStr.isEmpty) return '';
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return dateStr;
  }

  List<Map<String, dynamic>> get _filteredCreditors {
    if (_searchQuery.isEmpty) return _creditors;
    final query = _searchQuery.toLowerCase();
    return _creditors.where((c) {
      final company = (c['company'] ?? '').toString().toLowerCase();
      final person = (c['person'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      return company.contains(query) || person.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double totalCreditors = 0;
    for (final c in _creditors) {
      totalCreditors += (c['balance'] ?? 0) as num;
    }
    final formattedTotalCreditors = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2).format(totalCreditors);
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
                            'Total Creditors',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formattedTotalCreditors,
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
                              'Creditors Summary',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View company-wise creditors and transactions',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
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
                                      _printCreditorsTable(includeZeroBalance: true);
                                    },
                                    child: Text('Yes'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _printCreditorsTable(includeZeroBalance: false);
                                    },
                                    child: Text('No'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.deepPurple, size: 28),
                        tooltip: 'Refresh',
                        onPressed: _refreshCreditors,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by company, person, or phone...',
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
                        : _filteredCreditors.isEmpty
                        ? const Center(
                            child: Text(
                              'No creditors found.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredCreditors.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: false,
                            itemBuilder: (context, index) {
                              final creditor = _filteredCreditors[index];
                              final balance = creditor['balance'] ?? 0.0;
                              final formattedBalance = NumberFormat.currency(
                                locale: 'en_IN',
                                symbol: 'Rs. ',
                                decimalDigits: 2,
                              ).format(balance);
                              final isExpanded = _expandedItems.contains(index);
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
                                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                                        child: Text(
                                          (creditor['company'] ?? '').toString().isNotEmpty
                                              ? (creditor['company'] ?? '').toString()[0].toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    creditor['company'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Person: ${creditor['person'] ?? '-'} | Concern: ${creditor['concern'] ?? '-'} | Phone: ${creditor['phone'] ?? '-'}',
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
                                    setState(() {
                                      if (expanded) {
                                        _expandedItems.add(index);
                                      } else {
                                        _expandedItems.remove(index);
                                      }
                                    });
                                    if (expanded && !_transactionsByCreditorId.containsKey(creditor['id'])) {
                                      _loadTransactionsForCreditor(creditor['id'] as int);
                                    }
                                  },
                                  children: [
                                    if (isExpanded && _transactionsByCreditorId.containsKey(creditor['id']))
                                      _buildTransactionList(_transactionsByCreditorId[creditor['id']]!),
                                  ],
                                ),
                              );
                            },
                          ),
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
            child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)),
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
            final debit = (txn['debit'] ?? 0.0) as num;
            final credit = (txn['credit'] ?? 0.0) as num;
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
                          (txn['date'] != null && txn['date'].toString().isNotEmpty)
                              ? DateFormat('yyyy-MM-dd').format(
                                  DateTime.tryParse(txn['date']) ?? DateTime.now(),
                                )
                              : '',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                        child: Text(txn['details']?.toString() ?? ''),
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
