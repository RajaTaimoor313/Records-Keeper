// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import '../../database_helper.dart';

class ExpenditureData {
  final String date;
  final String category;
  final String details;
  final double amount;

  ExpenditureData({
    required this.date,
    required this.category,
    required this.details,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'category': category,
      'details': details,
      'amount': amount,
    };
  }

  static ExpenditureData fromMap(Map<String, dynamic> map) {
    return ExpenditureData(
      date: map['date'],
      category: map['category'],
      details: map['details'],
      amount: map['amount'],
    );
  }
}

class ExpenditureTab extends StatefulWidget {
  final bool isViewMode;

  const ExpenditureTab({super.key, required this.isViewMode});

  @override
  State<ExpenditureTab> createState() => _ExpenditureTabState();
}

class _ExpenditureTabState extends State<ExpenditureTab> {
  final List<String> categoryOptions = [
    'Petrol & Fuel',
    'Payments',
    'Bebtors',
    'Offloads',
    'Supplies',
    'Stationary',
    'Office Expenses',
    'Carage',
    'Personal',
    'Supply Man / Order Booker',
  ];
  final TextEditingController searchController = TextEditingController();

  String? selectedCategory;
  String? filterCategory;
  String? sortBy;
  bool isAscending = true;
  bool showAddForm = false;
  TextEditingController dateController = TextEditingController();
  TextEditingController detailsController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  List<ExpenditureData> expenditureRecords = [];
  List<ExpenditureData> filteredRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenditureRecords();
  }

  @override
  void dispose() {
    searchController.dispose();
    dateController.dispose();
    detailsController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenditureRecords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final records = await DatabaseHelper.instance.getExpenditures();
      setState(() {
        expenditureRecords = records.map((record) => ExpenditureData.fromMap(record)).toList();
        filteredRecords = List.from(expenditureRecords);
        isLoading = false;
      });
    } catch (e) {
      print('✖ Error loading expenditure records: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterRecords() {
    setState(() {
      filteredRecords = expenditureRecords.where((record) {
        bool categoryMatch = filterCategory == null || record.category == filterCategory;
        bool searchMatch = searchController.text.isEmpty ||
            record.details.toLowerCase().contains(searchController.text.toLowerCase()) ||
            record.category.toLowerCase().contains(searchController.text.toLowerCase()) ||
            record.date.toLowerCase().contains(searchController.text.toLowerCase()) ||
            record.amount.toString().contains(searchController.text);
        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  void _sortRecords(String sortCriteria) {
    if (sortBy == sortCriteria) {
      setState(() {
        isAscending = !isAscending;
      });
    } else {
      setState(() {
        sortBy = sortCriteria;
        isAscending = true;
      });
    }

    setState(() {
      if (sortCriteria == 'Date') {
        filteredRecords.sort((a, b) {
          final aDateParts = a.date.split('/');
          final bDateParts = b.date.split('/');

          final aDate = DateTime(
            int.parse(aDateParts[2]),
            int.parse(aDateParts[1]),
            int.parse(aDateParts[0]),
          );
          final bDate = DateTime(
            int.parse(bDateParts[2]),
            int.parse(bDateParts[1]),
            int.parse(bDateParts[0]),
          );

          return isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
      } else if (sortCriteria == 'Amount') {
        filteredRecords.sort((a, b) {
          return isAscending
              ? a.amount.compareTo(b.amount)
              : b.amount.compareTo(a.amount);
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _submitForm() async {
    if (dateController.text.isEmpty ||
        selectedCategory == null ||
        detailsController.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final expenditure = ExpenditureData(
        date: dateController.text,
        category: selectedCategory!,
        details: detailsController.text,
        amount: double.parse(amountController.text),
      );

      await DatabaseHelper.instance.insertExpenditure(expenditure.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expenditure added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        dateController.clear();
        selectedCategory = null;
        detailsController.clear();
        amountController.clear();
      });

      await _loadExpenditureRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding expenditure: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expenditure Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: !showAddForm 
                            ? [Colors.grey[300]!, Colors.grey[200]!]
                            : [Colors.deepPurple, Colors.deepPurple.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: !showAddForm 
                              ? Colors.transparent 
                              : Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!showAddForm) {
                              setState(() {
                                showAddForm = true;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: !showAddForm ? Colors.grey[600] : Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Data',
                                  style: TextStyle(
                                    color: !showAddForm ? Colors.grey[600] : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 10,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: showAddForm 
                            ? [Colors.grey[300]!, Colors.grey[200]!]
                            : [Colors.deepPurple, Colors.deepPurple.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: showAddForm 
                              ? Colors.transparent 
                              : Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (showAddForm) {
                              setState(() {
                                showAddForm = false;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: showAddForm ? Colors.grey[600] : Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'View Data',
                                  style: TextStyle(
                                    color: showAddForm ? Colors.grey[600] : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showAddForm ? _buildAddForm() : _buildDataView(),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.deepPurple.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_chart,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add Expenditure',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: const TextStyle(color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.deepPurple),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.category, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isDense: true,
                      isExpanded: true,
                      hint: const Text('Select a category'),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: categoryOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  decoration: InputDecoration(
                    labelText: 'Details',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.description, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Save Expenditure',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shadowColor: Colors.deepPurple.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataView() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search in all fields...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => _filterRecords(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Filter by Category',
                        labelStyle: const TextStyle(color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.deepPurple),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.filter_alt, color: Colors.deepPurple),
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
                            _filterRecords();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Sort by',
                        labelStyle: const TextStyle(color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.deepPurple),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.sort, color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sortBy,
                          isDense: true,
                          isExpanded: true,
                          hint: const Text('Sort...'),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: 'Date',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Date'),
                                  if (sortBy == 'Date')
                                    Icon(
                                      isAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                      color: Colors.deepPurple,
                                    ),
                                ],
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Amount',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Amount'),
                                  if (sortBy == 'Amount')
                                    Icon(
                                      isAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                      color: Colors.deepPurple,
                                    ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (newValue) {
                            if (newValue != null) {
                              _sortRecords(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                      onPressed: () {
                        setState(() {
                          filterCategory = null;
                          sortBy = null;
                          searchController.clear();
                        });
                        _loadExpenditureRecords();
                      },
                      tooltip: 'Refresh Data',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No records found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell('Date', flex: 2),
                                _buildHeaderCell('Category', flex: 3),
                                _buildHeaderCell('Details', flex: 4),
                                _buildHeaderCell('Amount', flex: 2, isLast: true),
                              ],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            final isEven = index % 2 == 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.grey.shade50 : Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    _buildDataCell(record.date, flex: 2),
                                    _buildDataCell(record.category, flex: 3),
                                    _buildDataCell(record.details, flex: 4),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs. ${record.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple.shade700,
          fontSize: 14,
        ),
        textAlign: isLast ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
} 