import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_keeper/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadShopBalances();
  }

  Future<void> _loadShopBalances() async {
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    // Get unique shops with their latest balance
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

  Future<void> _loadShopTransactions(String shopName, String shopCode) async {
    if (_shopTransactions.containsKey('$shopName-$shopCode')) {
      return; // Already loaded
    }

    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    final transactions = await dbInstance.query(
      'ledger',
      where: 'shopName = ? AND shopCode = ?',
      whereArgs: [shopName, shopCode],
      orderBy: 'date DESC',
    );

    setState(() {
      _shopTransactions['$shopName-$shopCode'] = transactions;
    });
  }

  Future<void> _updateLedgerRecord(int id, Map<String, dynamic> updates) async {
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    // If updating debit or credit, recalculate balance
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
    await _loadShopBalances(); // Reload balances
  }

  void _toggleShopExpansion(String shopName, String shopCode) {
    final key = '$shopName-$shopCode';
    setState(() {
      _expandedShops[key] = !(_expandedShops[key] ?? false);
    });

    if (_expandedShops[key] == true) {
      _loadShopTransactions(shopName, shopCode);
    }
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
                  // Header
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
                      const Column(
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
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Shop Balances List
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
                        : ListView.builder(
                            itemCount: _shopBalances.length,
                            itemBuilder: (context, index) {
                              final shop = _shopBalances[index];
                              final shopName = shop['shopName'] ?? '';
                              final shopCode = shop['shopCode'] ?? '';
                              final balance = shop['balance'] ?? 0.0;
                              final formattedBalance = NumberFormat.currency(
                                locale: 'en_IN',
                                symbol: 'Rs. ',
                                decimalDigits: 2,
                              ).format(balance);
                              final key = '$shopName-$shopCode';
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
                                    if (isExpanded &&
                                        _shopTransactions.containsKey(key))
                                      _buildTransactionList(
                                        _shopTransactions[key]!,
                                      ),
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
            width: 100,
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
            final transaction = entry.value;
            final debit = transaction['debit'] ?? 0.0;
            final credit = transaction['credit'] ?? 0.0;

            final TextEditingController detailsController =
                TextEditingController(text: transaction['details'] ?? '');

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
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0, left: 12.0),
                        child: Text(transaction['date'] ?? ''),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: detailsController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: null,
                        onFieldSubmitted: (val) {
                          _updateLedgerRecord(transaction['id'] as int, {
                            'details': val,
                          });
                        },
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
