import 'package:flutter/material.dart';
import 'package:records_keeper/tabs/cash_flow/bf_tab.dart';
import 'package:records_keeper/tabs/cash_flow/expenditure_tab.dart';
import 'package:records_keeper/tabs/cash_flow/income_tab.dart';

class CashFlowScreen extends StatelessWidget {
  final String? initialTab;

  const CashFlowScreen({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    switch (initialTab) {
      case 'Income':
        return const IncomeTab(isViewMode: false);
      case 'Expenditure':
        return const ExpenditureTab(isViewMode: false);
      case 'B/F':
        return const BFTab();
      default:
        return const Center(
          child: Text(
            'Please select an option from the menu',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
    }
  }
}
