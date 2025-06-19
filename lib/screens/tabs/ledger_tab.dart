import 'package:flutter/material.dart';
import '../../database_helper.dart';

class LedgerTab extends StatefulWidget {
  const LedgerTab({Key? key}) : super(key: key);

  @override
  State<LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends State<LedgerTab> {
  List<Map<String, dynamic>> _ledgerRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLedgerRecords();
  }

  Future<void> _loadLedgerRecords() async {
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;
    final records = await dbInstance.query('ledger', orderBy: 'date DESC');
    setState(() {
      _ledgerRecords = records;
      _isLoading = false;
    });
  }

  Future<void> _updateLedgerRecord(int id, Map<String, dynamic> updates) async {
    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;
    await dbInstance.update('ledger', updates, where: 'id = ?', whereArgs: [id]);
    await _loadLedgerRecords();
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
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Ledger Table
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _ledgerRecords.isEmpty
                          ? const Center(
                              child: Text(
                                'No ledger records found.',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Shop Name')),
                                  DataColumn(label: Text('Shop Code')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Details')),
                                  DataColumn(label: Text('Debit')),
                                  DataColumn(label: Text('Credit')),
                                  DataColumn(label: Text('Balance')),
                                ],
                                rows: _ledgerRecords.map((record) {
                                  final TextEditingController detailsController = TextEditingController(text: record['details'] ?? '');
                                  final TextEditingController creditController = TextEditingController(text: (record['credit'] ?? '').toString());
                                  final TextEditingController balanceController = TextEditingController(text: (record['balance'] ?? '').toString());
                                  return DataRow(cells: [
                                    DataCell(Text(record['shopName'] ?? '')),
                                    DataCell(Text(record['shopCode'] ?? '')),
                                    DataCell(Text(record['date'] ?? '')),
                                    DataCell(
                                      TextFormField(
                                        controller: detailsController,
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        onFieldSubmitted: (val) {
                                          _updateLedgerRecord(record['id'] as int, {'details': val});
                                        },
                                      ),
                                    ),
                                    DataCell(Text((record['debit'] ?? '').toString())),
                                    DataCell(
                                      TextFormField(
                                        controller: creditController,
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        keyboardType: TextInputType.number,
                                        onFieldSubmitted: (val) {
                                          _updateLedgerRecord(record['id'] as int, {'credit': double.tryParse(val) ?? 0});
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      TextFormField(
                                        controller: balanceController,
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        keyboardType: TextInputType.number,
                                        onFieldSubmitted: (val) {
                                          _updateLedgerRecord(record['id'] as int, {'balance': double.tryParse(val) ?? 0});
                                        },
                                      ),
                                    ),
                                  ]);
                                }).toList(),
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
} 