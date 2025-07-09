import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';

class ViewCreditors extends StatefulWidget {
  const ViewCreditors({super.key});

  @override
  State<ViewCreditors> createState() => _ViewCreditorsState();
}

class _ViewCreditorsState extends State<ViewCreditors> {
  List<Map<String, dynamic>> _creditors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCreditors();
  }

  Future<void> _loadCreditors() async {
    final creditors = await DatabaseHelper.instance.getCreditors();
    setState(() {
      _creditors = creditors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _creditors.isEmpty
                      ? const Center(
                          child: Text(
                            'No creditors found.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _creditors.length,
                          itemBuilder: (context, index) {
                            final creditor = _creditors[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                                  child: Text(
                                    (creditor['company'] ?? '?').toString().isNotEmpty
                                        ? creditor['company'][0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.deepPurple),
                                  ),
                                ),
                                title: Text(
                                  creditor['company'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Text(
                                  creditor['phone'] ?? '-',
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                trailing: Text(
                                  'Rs. \\${(creditor['balance'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        const Text('Concern: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(creditor['concern'] ?? '-'),
                                        const SizedBox(width: 24),
                                        const Text('Person: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(creditor['person'] ?? '-'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }
} 