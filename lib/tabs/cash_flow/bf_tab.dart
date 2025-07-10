import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_keeper/database_helper.dart';

class BFTab extends StatefulWidget {
  const BFTab({super.key});

  @override
  State<BFTab> createState() => _BFTabState();
}

class _BFTabState extends State<BFTab> {
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

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final incomes = await DatabaseHelper.instance.getIncomes();
    final expenditures = await DatabaseHelper.instance.getExpenditures();

    final Set<String> dateSet = {
      ...incomes.map((e) => e['date'] as String),
      ...expenditures.map((e) => e['date'] as String),
    };
    final List<String> dates = dateSet.toList()..sort((a, b) => a.compareTo(b));

    final Map<String, Map<String, double>> summary = {};
    double prevBalance = 0.0;
    for (final date in dates) {
      double sales = 0;
      double recovery = 0;
      double otherIncome = 0;
      double expenses = 0;
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
      for (final exp in expenditures.where((e) => e['date'] == date)) {
        if (exp['category'] != 'Personal') {
          expenses += (exp['amount'] as num).toDouble();
        }
      }
      final balance = sales + recovery + otherIncome - expenses + prevBalance;
      summary[date] = {
        'sales': sales,
        'recovery': recovery,
        'otherIncome': otherIncome,
        'expenses': expenses,
        'balance': balance,
      };
      prevBalance = balance;
    }
    setState(() {
      allDates = dates;
      filteredDates = dates;
      summaryByDate = summary;
      isLoading = false;
    });
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
      appBar: AppBar(title: const Text('B/F Summary')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
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
                                DataColumn(label: Text('Expenses')),
                                DataColumn(label: Text('Balance')),
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
                                          _formatIndianNumber(s['expenses']!),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatIndianNumber(s['balance']!),
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
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
