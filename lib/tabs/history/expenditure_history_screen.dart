import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';
import 'package:intl/intl.dart';

class ExpenditureHistoryScreen extends StatefulWidget {
  const ExpenditureHistoryScreen({super.key});

  @override
  State<ExpenditureHistoryScreen> createState() => _ExpenditureHistoryScreenState();
}

class _ExpenditureHistoryScreenState extends State<ExpenditureHistoryScreen> {
  late Future<List<String>> _datesFuture;
  String? filterCategory;
  final List<String> categoryOptions = [
    'Petrol & Fuel',
    'Payments',
    'Debtors',
    'Offloads',
    'Supplies',
    'Stationary',
    'Office Expenses',
    'Carage',
    'Personal',
    'Supply Man / Order Booker',
  ];

  @override
  void initState() {
    super.initState();
    _datesFuture = _getUniqueDates();
  }

  Future<List<String>> _getUniqueDates() async {
    final records = await DatabaseHelper.instance.getExpenditures();
    final filtered = filterCategory == null
      ? records
      : records.where((e) => e['category'] == filterCategory).toList();
    final dates = filtered.map((e) => e['date'] as String).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  Future<List<Map<String, dynamic>>> _getExpendituresByDate(String date) async {
    final records = await DatabaseHelper.instance.getExpenditures();
    return records.where((e) => e['date'] == date).toList();
  }

  void _showExpenditureDetailDialog(BuildContext context, String date, List<Map<String, dynamic>> records) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    String? filterCategory;
    List<String> categoryOptions = records.map((e) => e['category'] as String).toSet().toList();
    categoryOptions.sort();
    List<Map<String, dynamic>> filteredRecords = List.from(records);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            filteredRecords = filterCategory == null
              ? records
              : records.where((e) => e['category'] == filterCategory).toList();
            double total = filteredRecords.fold(0, (sum, e) => sum + (e['amount'] as num));
            return AlertDialog(
              title: Text('Expenditure on $date'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Filter by Category',
                          labelStyle: const TextStyle(color: Colors.deepPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.deepPurple),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.deepPurple.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.filter_alt,
                            color: Colors.deepPurple,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filterCategory,
                            isDense: true,
                            isExpanded: true,
                            hint: const Text('All Categories'),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ...categoryOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }),
                            ],
                            onChanged: (newValue) {
                              setState(() {
                                filterCategory = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 14))),
                              Expanded(flex: 4, child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 14))),
                              Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 14), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                      ),
                      ...filteredRecords.map((e) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(e['category'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14))),
                              Expanded(flex: 4, child: Text(e['details'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14))),
                              Expanded(flex: 2, child: Text(formatter.format(e['amount']), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                      )),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Expanded(flex: 3, child: SizedBox()),
                              const Expanded(flex: 4, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 15))),
                              Expanded(flex: 2, child: Text(formatter.format(total), style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenditure History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<String>>(
        future: _datesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history found.'));
          } else {
            final dates = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      'Expenditure on \\$date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                    onTap: () async {
                      final records = await _getExpendituresByDate(date);
                      _showExpenditureDetailDialog(context, date, records);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
} 