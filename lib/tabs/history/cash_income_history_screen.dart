import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:haider_traders/database_helper.dart';
import 'dart:convert';

class CashIncomeHistoryScreen extends StatefulWidget {
  const CashIncomeHistoryScreen({super.key});

  @override
  State<CashIncomeHistoryScreen> createState() =>
      _CashIncomeHistoryScreenState();
}

class _CashIncomeHistoryScreenState extends State<CashIncomeHistoryScreen> {
  bool isLoading = true;
  List<String> allDates = [];
  List<String> filteredDates = [];
  Map<String, Map<String, double>> summaryByDate = {};
  TextEditingController searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<Map<String, double>> _getProfitForDate(String date) async {
    final db = await DatabaseHelper.instance.database;
    final products = await db.query('products');
    final Map<String, Map<String, dynamic>> productRates = {};
    for (var p in products) {
      final brand = p['brand'] as String? ?? '';
      final boxRate = p['boxRate'] ?? 0.0;
      final salePrice = p['salePrice'] ?? 0.0;
      productRates[brand] = {'boxRate': boxRate, 'salePrice': salePrice};
    }
    double totalBox = 0.0;
    double totalTrade = 0.0;
    final loadFormHistory = await db.query(
      'load_form_history',
      where: 'date = ?',
      whereArgs: [date],
    );
    for (final entry in loadFormHistory) {
      final data = entry['data'] as String?;
      if (data == null) continue;
      final decoded = jsonDecode(data);
      final items = decoded['items'] as List<dynamic>?;
      if (items == null) continue;
      for (final item in items) {
        final brandName = item['brandName'] as String? ?? '';
        final saleQty = (item['sale'] ?? 0) as num;
        if (saleQty > 0 && productRates.containsKey(brandName)) {
          final boxRate = (productRates[brandName]!['boxRate'] ?? 0) as num;
          final salePrice = (productRates[brandName]!['salePrice'] ?? 0) as num;
          totalBox += boxRate * saleQty;
          totalTrade += salePrice * saleQty;
        }
      }
    }
    final gross = totalTrade - totalBox;
    final expResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenditure WHERE date = ?',
      [date],
    );
    final exp = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final net = gross - exp;
    return {'gross': gross, 'net': net};
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    final incomes = await DatabaseHelper.instance.getIncomes();
    final expenditures = await DatabaseHelper.instance.getExpenditures();
    final bfSummaries = <String, Map<String, dynamic>>{};
    final db = await DatabaseHelper.instance.database;
    final bfRows = await db.query('bf_summary');
    for (final row in bfRows) {
      bfSummaries[row['date'] as String] = row;
    }
    final Set<String> dateSet = {
      ...incomes.map((e) => e['date'] as String),
      ...expenditures.map((e) => e['date'] as String),
      ...bfSummaries.keys,
    };
    final List<String> dates = dateSet.toList()..sort((a, b) => b.compareTo(a));
    final Map<String, Map<String, double>> summary = {};
    for (final date in dates) {
      double sales = 0;
      double recovery = 0;
      double otherIncome = 0;
      double expenditure = 0;
      for (final inc in incomes.where((e) => e['date'] == date)) {
        if (inc['category'] == 'Sales & Recovery' && inc['details'] == 'Sale') {
          sales += (inc['amount'] as num).toDouble();
        } else if (inc['category'] == 'Sales & Recovery' &&
            inc['details'] == 'Recovery') {
          recovery += (inc['amount'] as num).toDouble();
        } else if (inc['category'] == 'Other Income') {
          otherIncome += (inc['amount'] as num).toDouble();
        }
      }
      if (bfSummaries.containsKey(date)) {
        expenditure =
            (bfSummaries[date]?['total_expenditure'] as num?)?.toDouble() ??
            0.0;
      } else {
        expenditure = expenditures
            .where((e) => e['date'] == date)
            .fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());
      }
      final profit = await _getProfitForDate(date);
      summary[date] = {
        'sales': sales,
        'recovery': recovery,
        'otherIncome': otherIncome,
        'expenditure': expenditure,
        'grossProfit': profit['gross'] ?? 0.0,
        'netProfit': profit['net'] ?? 0.0,
      };
    }
    if (mounted) {
      setState(() {
        allDates = dates;
        filteredDates = dates;
        summaryByDate = summary;
        isLoading = false;
      });
    }
  }

  void _search(String value) {
    if (mounted) {
      setState(() {
        filteredDates = allDates.where((date) => date.contains(value)).toList();
      });
    }
  }

  Future<void> _deleteDate(String date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete all records for $date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('income', where: 'date = ?', whereArgs: [date]);
      await db.delete('expenditure', where: 'date = ?', whereArgs: [date]);
      await db.delete('bf_summary', where: 'date = ?', whereArgs: [date]);
      _loadData();
    }
  }

  String _formatIndianNumber(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash and Income History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by date (yyyy-mm-dd)',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _search,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.resolveWith<Color?>(
                                    (states) => Colors.deepPurple.shade50,
                                  ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                fontSize: 16,
                              ),
                              dataRowColor:
                                  MaterialStateProperty.resolveWith<Color?>((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return Colors.deepPurple.shade100;
                                    }
                                    return null;
                                  }),
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Sales')),
                                DataColumn(label: Text('Recovery')),
                                DataColumn(label: Text('Other Income')),
                                DataColumn(label: Text('Expenditure')),
                                DataColumn(label: Text('Gross Profit')),
                                DataColumn(label: Text('Net Profit')),
                                DataColumn(label: Text('Delete')),
                              ],
                              rows: List<DataRow>.generate(
                                filteredDates.length,
                                (index) {
                                  final date = filteredDates[index];
                                  final s = summaryByDate[date]!;
                                  final isEven = index % 2 == 0;
                                  return DataRow(
                                    color:
                                        MaterialStateProperty.resolveWith<
                                          Color?
                                        >((Set<MaterialState> states) {
                                          if (states.contains(
                                            MaterialState.selected,
                                          )) {
                                            return Colors.deepPurple.shade100;
                                          }
                                          return isEven
                                              ? Colors.grey.shade50
                                              : Colors.white;
                                        }),
                                    cells: [
                                      DataCell(
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(s['sales']!),
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(s['recovery']!),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(
                                            s['otherIncome']!,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(
                                            s['expenditure']!,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(
                                            s['grossProfit']!,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(s['netProfit']!),
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          tooltip:
                                              'Delete all records for this date',
                                          onPressed: () => _deleteDate(date),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
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
