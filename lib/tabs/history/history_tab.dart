import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:records_keeper/tabs/history/cash_income_history_screen.dart';
import 'package:records_keeper/tabs/reports/sale_report.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool _isRange = false;
  DateTime? _selectedDate;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Switch(
                    value: _isRange,
                    onChanged: (val) {
                      setState(() {
                        _isRange = val;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                  Text(
                    _isRange ? 'Range Picker' : 'Single Date Picker',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  if (!_isRange)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedDate != null
                            ? DateFormat('dd-MMMM-yyyy').format(_selectedDate!)
                            : 'Select Date',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                  if (_isRange)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _selectedRange != null
                            ? '${DateFormat('dd-MMMM-yyyy').format(_selectedRange!.start)} - ${DateFormat('dd-MMMM-yyyy').format(_selectedRange!.end)}'
                            : 'Select Date Range',
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _selectedRange,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedRange = picked;
                          });
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              _buildHistoryOption(
                context,
                icon: Icons.receipt_long,
                title: 'Sales History',
                subtitle: 'View all past sales invoices and transactions.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SaleReport()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildHistoryOption(
                context,
                icon: Icons.list_alt,
                title: 'Pick List History',
                subtitle: 'View all past pick lists.',
                onTap: () {
                  Navigator.pushNamed(context, '/pick-list-history');
                },
              ),
              const SizedBox(height: 20),
              _buildHistoryOption(
                context,
                icon: Icons.assignment,
                title: 'Load Form History',
                subtitle: 'View all past load forms.',
                onTap: () {
                  Navigator.pushNamed(context, '/load-form-history');
                },
              ),
              const SizedBox(height: 20),
              _buildHistoryOption(
                context,
                icon: Icons.attach_money,
                title: 'Cash and Income',
                subtitle:
                    'View complete history of Income, Expenditure, and Recovery by date.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CashIncomeHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 36, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
        onTap: onTap,
      ),
    );
  }
}
