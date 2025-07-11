import 'package:flutter/material.dart';
import 'package:haider_traders/database_helper.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  List<String> creditorNames = [];
  List<Map<String, dynamic>> creditors = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCreditors();
  }

  Future<void> _fetchCreditors() async {
    final fetchedCreditors = await DatabaseHelper.instance.getCreditors();
    setState(() {
      creditors = fetchedCreditors;
      creditorNames = creditors.map<String>((c) => c['company']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
      isLoading = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payments (Creditors)',
                            style: TextStyle(fontSize: 24, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                                controller: TextEditingController(
                                  text: '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                ),
                                readOnly: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<String>.empty();
                              }
                              return creditorNames.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {
                              nameController.text = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a name';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_exchange_rounded),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an amount';
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final name = nameController.text.trim();
                                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                                  final creditor = creditors.firstWhere(
                                    (c) => (c['company']?.toString() ?? '').toLowerCase() == name.toLowerCase(),
                                    orElse: () => {},
                                  );
                                  if (creditor.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Creditor not found.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  final currentBalance = (creditor['balance'] as num?)?.toDouble() ?? 0.0;
                                  final newBalance = currentBalance - amount;
                                  await DatabaseHelper.instance.updateCreditorBalance(name, newBalance);
                                  await DatabaseHelper.instance.insertExpenditure({
                                    'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                    'category': 'Payments',
                                    'details': 'Paid to Creditor $name',
                                    'amount': amount,
                                  });
                                  // Add transaction to creditor_transactions
                                  await DatabaseHelper.instance.insertCreditorTransaction({
                                    'creditor_id': creditor['id'],
                                    'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                    'details': 'Payment made',
                                    'debit': 0,
                                    'credit': amount,
                                    'balance': newBalance,
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Payment submitted: Name = \'$name\', Amount = Rs. ${amount.toStringAsFixed(2)}'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  nameController.clear();
                                  amountController.clear();
                                  await _fetchCreditors();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
} 